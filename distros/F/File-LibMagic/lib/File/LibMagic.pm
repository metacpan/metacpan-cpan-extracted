package File::LibMagic;

use 5.008;

use strict;
use warnings;

use Carp;
use Exporter qw( import );
use File::LibMagic::Constants qw ( constants );
use List::Util qw( max );
use Scalar::Util qw( reftype );
use XSLoader;

our $VERSION = '1.23';

XSLoader::load( __PACKAGE__, $VERSION );

for my $name ( constants() ) {
    my ( $error, $value ) = constant($name);

    # The various MAGIC_..._MAX constants have been introduced over various
    # releases of libmagic. If some of them aren't available we'll just skip
    # them.
    next if $error && $name =~ /_MAX$/;

    croak "Could not define $name() - $error"
        if defined $error;

    my $sub = sub () {$value};

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    *{$name} = $sub;
    ## use critic
}

our %EXPORT_TAGS = (
    'easy'     => [qw( MagicBuffer MagicFile )],
    'complete' => [
        constants(),
        qw(
            magic_buffer
            magic_buffer_offset
            magic_close
            magic_file
            magic_load
            magic_open
            )
    ]
);

$EXPORT_TAGS{all} = [ @{ $EXPORT_TAGS{easy} }, @{ $EXPORT_TAGS{complete} } ];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

my %magic_param_map;
my @all_params = qw(
    max_indir
    max_name
    max_elf_phnum
    max_elf_shnum
    max_elf_notes
    max_regex
    max_bytes
);

## no critic ( Subroutines::ProhibitUnusedPrivateSubroutines)
#
# This exists so we can have an author test that checks that all known keys
# are supported by the local libmagic.
sub _all_limit_params {@all_params}
## use critic ( Subroutines::ProhibitUnusedPrivateSubroutines)

# Since these params were introduced in different libmagic releases, we need
# to check that they exist, rather than just assuming they're all defined in
# the libmagic we've linked against.
for my $param (@all_params) {
    ( my $name = $param ) =~ s/^max_//;
    my $constant_name = 'MAGIC_PARAM_' . ( uc $name ) . '_MAX';
    my $const         = __PACKAGE__->can($constant_name)
        or next;

    $magic_param_map{$param} = $const->();
}

sub new {
    my $class = shift;

    my ( $magic_file, $flags, %magic_params )
        = $class->_constructor_params(@_);

    my $m = magic_open($flags);

    my $magic_paths
        = ref $magic_file && reftype($magic_file) eq 'ARRAY'
        ? join ':', @{$magic_file}
        : $magic_file;

    # We need to call this even if $magic_paths is undef
    magic_load( $m, $magic_paths );

    for my $param ( keys %magic_params ) {
        my $value = $magic_params{$param}[1];
        unless ( _magic_setparam( $m, $param, $value ) ) {
            my $desc = $magic_params{$param}[0];
            croak "calling magic_setparam with $desc failed";
        }
    }

    return bless {
        magic      => $m,
        magic_file => $magic_file,
        flags      => $flags,
    }, $class;
}

sub _constructor_params {
    my $class = shift;

    if ( @_ == 1 ) {
        return ( $_[0], MAGIC_NONE(), () );
    }

    my %p = @_;

    my $flags = MAGIC_NONE();
    $flags |= MAGIC_SYMLINK()
        if $p{follow_symlinks};
    $flags |= MAGIC_COMPRESS()
        if $p{uncompress};

    my %magic_params;
    for my $param (@all_params) {
        next unless exists $p{$param};
        croak "Your version of libmagic does not support the $param parameter"
            unless $magic_param_map{$param};
        $magic_params{ $magic_param_map{$param} } = [ $param, $p{$param} ];
    }

    if ( exists $p{max_future_compat} ) {
        for my $param ( keys %{ $p{max_future_compat} } ) {
            unless ( $param =~ /\A[0-9]+\z/ ) {
                croak
                    "You passed a non-integer key in the max_future_compat parameter: $param";
            }

            $magic_params{$param} = [
                "max_future_compat: $param",
                $p{max_future_compat}{$param},
            ];
        }
    }

    return ( $p{magic_file}, $flags, %magic_params );
}

sub info_from_string {
    my $self = shift;
    return $self->_info_hash( $self->_info_from_string(@_) );
}

