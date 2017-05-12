package GPS::Babel;

use warnings;
use strict;
use Carp;
use Geo::Gpx 0.15;
use File::Which qw(which);
use IO::Handle;
use Scalar::Util qw(blessed);

our $VERSION = '0.11';

my $EXENAME = 'gpsbabel';

sub new {
  my $class = shift;
  my $args  = shift || {};
  my $self  = bless {}, $class;

  if ( exists $args->{exename} ) {
    my $exename = delete $args->{exename};
    $exename = [$exename] unless ref $exename eq 'ARRAY';
    $self->set_exename( @$exename );
  }
  else {
    $self->set_exename( which( $EXENAME ) || () );
  }

  return $self;
}

sub get_exename {
  my $self = shift;
  return @{ $self->{exepath} };
}

sub set_exename {
  my $self = shift;
  $self->{exepath} = [@_];
}

sub check_exe {
  my $self = shift;

  my @exe = $self->get_exename;
  croak "$EXENAME not found" unless @exe;
  return @exe;
}

sub _with_babel {
  my $self = shift;
  my ( $mode, $opts, $cb ) = @_;

  my @exe = $self->check_exe;
  my $exe_desc = "'" . join( "' '", @exe ) . "'";

  my @args = ( @exe, @{$opts} );

  if ( $^O =~ /MSWin32/ ) {
    # Windows: shell escape and collapse to a single string
    @args = ( '"' . join( '" "', map { s/"/""/g } @args ) . '"' );
  }

  open( my $fh, $mode, @args )
   or die "Can't execute $exe_desc ($!)\n";
  $cb->( $fh );
  $fh->close or die "$exe_desc failed ($?)\n";
}

sub _with_babel_reader {
  my $self = shift;
  my ( $opts, $cb ) = @_;

  $self->_with_babel( '-|', $opts, $cb );
}

sub _with_babel_lines {
  my $self = shift;
  my ( $opts, $cb ) = @_;
  my @buf   = ();
  my $flush = sub {
    my $line = join '', @buf;
    $cb->( $line ) unless $line =~ /^\s*$/;
    @buf = ();
  };
  $self->_with_babel_reader(
    $opts,
    sub {
      my $fh = shift;
      while ( defined( my $line = <$fh> ) ) {
        chomp $line;
        $flush->() unless $line =~ /^\s+/;
        push @buf, $line;
      }
    }
  );
  $flush->();
}

sub _with_babel_writer {
  my $self = shift;
  my ( $opts, $cb ) = @_;

  $self->_with_babel( '|-', $opts, $cb );
}

sub _tidy {
  my $str = shift;
  $str = '' unless defined $str;
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  $str =~ s/\s+/ /g;
  return $str;
}

sub _find_info {
  my $self = shift;

  my $info = {
    formats => {},
    filters => {},
    for_ext => {}
  };

  # Read the version
  $self->_with_babel_reader(
    ['-V'],
    sub {
      my $fh = shift;
      local $/;
      $info->{banner} = _tidy( <$fh> );
    }
  );

  if ( $info->{banner} =~ /([\d.]+)/ ) {
    $info->{version} = $1;
  }
  else {
    $info->{version} = '0.0.0';
  }

  my $handle_extra = sub {
    my @extra = @_;
    return unless @extra;
    my $doclink = shift @extra;
    return (
      doclink => $doclink,
      @extra ? ( extra => \@extra ) : ()
    );
  };

  # -^3 and -%1 are 1.2.8 and later
  if ( _cmp_ver( $info->{version}, '1.2.8' ) >= 0 ) {

    # File formats
    $self->_with_babel_lines(
      ['-^3'],
      sub {
        my $ln = shift;
        my ( $type, @f ) = split( /\t/, $ln );
        if ( $type eq 'file' ) {
          my ( $modes, $name, $ext, $desc, $parent, @extra, ) = @f;
          ( my $nmodes = $modes ) =~ tr/rw-/110/;
          $nmodes = oct( '0b' . $nmodes );
          $info->{formats}->{$name} = {
            modes  => $modes,
            nmodes => $nmodes,
            desc   => $desc,
            parent => $parent,
            $handle_extra->( @extra ),
          };
          if ( $ext ) {
            $ext =~ s/^[.]//;    # At least one format has a stray '.'
            $ext = lc( $ext );
            $info->{formats}->{$name}->{ext} = $ext;
            push @{ $info->{for_ext}->{$ext} }, $name;
          }
        }
        elsif ( $type eq 'option' ) {
          my ( $fname, $name, $desc, $type, $default, $min, $max,
            @extra, )
           = @f;
          $info->{formats}->{$fname}->{options}->{$name} = {
            desc    => $desc,
            type    => $type,
            default => $default || '',
            min     => $min || '',
            max     => $max || '',
            $handle_extra->( @extra ),
          };
        }
        else {

          # Something we don't know about - so ignore it
        }
      }
    );

    # Filters
    $self->_with_babel_lines(
      ['-%1'],
      sub {
        my $ln = shift;
        my ( $name, @f ) = split( /\t/, $ln );
        if ( $name eq 'option' ) {
          my ( $fname, $oname, $desc, $type, @extra ) = @f;
          my @valid = splice @extra, 0, 3;
          $info->{filters}->{$fname}->{options}->{$oname} = {
            desc  => $desc,
            type  => $type,
            valid => \@valid,
            $handle_extra->( @extra ),
          };
        }
        else {
          $info->{filters}->{$name} = { desc => $f[0] };
        }
      }
    );
  }

  return $info;
}

sub get_info {
  my $self = shift;

  return $self->{info} ||= $self->_find_info;
}

sub banner {
  my $self = shift;
  return $self->get_info->{banner};
}

sub version {
  my $self = shift;
  return $self->get_info->{version};
}

sub _cmp_ver {
  my ( $v1, $v2 ) = @_;
  my @v1 = split( /[.]/, $v1 );
  my @v2 = split( /[.]/, $v2 );

  while ( @v1 && @v2 ) {
    my $cmp = ( shift @v1 <=> shift @v2 );
    return $cmp if $cmp;
  }

  return @v1 <=> @v2;
}

sub got_ver {
  my $self = shift;
  my $need = shift;
  my $got  = $self->version;
  return _cmp_ver( $got, $need ) >= 0;
}

sub guess_format {
  my $self = shift;
  my $name = shift;
  my $dfmt = shift;

  croak( "Missing filename" )
   unless defined( $name );

  my $info = $self->get_info;

  # Format specified
  if ( defined( $dfmt ) ) {
    croak( "Unknown format \"$dfmt\"" )
     if %{ $info->{formats} }
       && !exists( $info->{formats}->{$dfmt} );
    return $dfmt;
  }

  croak( "Filename \"$name\" has no extension" )
   unless $name =~ /[.]([^.]+)$/;

  my $ext = lc( $1 );
  my $fmt = $info->{for_ext}->{$ext};

  croak( "No format handles extension .$ext" )
   unless defined( $fmt );

  my @fmt = sort @{$fmt};

  return $fmt[0] if @fmt == 1;

  my $last = pop @fmt;
  my $list = join( ' and ', join( ', ', @fmt ), $last );

  croak( "Multiple formats ($list) handle extension .$ext" );
}

sub _convert_opts {
  my $self = shift;
  my $inf  = shift;
  my $outf = shift;
  my $opts = shift || {};

  croak "Must provide input and output filenames"
   unless defined( $outf );

  my $infmt  = $self->guess_format( $inf,  $opts->{in_format} );
  my $outfmt = $self->guess_format( $outf, $opts->{out_format} );

  my $info = $self->get_info;

  my $inmd  = $info->{formats}->{$infmt}->{nmodes}  || 0b111111;
  my $outmd = $info->{formats}->{$outfmt}->{nmodes} || 0b111111;

 # Work out which modes can be read by the input format /and/ written by
 # the output format.
  my $canmd = ( $inmd >> 1 ) & $outmd;

  my @proc = ();
  push @proc, '-r' if ( $canmd & 0x01 );
  push @proc, '-t' if ( $canmd & 0x04 );
  push @proc, '-w' if ( $canmd & 0x10 );

  croak
   "Formats $infmt and $outfmt have no read/write capabilities in common"
   unless @proc;

  my @opts = (
    '-p', '',   @proc,   '-i', $infmt, '-f',
    $inf, '-o', $outfmt, '-F', $outf
  );

  return @opts;
}

sub convert {
  my $self = shift;

  my @opts = $self->_convert_opts( @_ );

  $self->direct( @opts );
}

sub direct {
  my $self = shift;

  if ( system( $self->check_exe, @_ ) ) {
    croak( "$EXENAME failed with error " . ( ( $? == -1 ) ? $! : $? ) );
  }
}

sub read {
  my $self = shift;
  my $inf  = shift;
  my $opts = shift || {};

  require Geo::Gpx;

  croak "Must provide an input filename"
   unless defined( $inf );

  $opts->{out_format} = 'gpx';

  my @opts = $self->_convert_opts( $inf, '-', $opts );
  my $gpx = undef;

  $self->_with_babel_reader(
    \@opts,
    sub {
      my $fh = shift;
      $gpx = Geo::Gpx->new( input => $fh );
    }
  );

  return $gpx;
}

sub write {
  my $self = shift;
  my $outf = shift;
  my $gpx  = shift;
  my $opts = shift || {};

  croak "Must provide some data to output"
   unless blessed( $gpx ) && $gpx->can( 'xml' );

  $opts->{in_format} = 'gpx';

  my $xml = $gpx->xml;

  my @opts = $self->_convert_opts( '-', $outf, $opts );
  $self->_with_babel_writer(
    \@opts,
    sub {
      my $fh = shift;
      $fh->print( $xml );
    }
  );
}

1;
__END__

=head1 NAME

GPS::Babel - Perl interface to gpsbabel

=head1 VERSION

This document describes GPS::Babel version 0.11

=head1 SYNOPSIS

    use GPS::Babel;

    my $babel = GPS::Babel->new();

    # Read an OZIExplorer file into a data structure
    my $data  = $babel->read('route.ozi', 'ozi');

    # Convert a file automatically choosing input and output
    # format based on extension
    $babel->convert('points.wpt', 'points.gpx');

    # Call gpsbabel directly
    $babel->direct(qw(gpsbabel -i saroute,split
        -f in.anr -f in2.anr -o an1,type=road -F out.an1));

=head1 DESCRIPTION

From L<http://gpsbabel.org/>:

    GPSBabel converts waypoints, tracks, and routes from one format to
    another, whether that format is a common mapping format like
    Delorme, Streets and Trips, or even a serial upload or download to a
    GPS unit such as those from Garmin and Magellan. By flattening the
    Tower of Babel that the authors of various programs for manipulating
    GPS data have imposed upon us, it returns to us the ability to
    freely move our own waypoint data between the programs and hardware
    we choose to use.

As I write this C<gpsbabel> supports 96 various GPS related data
formats. In addition to file conversion it supports upload and
download to a number of serial and USB devices. This module provides a
(thin) wrapper around the gpsbabel binary making it easier to use in a
perlish way.

GPSBabel supports many options including arbitrary chains of filters,
merging data from multiple files and many format specific parameters.
This module doesn't attempt to provide an API wrapper around all these
options. It does however provide for simple access to the most common
operations. For more complex cases a passthrough method (C<direct>)
passes its arguments directly to gpsbabel with minimal preprocessing.

GPSBabel is able to describe its built in filters and formats and
enumerate the options they accept. This information is available as a
perl data structure which may be used to construct a dynamic user
interface that reflects the options available from the gpsbabel binary.

=head2 Format Guessing

C<GPS::Babel> queries the capabilities of C<gpsbabel> and can use this
information to automatically choose input and output formats based on
the extensions of filenames. This makes it possible to, for example,
create tools that bulk convert a batch of files choosing the correct
format for each one.

While this can be convenient there is an important caveat: if more than
one format is associated with a particular extension GPS::Babel will
fail rather than risking making the wrong guess. Because new formats are
being added to gpsbabel all the time it's possible that a format that
can be guessed today will become ambiguous tomorrow. That raises the
spectre of a program that works now breaking in the future.

Also some formats support a particular extension without explicitly
saying so - for example the compegps format supports .wpt files but
gpsbabel (currently) reports that the only format explicitly associated
with the .wpt extension is xmap. This means that C<GPS::Babel> will
confidently guess that the format for a file called something.wpt is
xmap even if the file contains compegps data.

In general then you should only use format guessing in applications
where the user will have the opportunity to select a format explicitly
if an unambiguous guess can't be made. For applications that must run
unattended or where the user doesn't have this kind of control you
should make the choice of filter explicit by passing C<in_format> and/or
C<out_format> options to C<read>, C<write> and C<convert> as
appropriate.

=head1 INTERFACE

=over

=item C<new( { options } )>

Create a new C<GPS::Babel> object. Optionally the exename option may
be used to specify the full name of the gpsbabel executable

    my $babel = GPS::Babel->new({
        exename => 'C:\GPSBabel\gpsbabel.exe'
    });

=item C<check_exe()>

Verify that the name of the gpsbabel executable is known throwing an
error if it isn't. This is generally called by other methods but you may
call it yourself to cause an error to be thrown early in your program if
gpsbabel is not available.

=item C<get_info()>

Returns a reference to a hash that describes the capabilities of your
gpsbabel binary. The format of this hash is probably best explored by
running the following script and perusing its output:

    #!/usr/bin/perl -w

    use strict;
    use GPS::Babel;
    use Data::Dumper;

    $| = 1;

    my $babel = GPS::Babel->new();
    print Dumper($babel->get_info());

This script is provided in the distribution as C<scripts/babel_info.pl>.

In general the returned hash has the following structure:

    $info = {
        version     => $gpsbabel_version,
        banner      => $gpsbabel_banner,
        filters     => {
            # big hash of filters
        },
        formats     => {
            # big hash of formats
        },
        for_ext     => {
            # hash mapping lower case extension name to a list
            # of formats that use that extension
        }
    };

The C<filters>, C<formats> and C<for_ext> hashes are only present if you have
gpsbabel 1.2.8 or later installed.

=item C<banner()>

Get the GPSBabel banner string - the same string that is output by the command

    $ gpsbabel -V

=item C<version()>

Get the GPSBabel version number. The version is extracted from the banner string.

    print $babel->version(), "\n";

=item C<got_ver( $ver )>

Return true if the available version of gpsbabel is equal to or greater
than the supplied version string. For example:

    die "I need gpsbabel 1.3.0 or later\n"
        unless $babel->got_ver('1.3.0');

=item C<guess_format( $filename )>

Given a filename return the name of the gpsbabel format that handles
files of that type. Croaks with a suitable message if the format can't
be identified from the extension. If more than one format matches an
error listing all of the matching formats will be thrown.

Optionally a format name may be supplied as the second argument in which
case an error will be thrown if the installed gpsbabel doesn't support
that format.

Format guessing only works with gpsbabel 1.2.8 or later. As mentioned
above, the requirement that an extension maps unambiguously to a format
means that installing a later version of gpsbabel which adds support for
another format that uses the same extension can cause code that used to
work to stop working. For this reason format guessing should only be
used in interactive programs that give the user the opportunity to
specify a format explicitly if such an ambiguity exists.

=item C<get_exename()>

Get the name of the gpsbabel executable that will be used. This defaults
to whatever File::Which::which('gpsbabel') returns. To use a particular
gpsbabel binary either pass the path to the constructor using the
'exename' option or call C<set_exename( $path )>.

=item C<set_exename( $path )>

Set the path and name of the gpsbabel executable to use. The executable
doesn't have to be called 'gpsbabel' - although naming any other program
is unlikely to have pleasing results...

    $babel->set_exename('/sw/bin/gpsbabel');

=item C<read( $filename [, { $options } ] )>

Read a file in a format supported by gpsbabel into a C<Geo::Gpx> object.
The input format is guessed from the filename unless supplied explicitly
in the options like this

    $data = $babel->read('hotels.wpt', { in_format => 'xmap' });

See C<Geo::Gpx> for documentation on the returned object.

=item C<write( $filename, $gpx_data [, { $options }] )>

Write GPX data (typically in the form of an instance of C<Geo::Gpx>) to
a file in one of the formats gpsbabel supports. C<$gpx_data> must be a
reference to an object that exposes a method called C<xml> that returns
a GPX document. C<Geo::Gpx> satisfies this requirement.

The format will be guessed from the filename (see caveats above) or may
be explicitly specified by passing a hash containing C<out_format> as
the third argument:

    $babsel->write('points.kml', $my_points, { out_format => 'kml' });

For consistency the data is filtered through gpsbabel even if the desired
output format is 'gpx'. If you will only be dealing with GPX files use
C<Geo::Gpx> directly.

=item C<convert( $infile, $outfile, [, { $options } ] )>

Convert a file from one format to another. Both formats must be
supported by gpsbabel.

With no options C<convert> attempts to guess the input and output formats
using C<guess_format> - see the caveats about that above. To specify the
formats explicitly supply as a third argument a hash containing the keys
C<in_format> and C<out_format> like this:

    $babel->convert('infile.wpt', 'outfile.kml',
        { in_format => 'compegps', out_format => 'kml' });

gpsbabel treats waypoints, tracks and routes as separate channels of
information and not all formats support reading and writing all three.
C<convert> attempts to convert anything that can be both read by the
input format and written by the output format. If the formats have
nothing in common an error will be thrown.

=item C<direct( @options )>

Invoke gpsbabel with the supplied options. The supplied options are passed
unmodified to system(), for example:

    $babel->direct(qw(-i gpx -f somefile.gpx -o kml -F somefile.kml));

Throws appropriate errors if gpsbabel fails.

=back

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< %s not found >>

Can't find the gpsbabel executable.

=item C<< Missing filename >>

C<guess_format> (or a method that calls it) needs a filename from
which to guess the format.

=item C<< Unknown format "%s" >>

An explicit format was passed to C<guess_format> that doesn't appear
to be supported by the installed gpsbabel.

=item C<< Filename "%s" has no extension >>

Can't guess the format of a filename with no extension.

=item C<< No format handles extension .%s >>

The installed gpsbabel doesn't contain a format that explicitly supports
the named extension. That doesn't necessarily mean that gpsbabel can't
handle the file: many file formats use a number of different extensions
and many gpsbabel input/output modules don't specify the extensions they
support. If in doubt check the gpsbabel documentation and supply the
format explicitly.

=item C<< Multiple formats (%s) handle extension .%s >>

C<guess_format> couldn't unambiguously guess the appropriate format
from the extension. Check the gpsbabel documentation and supply an
explicit format.

=item C<< Must provide input and output filenames >>

C<convert> needs input and output filenames.

=item C<< Formats %s and %s have no read/write capabilities in common >>

Some gpsbabel formats are read only, some are write only, some support only
waypoints or only tracks. C<convert> couldn't find enough common ground
between input and output formats to be able to convert any data.

=item C<< %s failed with error %s >>

A call to gpsbabel failed.

=item C<< Must provide an input filename >>

C<read> needs to know the name of the file to read.

=item C<< Must provide some data to output >>

C<write> needs data to output. The supplied object must expose a
method called C<xml> that returns GPX data. Typically this is achieved
by passing a C<Geo::Gpx>.

=back

=head1 CONFIGURATION AND ENVIRONMENT

GPS::Babel requires no configuration files or environment variables.
With the exception of C<direct()> all calls pass the argument -p '' to
gpsbabel to inhibit reading of any inifile. See L<http://www.gpsbabel.org/htmldoc-
1.3.2/inifile.html> for more details.

=head1 DEPENDENCIES

GPS::Babel needs gpsbabel, ideally installed on your PATH and ideally
version 1.2.8 or later.

In addition GPS::Babel requires the following Perl modules:

    Geo::Gpx (for read, write)
    File::Which

=head1 INCOMPATIBILITIES

GPS::Babel has only been tested with versions 1.3.0 and later of
gpsbabel. It should work with earlier versions but it's advisable to
upgrade to the latest version if possible. The gpsbabel developer
community is extremely active so it's worth having the latest version
installed.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-gps-babel@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

Robert Lipe and numerous contributors did all the work by providing
gpsbabel in the first place. This is just a wafer-thin layer on top of
all their goodness.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
