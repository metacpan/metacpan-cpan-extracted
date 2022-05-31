package Imager::File::AVIF;
use strict;
use Imager;
use vars qw($VERSION @ISA);

BEGIN {
  $VERSION = "0.001";

  require XSLoader;
  XSLoader::load('Imager::File::AVIF', $VERSION);
}

Imager->register_reader
  (
   type=>'avif',
   single => 
   sub { 
     my ($im, $io, %hsh) = @_;

     my $page = $hsh{page};
     defined $page or $page = 0;
     $im->{IMG} = i_readavif($io, $page);

     unless ($im->{IMG}) {
       $im->_set_error(Imager->_error_as_msg);
       return;
     }

     return $im;
   },
   multiple =>
   sub {
     my ($io, %hsh) = @_;

     my @imgs = i_readavif_multi($io);
     unless (@imgs) {
       Imager->_set_error(Imager->_error_as_msg);
       return;
     }

     return map bless({ IMG => $_, ERRSTR => undef }, "Imager"), @imgs;
   },
  );

Imager->register_writer
  (
   type=>'avif',
   single => 
   sub { 
     my ($im, $io, %hsh) = @_;

     $im->_set_opts(\%hsh, "i_", $im);
     $im->_set_opts(\%hsh, "avif_", $im);

     unless (i_writeavif($im->{IMG}, $io)) {
       $im->_set_error(Imager->_error_as_msg);
       return;
     }
     return $im;
   },
   multiple =>
   sub {
     my ($class, $io, $opts, @ims) = @_;

     Imager->_set_opts($opts, "avif_", @ims);

     my @work = map $_->{IMG}, @ims;
     my $result = i_writeavif_multi($io, @work);
     unless ($result) {
       $class->_set_error($class->_error_as_msg);
       return;
     }

     return 1;
   },
  );

sub can_write {
  $_[0]->codecs =~ m!\[enc[\]/]!;
}

sub can_read {
  $_[0]->codecs =~ m![\[/]dec\]!;
}

__END__

=head1 NAME

Imager::File::AVIF - read and write AVIF files

=head1 SYNOPSIS

  use Imager;
  # will be loaded automatically in later versions of Imager when reading or writing
  use Imager::File::AVIF;

  my $img = Imager->new;
  $img->read(file=>"foo.avif")
    or die $img->errstr;

  # type won't be necessary if the extension is avif from Imager 1.008
  $img->write(file => "foo.avif", type => "avif")
    or die $img->errstr;

  use Imager::File::AVIF;
  # do we have the codecs needed to read and write?
  my $can_read  = Imager::File::AVIF->can_read;
  my $can_write = Imager::File::AVIF->can_write;

  # library build/runtime information
  my $codecs    = Imager::File::AVIF->codecs;
  my $libver    = Imager::File::AVIF->libversion;
  my $buildver  = Imager::File::AVIF->buildversion;

=head1 DESCRIPTION

Implements .avif file support for Imager.

At this point this is a very basic implementation, with limited
control over output.

=head1 TAGS

Imager::File::AVIF will use the following tags when writing to AVIF
and set them in images read from AVIF files:

=over

=item *

C<avif_timescale> - the base frame rate of the file.  This must be a
positive integer and is specified in Hz.  i.e. if this is 60 and all
frames have a duration of 1, the file will be playeed at 60 frames per
second.

This is only read from the first images and controls all frames in the
file.

Default: 1Hz.

=item *

C<avif_duration> - the number of timescale units for this frame.
i.e. if C<avif_timescale> is 60, and C<avif_duration> is 2, the frame
will be displayed for 1/30 second.  Default: 1.

=back

The following tag is set in image read from an AVIF file:

=over

=item *

C<avif_total_duration> - the total length of the image sequence in the
units controlled by C<avif_timescale>.

=back

=head1 METHODS

=over

=item can_read()

  if (Imager::File::AVIF->can_read) {
    # we can read AVIF files
  }

Tests whether the C<libavif> codec list includes any codecs capable of
reading.

=item can_write()

  if (Imager::File::AVIF->can_write) {
    # we can write AVIF files
  }

Tests whether the C<libavif> codec list includes any codecs capable of
writing.

=item buildversion()

Returns the version of the C<libavif> library Imager::File::AVIF was
built with.

  print Imager::File::AVIF->buildversion, "\n";

=item libversion()

Returns the version of the C<libavif> library Imager::File::AVIF is
linked with.  This may be different to buildversion() if C<libavif> is
dynamically linked.

  print Imager::File::AVIF->libversion, "\n";

=item codecs()

Returns the codecs C<libavif> was built with, this will look something
like:

  dav1d [dec]:0.7.1, libgav1 [dec]:0.16.1, aom [enc/dec]:v3.3.0

An entry with C<dec> is required to be able to read AVIF images, and
an entry with C<enc> is required to be able to write AVIF images.

  print Imager::File::AVIF->codecs, "\n";

=back

=head1 INSTALLATION

To install Imager::File::AVIF you need Imager installed and you need
C<libavif> installed, along with it's development headers.

Note that the C<libavif> included with Debian bullseye was not built
with a write compatible codec, but C<libavif> from bullseye-backports
does include a write compatible codec.

If you've installed C<libavif> outside the normal places, install
C<pkg-config> and set C<PKG_CONFIG_PATH> to the directory containing
the installed F<libavif.pc> when running C<Makefile.PL>, for example:

  PKG_CONFIG_PATH=/home/tony/local/libavif-0.10.1/lib/pkgconfig/ perl Makefile.PL

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=head1 SEE ALSO

Imager, Imager::Files.

=cut