sub info_from_filename {
    my $self = shift;
    return $self->_info_hash( $self->_info_from_filename(@_) );
}

sub info_from_handle {
    my $self = shift;
    return $self->_info_hash( $self->_info_from_handle(@_) );
}

sub _info_hash {
    return {
        description        => $_[1],
        mime_type          => $_[2],
        encoding           => $_[3],
        mime_with_encoding => $_[0]->_mime_with_encoding( @_[ 2, 3 ] ),
    };
}

sub _mime_with_encoding {
    return $_[1] unless $_[2];
    return "$_[1]; charset=$_[2]";
}

sub DESTROY {
    my ($self) = @_;

    magic_close( $self->{magic} ) if defined $self->{magic};
}

# Old OO API
sub checktype_contents {
    my ( $self, $data ) = @_;
    return magic_buffer( $self->_mime_handle, $data );
}

sub checktype_filename {
    my ( $self, $filename ) = @_;
    return magic_file( $self->_mime_handle, $filename );
}

sub describe_contents {
    my ( $self, $data ) = @_;
    return magic_buffer( $self->_describe_handle, $data );
}

sub describe_filename {
    my ( $self, $filename ) = @_;
    return magic_file( $self->_describe_handle, $filename );
}

sub _describe_handle {
    my $self = shift;
    _magic_setflags( $self->{magic}, MAGIC_NONE() );
    return $self->{magic};
}

sub _mime_handle {
    my $self = shift;
    _magic_setflags( $self->{magic}, MAGIC_MIME() );
    return $self->{magic};
}

# To find the maximum value for magic_setparam we first check the next 10
# values after the highest known param constant. We expect this to be
# sufficient in nearly every case. But just in case we'll also continue
# checking up to 0xFFFF if there are more than 10 values we don't know about.
{
    my $Max;

    sub max_param_constant {
        return $Max if defined $Max;

        my $m = magic_open(0);

        return $Max = 0
            unless keys %magic_param_map;

        my $value = 0;
        my $min   = max values %magic_param_map;
        my $max   = $min + 10;

        for my $param ( $min .. $max ) {
            unless ( _magic_param_exists( $m, $param, $value ) ) {
                magic_close($m);
                return $Max = $param - 1;
            }
        }

        $min = $max;
        $max = 0xFFFF;
        while ( $min <= $max ) {
            my $mid = int( ( $min + $max ) / 2 );
            if ( _magic_param_exists( $m, $mid, $value ) ) {
                $min = $mid + 1;
            }
            else {
                $max = $mid - 1;
            }
        }
        magic_close($m);

        return $Max = $min - 1;
    }
}

sub limit_key_is_supported {
    return exists $magic_param_map{ $_[1] };
}

1;

# ABSTRACT: Determine MIME types of data or files using libmagic

__END__

=pod

=encoding UTF-8

=head1 NAME

File::LibMagic - Determine MIME types of data or files using libmagic

=head1 VERSION

version 1.23

=head1 SYNOPSIS

  use File::LibMagic;

  my $magic = File::LibMagic->new;

  my $info = $magic->info_from_filename('path/to/file');
  # Prints a description like "ASCII text"
  print $info->{description};
  # Prints a MIME type like "text/plain"
  print $info->{mime_type};
  # Prints a character encoding like "us-ascii"
  print $info->{encoding};
  # Prints a MIME type with encoding like "text/plain; charset=us-ascii"
  print $info->{mime_with_encoding};

  my $file_content = read_file('path/to/file');
  $info = $magic->info_from_string($file_content);

  open my $fh, '<', 'path/to/file' or die $!;
  $info = $magic->info_from_handle($fh);

=head1 DESCRIPTION

The C<File::LibMagic> module is a simple perl interface to libmagic from the
file package (version 4.x or 5.x). You will need both the library
(F<libmagic.so>) and the header file (F<magic.h>) to build this Perl module.

=head2 Installing libmagic

On Debian/Ubuntu run:

    sudo apt-get install libmagic-dev

on Red Hat run:

    sudo yum install file-devel

