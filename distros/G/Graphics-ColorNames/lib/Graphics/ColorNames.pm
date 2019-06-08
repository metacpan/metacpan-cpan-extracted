package Graphics::ColorNames;
use 5.006;

# ABSTRACT: defines RGB values for common color names

use strict;
use warnings;

use v5.10;

use Exporter qw/ import /;

use Carp;
use File::Spec::Functions qw/ file_name_is_absolute /;
use Module::Load 0.10;
use Module::Loaded;

our $VERSION = 'v3.5.0';

our %EXPORT_TAGS = (
    'all'     => [qw( hex2tuple tuple2hex all_schemes )],
    'utility' => [qw( hex2tuple tuple2hex )],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT    = ();

sub VERSION {
    my ( $class, $wanted ) = @_;
    require version;
    return version->parse($VERSION);
}

# We store Schemes in a hash as a quick-and-dirty way to filter
# duplicates (which sometimes occur when directories are repeated in
# @INC or via symlinks).  The order does not matter.

my %FoundSchemes = ();

sub _load {
    while ( my $module = shift ) {
        unless ( is_loaded($module) ) {
            load($module);
            mark_as_loaded($module) unless ( is_loaded($module) );
        }
    }
}

# TODO - see if using Tie::Hash::Layered gives an improvement

sub _load_scheme_from_module {
    my ($self, $scheme) = @_;

    my $module =
        $scheme =~ /^\+/ ? substr( $scheme, 1 )
      : $scheme =~ /^Color::Library::Dictionary::/ ? $scheme
      :   __PACKAGE__ . '::' . $scheme;

    eval { _load($module); };
    if ($@) {
        croak "Cannot load color naming scheme module $module";
    }

    if ($module->can('NamesRgbTable')) {
        $self->load_scheme( $module->NamesRgbTable );
    }
    elsif ($module->can('_load_color_list')) {
        $self->load_scheme( $module->_load_color_list );
    }
    else {
        croak "Unknown scheme type: $module";
    }
}

sub TIEHASH {
    my $class = shift || __PACKAGE__;
    my $self = {
        _schemes  => [],
        _iterator => 0,
    };

    bless $self, $class;

    if (@_) {
        foreach my $scheme (@_) {
            if ( ref $scheme ) {
                $self->load_scheme($scheme);
            }
            elsif ($scheme =~ /^\+?(?:\w+[:][:])*\w+$/) {
                $self->_load_scheme_from_module($scheme);
            }
            elsif ( file_name_is_absolute($scheme) ) {
                $self->_load_scheme_from_file($scheme);
            }
            else {
                croak "Unknown color scheme: $scheme";
            }
        }
    }
    else {
        $self->_load_scheme_from_module('X');
    }

    return $self;
}

sub FETCH {
    my $self = shift;
    my $key = lc( shift || "" );

    # If we're passing it an RGB value, return that value

    if ( $key =~ m/^(?:\x23|0x)?([0-9a-f]{6})$/ ) {
        return $1;
    }
    else {

        $key =~ s/[^0-9a-z\%]//g;    # ignore non-word characters

        my $val = undef;
        my $i   = 0;
        while ( ( !defined $val ) && ( $i < @{ $self->{_schemes} } ) ) {
            $val = $self->{_schemes}->[ $i++ ]->{$key};
        }

        if ( defined $val ) {
            return sprintf( '%06x', $val ),;
        }
        else {
            return;
        }
    }
}

sub EXISTS {
    my ( $self, $key ) = @_;
    defined( $self->FETCH($key) );
}

sub FIRSTKEY {
    ( my $self = shift )->{_iterator} = 0;
    each %{ $self->{_schemes}->[ $self->{_iterator} ] };
}

sub NEXTKEY {
    my $self = shift;
    my ( $key, $val ) = each %{ $self->{_schemes}->[ $self->{_iterator} ] };
    unless ( defined $key ) {
        ( $key, $val ) = each %{ $self->{_schemes}->[ ++$self->{_iterator} ] };
    }
    return $key;
}

sub load_scheme {
    my $self   = shift;
    my $scheme = shift;

    if ( ref($scheme) eq "HASH" ) {
        push @{ $self->{_schemes} }, $scheme;
    }
    elsif ( ref($scheme) eq "CODE" ) {
        _load("Tie::Sub");
        push @{ $self->{_schemes} }, {};
        tie %{ $self->{_schemes}->[-1] }, 'Tie::Sub', $scheme;
    }
    elsif ( ref($scheme) eq "ARRAY" ) {

        # assumes these are Color::Library::Dictionary 0.02 files
        my $s = {};
        foreach my $rec (@$scheme) {
            my $key  = $rec->[0];
            my $name = $rec->[1];
            my $code = $rec->[5];
            $name =~ s/[\W\_]//g;    # ignore non-word characters
            $s->{$name} = $code unless ( exists $s->{$name} );
            if ( $key =~ /^(.+\:.+)\.([0-9]+)$/ ) {
                $s->{"$name$2"} = $code;
            }
        }
        push @{ $self->{_schemes} }, $s;
    }
    else {
        # TODO - use Exception
        undef $!;
        eval {
            if (   ( ref($scheme) eq 'GLOB' )
                || ref($scheme) eq "IO::File"
                || $scheme->isa('IO::File')
                || ref($scheme) eq "FileHandle"
                || $scheme->isa('FileHandle') )
            {
                $self->_load_scheme_from_file($scheme);
            }
        };
        if ($@) {
            croak "Error $@ on scheme type ", ref($scheme);
        }
        elsif ($!) {
            croak "$!";
        }
        else {
            # everything is ok?
        }
    }
}

sub _find_schemes {

    my $path = shift;

    # BUG: deep-named schemes such as Graphics::ColorNames::Foo::Bar
    # are not supported.

    if ( -d $path ) {
        my $dh = DirHandle->new($path)
          || croak "Unable to access directory $path";
        while ( defined( my $fn = $dh->read ) ) {
            if (   ( -r File::Spec->catdir( $path, $fn ) )
                && ( $fn =~ /(.+)\.pm$/ ) )
            {
                $FoundSchemes{$1}++;
            }
        }
    }
}

sub _readonly_error {
    croak "Cannot modify a read-only value";
}

sub DESTROY {
    my $self = shift;
    delete $self->{_schemes};
    delete $self->{_iterator};
}

BEGIN {
    no strict 'refs';
    *STORE  = \&_readonly_error;
    *DELETE = \&_readonly_error;
    *CLEAR  = \&_readonly_error;    # causes problems with 'undef'

    *new = \&TIEHASH;
}

# Convert 6-digit hexidecimal code (used for HTML etc.) to an array of
# RGB values

sub hex2tuple {
    my $rgb = CORE::hex(shift);
    my ( $red, $green, $blue );
    $blue  = ( $rgb & 0x0000ff );
    $green = ( $rgb & 0x00ff00 ) >> 8;
    $red   = ( $rgb & 0xff0000 ) >> 16;
    return ( $red, $green, $blue );
}

# Convert list of RGB values to 6-digit hexidecimal code (used for HTML, etc.)

sub tuple2hex {
    my ( $red, $green, $blue ) = @_;
    my $rgb = sprintf "%.2x%.2x%.2x", $red, $green, $blue;
    return $rgb;
}

sub all_schemes {
    unless (%FoundSchemes) {

        _load( "DirHandle", "File::Spec" );

        foreach my $dir (@INC) {
            _find_schemes(
                File::Spec->catdir( $dir, split( /::/, __PACKAGE__ ) ) );
        }
    }
    return ( keys %FoundSchemes );
}

sub _load_scheme_from_file {
    my $self = shift;
    my $file = shift;

    unless ( ref $file ) {
        unless ( -r $file ) {
            croak "Cannot load scheme from file: \'$file\'";
        }
        _load("IO::File");
    }

    my $fh = ref($file) ? $file : ( IO::File->new );
    unless ( ref $file ) {
        open( $fh, $file )
          || croak "Cannot open file: \'$file\'";
    }

    my $scheme = {};

    while ( my $line = <$fh> ) {
        chomp($line);
        $line =~ s/[\!\#].*$//;
        if ( $line ne "" ) {
            my $name = lc( substr( $line, 12 ) );
            $name =~ s/[\W]//g;  # remove anything that isn't a letter or number

            croak "Missing color name",
              unless ( $name ne "" );

            # TODO? Should we add an option to warn if overlapping names
            # are defined? This seems to be too common to be useful.

            # unless (exists $scheme->{$name}) {

            $scheme->{$name} = 0;
            foreach ( 0, 4, 8 ) {
                $scheme->{$name} <<= 8;
                $scheme->{$name} |= ( eval substr( $line, $_, 3 ) );
            }

            # }
        }
    }
    $self->load_scheme($scheme);

    unless ( ref $file ) {
        close $fh;
    }
}

sub hex {
    my ($self, $name, $prefix) = @_;
    my $rgb  = $self->FETCH($name);

    return '' unless defined $rgb;

    return $rgb unless defined $prefix;

    return $prefix . $rgb;
}

sub rgb {
    my ($self, $name, $separator) = @_;
    my $rgb = $self->FETCH($name);
    my @rgb = (defined $rgb) ? hex2tuple( $rgb ) : ();
    return wantarray ? @rgb : join($separator || ',', @rgb);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNames - defines RGB values for common color names

=head1 VERSION

version v3.5.0

=head1 SYNOPSIS

  use Graphics::ColorNames;
  use Graphics::ColorNames::WWW;

  $pal = Graphics::ColorNames->new( qw[ X WWW ] );

  $rgb = $pal->hex('green');          # returns '00ff00'
  $rgb = $pal->hex('green', '0x');    # returns '0x00ff00'
  $rgb = $pal->hex('green', '#');     # returns '#00ff00'

  $rgb = $pal->rgb('green');          # returns '0,255,0'
  @rgb = $pal->rgb('green');          # returns (0, 255, 0)

=head1 DESCRIPTION

This module provides a common interface for obtaining the RGB values
of colors by standard names.  The intention is to (1) provide a common
module that authors can use with other modules to specify colors by
name; and (2) free module authors from having to "re-invent the wheel"
whenever they decide to give the users the option of specifying a
color by name rather than RGB value.

=head1 METHODS

=head2 C<new>

The constructor is as follows:

  my $pal = Graphics::ColorNames->new( @schemes );

where C<@schemes> is an array of color schemes (palettes, dictionaries).

A valid color scheme may be the name of a color scheme (such as C<X>
or a full module name such as C<Graphics::ColorNames::X>), a reference
to a color scheme hash or subroutine, or to the path or open
filehandle for a F<rgb.txt> file.

If none are specified, it uses the default C<X> color scheme, which
corresponds to the X-Windows F<rgb.txt> colors.  For most purposes,
this is good enough.  Since v3.2.0, it was updated to use the
2014-07-06 colors, so includes the standard CSS colors as well.

Other color schemes are available on CPAN,
e.g. L<Graphics::ColorNames::WWW>.

Since version 2.1002, L<Color::Library> dictionaries can be used as
well:

  my $pal = Graphics::ColorNames->new( 'Color::Library::Dictionary::HTML' );

=head2 C<rgb>

  @rgb = $pal->rgb($name);

  $rgb = $pal->rgb($name, $separator);

If called in a list context, returns a triplet.

If called in a scalar context, returns a string separated by an
optional separator (which defauls to a comma).  For example,

  @rgb = $pal->rgb('blue');      # returns (0, 0, 255)

  $rgb = $pal->rgb('blue', ','); # returns "0,0,255"

Unknown color names return empty lists or strings, depending on the
context.

Color names are case insensitive, and spaces or punctuation are
ignored. So "Alice Blue" returns the same value as "aliceblue",
"ALICE-BLUE" and "a*lICEbl-ue".  (If you are using color names based
on user input, you should add additional validation of the color
names.)

The value returned is in the six-digit hexidecimal format used in HTML and
CSS (without the initial '#'). To convert it to separate red, green, and
blue values (between 0 and 255), use the L</hex2tuple> function.

You may also specify an absolute filename as a color scheme, if the file
is in the same format as the standard F<rgb.txt> file.

=head2 C<hex>

  $hex = $pal->hex($name, $prefix);

Returns a 6-digit hexidecimal RGB code for the color.  If an optional
prefix is specified, it will prefix the code with that string.  For
example,

  $hex = $pal->hex('blue', '#'); # returns "#0000ff"

If the color does not exist, it will return an empty string.

A hexidecimal RGB value in the form of C<#RRGGBB>, C<0xRRGGBB> or
C<RRGGBB> will return itself:

  $color = $pal->hex('#123abc');         # returns '123abc'

=head2 autoloaded color name methods

Autoloaded color name methods were removed in v3.4.0.

=head2 C<load_scheme>

  $pal->load_scheme( $scheme );

This dynamically loads a color scheme, which can be either a hash
reference or code reference.

=head1 EXPORTS

=head2 C<all_schemes>

  my @schemes = all_schemes();

Returns a list of all available color schemes installed on the machine
in the F<Graphics::ColorNames> namespace.

The order has no significance.

=head2 C<hex2tuple>

Converts a hexidecimal string to a tuple.

=head2 C<tuple2hex>

Converts a tuple to a hexidecimal string.

=head1 TIED INTERFACE

The standard interface (prior to version 0.40) was through a tied hash:

  tie %pal, 'Graphics::ColorNames', qw[ X WWW ];

This interface is deprecated, and will be moved to a separate module
in the future.

=head1 CUSTOM COLOR SCHEMES

You can add naming scheme files by creating a Perl module is the name
C<Graphics::ColorNames::SCHEMENAME> which has a subroutine named
C<NamesRgbTable> that returns a hash of color names and RGB values.
(Schemes with a different base namespace will require the fill namespace
to be given.)

The color names must be in all lower-case, and the RGB values must be
24-bit numbers containing the red, green, and blue values in most- significant
to least- significant byte order.

An example naming schema is below:

  package Graphics::ColorNames::Metallic;

  sub NamesRgbTable() {
    use integer;
    return {
      copper => 0xb87333,
      gold   => 0xcd7f32,
      silver => 0xe6e8fa,
    };
  }

You would use the above schema as follows:

  tie %colors, 'Graphics::ColorNames', 'Metallic';

The behavior of specifying multiple keys with the same name is undefined
as to which one takes precedence.

As of version 2.10, case, spaces and punctuation are ignored in color
names. So a name like "Willy's Favorite Shade-of-Blue" is treated the
same as "willysfavoroteshadeofblue".  (If your scheme does not include
duplicate entrieswith spaces and punctuation, then the minimum
version of L<Graphics::ColorNames> should be 2.10 in your requirements.)

An example of an additional module is the L<Graphics::ColorNames::Mozilla>
module.

Since version 1.03, C<NamesRgbTable> may also return a code reference:

  package Graphics::ColorNames::Orange;

  sub NamesRgbTable() {
    return sub {
      my $name = shift;
      return 0xffa500;
    };
  }

See L<Graphics::ColorNames::GrayScale> for an example.

=head1 ROADMAP

The following changes are planned in the future:

=over 4

=item *

The tied interface will be removed, but implemented in a separate
module for users that wish to use it.

=item *

The namespace for color schemes will be moved to the
C<Graphics::ColorNames::Schemes> but options will be added to use the
existing scheme.

This will allow modules to be named like C<Graphics::ColorNames::Tied>
without being confused for color schemes.

=item *

This module will be rewritten to be a L<Moo>-based class.

=back

=head1 SEE ALSO

L<Color::Library> provides an extensive library of color schemes. A notable
difference is that it supports more complex schemes which contain additional
information about individual colors and map multiple colors to a single name.

L<Color::Rgb> has a similar function to this module, but parses an
F<rgb.txt> file.

L<Graphics::ColorObject> can convert between RGB and other color space
types.

L<Graphics::ColorUtils> can also convert betweeb RGB and other color
space types, and supports RGB from names in various color schemes.

L<Acme::AutoColor> provides subroutines corresponding to color names.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Graphics-ColorNames>
and may be cloned from L<git://github.com/robrwo/Graphics-ColorNames.git>

The SourceForge project for this module at
L<http://sourceforge.net/projects/colornames/> is no longer
maintained.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graphics-ColorNames> or
by email to
L<bug-Graphics-ColorNames@rt.cpan.org|mailto:bug-Graphics-ColorNames@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Alan D. Salewski Steve Pomeroy "chemboy" Magnus Cedergren Gary Vollink Claus Färber Andreas J. König Slaven Rezić

=over 4

=item *

Alan D. Salewski <alans@cji.com>

=item *

Steve Pomeroy <xavier@cpan.org>

=item *

"chemboy" <chemboy@perlmonk.org>

=item *

Magnus Cedergren <magnus@mbox604.swipnet.se>

=item *

Gary Vollink <gary@vollink.com>

=item *

Claus Färber <cfaerber@cpan.org>

=item *

Andreas J. König <andk@cpan.org>

=item *

Slaven Rezić <slaven@rezic.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2001-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
