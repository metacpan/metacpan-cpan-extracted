package Imager::File::HEIF;
use strict;
use Imager;
use vars qw($VERSION @ISA);

BEGIN {
  $VERSION = "0.003";

  require XSLoader;
  XSLoader::load('Imager::File::HEIF', $VERSION);
}

Imager->register_reader
  (
   type=>'heif',
   single => 
   sub { 
     my ($im, $io, %hsh) = @_;

     my $page = $hsh{page};
     defined $page or $page = 0;
     $im->{IMG} = i_readheif($io, $page);

     unless ($im->{IMG}) {
       $im->_set_error(Imager->_error_as_msg);
       return;
     }

     return $im;
   },
   multiple =>
   sub {
     my ($io, %hsh) = @_;

     my @imgs = i_readheif_multi($io);
     unless (@imgs) {
       Imager->_set_error(Imager->_error_as_msg);
       return;
     }

     return map bless({ IMG => $_, ERRSTR => undef }, "Imager"), @imgs;
   },
  );

Imager->register_writer
  (
   type=>'heif',
   single => 
   sub { 
     my ($im, $io, %hsh) = @_;

     $im->_set_opts(\%hsh, "i_", $im);
     $im->_set_opts(\%hsh, "heif_", $im);

     unless (i_writeheif($im->{IMG}, $io)) {
       $im->_set_error(Imager->_error_as_msg);
       return;
     }
     return $im;
   },
   multiple =>
   sub {
     my ($class, $io, $opts, @ims) = @_;

     Imager->_set_opts($opts, "heif_", @ims);

     my @work = map $_->{IMG}, @ims;
     my $result = i_writeheif_multi($io, @work);
     unless ($result) {
       $class->_set_error($class->_error_as_msg);
       return;
     }

     return 1;
   },
  );

eval {
  # available in some future version of Imager
  Imager->add_file_magic
    (
     name => "heif",
     bits => "    ftypheic",
     mask => "    xxxxxxxx",
    );
};

eval {
  # from Imager 1.008
  Imager->add_type_extensions("heif", "heic", "heif");
};

1;


__END__

=head1 NAME

Imager::File::HEIF - read and write HEIF files

=head1 SYNOPSIS

  use Imager;
  # you need to explicitly load it, or supply a type => "heif" parameter
  use Imager::File::HEIF;

  my $img = Imager->new;
  $img->read(file=>"foo.heif")
    or die $img->errstr;

  # type won't be necessary if the extension is heif from Imager 1.008
  $img->write(file => "foo.heif", type => "heif")
    or die $img->errstr;

=head1 DESCRIPTION

Implements .heif file support for Imager.

=head1 LIMITATIONS

=over

=item *

Due to the limitations of C<heif> (or possibly C<libheif>) grayscale
images are written as RGB images.

=item *

libx265 will
L<reject|https://mailman.videolan.org/pipermail/x265-devel/2018-May/012068.html>
attempts to write images smaller than 64x64 pixels.  Since this may
change in the future I haven't tried to prevent that in Imager itself.

=item *

Imager's images are always RGB or grayscale images, and libheif will
re-encode the RGB data Imager provides to YCbCr for output.  This
inevitably loses some information, and I've seen one
L<complaint|https://github.com/strukturag/libheif/issues/40#issuecomment-428598563>
that libheif's conversion isn't as good as it could be.  Grayscale
images (which are still passed through as RGB) seem to be supported
with very good quality.  YMMV.

=back

=head1 PATENTS

The h.265 compression libheif uses is covered by patents, if you use
this code for commercial purposes you may need to license those
patents.

=head1 INSTALLATION

To install Imager::File::HEIF you need Imager installed and you need
libheif, libde265 and libx265 and their development files.

Development of Imager::File::HEIF was done with the latest development
versions of libheif and libde265 at the time ie from git, older
releases might fail to build or run.

=head1 CONTROLLING COMPRESSION

You can control compression through two tags (implicityly set on the
images via write() or write_multi()):

=over

=item *

C<heif_lossless> - if this is non-zero the image is compressed in
"lossless" mode.  Note that in both lossy and lossless modes the image
is converted from the RGB colorspace to the YCbCr colorspace, which
will lose information.  If non-zero the C<heif_quality> value is
ignored (and irrelevant.)  Default: 0 (lossy compression is used.)

=item *

C<heif_quality> - a value from 0 to 100 representing the quality of
lossy compression.  Default: 80.

=back

B<WARNING>: from my testing, using the rough measure done by Imager
i_img_diff(), lossy at 80 quality turned out closer to the original
image than lossless.

=head1 TODO

=over

=item *

can we hack grayscale by setting the chroma bits to zero?  The sample
code produces a chroma bits 8 image when given a grayscale input PNG,
which is why I suspect the format doesn't support gray, but they might
be a deficiency in the tool.  I tried just adding a Y channel for
grayscale, but that simply made the encoding step crash.

The heif_enc sample creates a YCbCr image and only adds a Y plane.

=item *

10-bit/sample and 12-bit/sample images.  Based on
L<https://github.com/strukturag/libheif/issues/40> this might not be
supported completely yet.

=item *

reading metadata (any to read?) I think pixel ratios are available.
HEIF supports pixel ratios via the C<PixelAspectRatioBox pasp> member
of C<ItemPropertyContainerBox 'ipco'> but libheif doesn't appear to
support that.

=item *

writing metadata.  We don't seem to have the animation metadata that
webp does.

=item *

reading sub-image data?  we can probably skip thumbs (or provide an
option to read the thumb rather than the main image), but are there
other images to read?  Depth images.  Low priority.

=item *

writing sub-image data?  thumbnails and depth images.  Very low
priority.

=item *

Everything else.

=back

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=head1 SEE ALSO

Imager, Imager::Files.

=cut