On Mac you can use homebrew (https://brew.sh/):

    brew install libmagic

=head2 Specifying lib and/or include directories

On some systems, you may need to pass additional lib and include directories
to the Makefile.PL. You can do this with the `--lib` and `--include`
parameters:

    perl Makefile.PL --lib /usr/local/lib --include /usr/local/include

You can pass these parameters multiple times to specify more than one
location.

=head1 API

This module provides an object-oriented API with the following methods:

=head2 File::LibMagic->new

Creates a new File::LibMagic object.

Using the object oriented interface only opens the magic database once, which
is probably most efficient for repeated uses.

Each C<File::LibMagic> object loads the magic database independently of other
C<File::LibMagic> objects, so you may want to share a single object across
many modules.

This method takes the following named parameters:

=over 4

=item * C<magic_file>

This should be a string or an arrayref containing one or more magic files.

If a file you provide doesn't exist the constructor will throw an exception,
but only with libmagic 4.17+.

If you don't set this parameter, the constructor will throw an exception if it
can't find any magic files at all.

Note that even if you're using a custom file, you probably I<also> want to use
the standard file (F</usr/share/misc/magic> on my system, yours may vary).

=item * C<follow_symlinks>

If this is true, then calls to C<< $magic->info_from_filename >> will follow
symlinks to the real file.

=item * C<uncompress>

If this is true, then compressed files (such as gzip files) will be
uncompressed, and the various C<< info_from_* >> methods will return info
about the uncompressed file.

=item * Processing limits

Newer versions of the libmagic library have a number of limits order to
prevent malformed or malicious files from causing resource exhaustion or other
errors.

If your libmagic support it, you can set the following limits through
constructor parameters. If your version does not support setting these limits,
passing these options will cause the constructor to croak. In addition, the
specific limits were introduced over a number of libmagic releases, and your
version of libmagic may not support every parameter. Using a parameter that is
not supported by your libmagic will also cause the constructor to cloak.

=over 8

=item * C<max_indir>

This limits recursion for indirection when processing entries in the
magic file.

=item * C<max_name>

This limits the maximum number of levels of name/use magic that will be
processed in the magic file.

=item * C<max_elf_notes>

This limits the maximum number of ELF notes that will be processed when
determining a file's mime type.

=item * C<max_elf_phnum>

This limits the maximum number of ELF program sections that will be processed
when determining a file's mime type.

=item * C<max_elf_shnum>

This limits the maximum number of ELF sections that will be processed when
determining a file's mime type.

=item * C<max_regex>

This limits the maximum size of regexes when processing entries in the magic
file.

=item * C<max_bytes>

This limits the maximum number of bytes read from a file when determining a
file's mime type.

=back

The values of these parameters should be integer limits.

=item * C<max_future_compat>

For compatibility with future additions to the libmagic processing limit
parameters, you can pass a C<max_future_compat> parameter. This is a hash
reference where the keys are constant values (integers defined by libmagic,
not names) and the values are the limit you want to set.

=back

=head2 $magic->info_from_filename('path/to/file')

This method returns info about the given file. The return value is a hash
reference with four keys:

=over 4

=item * C<description>

A textual description of the file content like "ASCII C program text".

=item * C<mime_type>

The MIME type without a character encoding, like "text/x-c".

=item * C<encoding>

Just the character encoding, like "us-ascii".

=item * C<mime_with_encoding>

The MIME type with a character encoding, like "text/x-c;
charset=us-ascii". Note that if no encoding was found, this will be the same
as the C<mime_type> key.

=back

=head2 $magic->info_from_string($string)

This method returns info about the contents of the given string. The string
can be passed as a reference to save memory.

The return value is the same as that of C<< $mime->info_from_filename >>.

=head2 $magic->info_from_handle($fh)

This method returns info about the contents read from the given filehandle. It
will read data starting from the handle's current position, and leave the
handle at that same position after reading.

=head2 File::LibMagic->max_param_constant

This method returns the maximum value that can be passed as a processing limit
parameter to the constructor. You can use this to determine if passing a
particular value in the C<max_future_compat> constructor parameter will work.

This may include constant values that do not have corresponding C<max_X>
constructor keys if your version of libmagic is newer than the one used to
build this distribution.

Conversely, if your version is older than it's possible that not all of the
defined keys will be supported.

=head2 File::LibMagic->limit_key_is_supported($key)

This method takes a processing limit key like C<max_indir> or C<max_name> and
returns a boolean indicating whether the linked version of libmagic supports
that processing limit.

=head1 DISCOURAGED APIS

This module offers two different procedural APIs based on optional exports,
the "easy" and "complete" interfaces. There is also an older OO API still
available. All of these APIs are discouraged, but will not be removed in the
near future, nor will using them cause any warnings.

I strongly recommend you use the new OO API. It's simpler than the complete
interface, more efficient than the easy interface, and more featureful than
the old OO API.

=head2 The Old OO API

This API uses the same constructor as the current API.

=over 4

=item * $magic->checktype_contents($data)

Returns the MIME type of the data given as the first argument. The data can be
passed as a plain scalar or as a reference to a scalar.

This is the same value as would be returned by the C<file> command with the
C<-i> switch.

=item * $magic->checktype_filename($filename)

Returns the MIME type of the given file.

This is the same value as would be returned by the C<file> command with the
C<-i> switch.

=item * $magic->describe_contents($data)

Returns a description (as a string) of the data given as the first argument.
The data can be passed as a plain scalar or as a reference to a scalar.

This is the same value as would be returned by the C<file> command with no
switches.

=item * $magic->describe_filename($filename)

Returns a description (as a string) of the given file.

This is the same value as would be returned by the C<file> command with no
switches.

=back

=head2 The "easy" interface

This interface is exported by:

  use File::LibMagic ':easy';

This interface exports two subroutines:

=over 4

=item * MagicBuffer($data)

Returns the description of a chunk of data, just like the C<describe_contents>
method.

=item * MagicFile($filename)

Returns the description of a file, just like the C<describe_filename> method.

=back

=head2 The "complete" interface

This interface is exported by:

  use File::LibMagic ':complete';

This interface exports several subroutines:

=over 4

=item * magic_open($flags)

This subroutine opens creates a magic handle. See the libmagic man page for a
description of all the flags. These are exported by the C<:complete> import.

  my $handle = magic_open(MAGIC_MIME);

=item * magic_load($handle, $filename)

This subroutine actually loads the magic file. The C<$filename> argument is
optional. There should be a sane default compiled into your C<libmagic>
library.

=item * magic_buffer($handle, $data)

This returns information about a chunk of data as a string. What it returns
depends on the flags you passed to C<magic_open>, a description, a MIME type,
etc.

=item * magic_file($handle, $filename)

This returns information about a file as a string. What it returns depends on
the flags you passed to C<magic_open>, a description, a MIME type, etc.

=item * magic_close($handle)

Closes the magic handle.

=back

=head1 EXCEPTIONS

This module can throw an exception if your system runs out of memory when
trying to call C<magic_open> internally.

=head1 BUGS

This module is totally dependent on the version of file on your system. It's
possible that the tests will fail because of this. Please report these
failures so I can make the tests smarter. Please make sure to report the
version of file on your system as well!

=head1 DEPENDENCIES/PREREQUISITES

This module requires file 4.x or file 5x and the associated libmagic library
and headers (https://darwinsys.com/file/).

=head1 RELATED MODULES

Andreas created File::LibMagic because he wanted to use libmagic (from
file 4.x) L<File::MMagic> only worked with file 3.x.

L<File::MimeInfo::Magic> uses the magic file from freedesktop.org which is
encoded in XML, and is thus not the fastest approach. See
L<https://mail.gnome.org/archives/nautilus-list/2003-December/msg00260.html>
for a discussion of this issue.

L<File::Type> uses a relatively small magic file, which is directly hacked
into the module code. It is quite fast but the database is quite small
relative to the file package.

=head1 SUPPORT

Please submit bugs to the CPAN RT system at
https://rt.cpan.org/Public/Dist/Display.html?Name=File-LibMagic or via email at
bug-file-libmagic@rt.cpan.org.

Bugs may be submitted at L<https://github.com/houseabsolute/File-LibMagic/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for File-LibMagic can be found at L<https://github.com/houseabsolute/File-LibMagic>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<https://www.urth.org/fs-donation.html>.

=head1 AUTHORS

=over 4

=item *

Andreas Fitzner

=item *

Michael Hendricks <michael@ndrix.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 CONTRIBUTORS

=for stopwords E. Choroba Mithun Ayachit Olaf Alders Paul Wise Tom Wyant

=over 4

=item *

E. Choroba <choroba@matfyz.cz>

=item *

Mithun Ayachit <mayachit@amfam.com>

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Paul Wise <pabs3@bonedaddy.net>

=item *

Tom Wyant <wyant@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Andreas Fitzner, Michael Hendricks, Dave Rolsky, and Paul Wise.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
