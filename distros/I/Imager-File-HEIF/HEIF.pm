package Imager::File::HEIF;
use strict;
use Imager;
use Imager::File::HEIF::Encoder;
use Imager::File::HEIF::Encoder::Parameter;

our $VERSION;

BEGIN {
  $VERSION = "0.007";

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

END {
  __PACKAGE__->deinit();
}

1;


__END__

=head1 NAME

Imager::File::HEIF - read and write HEIF files

=head1 SYNOPSIS

  use Imager;
  # before Imager 1.013 you need to explicitly load this
  use Imager::File::HEIF;

  my $img = Imager->new;
  $img->read(file => "foo.heif")
    or die $img->errstr;

  # type won't be necessary if the extension is heif from Imager 1.008
  $img->write(file => "foo.heif", type => "heif")
    or die $img->errstr;

=head1 DESCRIPTION

Implements F<.heif> file support for Imager.

=head1 CLASS METHODS

=over

=item libversion()

=item buildversion()

  my $lib_version   = Imager::File::HEIF->libversion;
  my $build_version = Imager::File::HEIF->buildversion;

Returns the version of C<libheif>, either the version of the library
currently being used, or the version that Imager::File::HEIF was built
with.

These might differ because the library was updated after
Imager::File::HEIF was built.

=item init()

=item deinit()

  Imager::File::HEIF->init;
  Imager::File::HEIF->deinit;

You do not need to call these in normal code.

Initialise or clean up respectively the state of C<libheif>.

These require C<libheif> 1.13.0 or later to have any effect.

Imager::File::HEIF will call these on load and at C<END> time
respectively.

In practice C<libx265> still leaves a lot of memory leaked in my
testing.

=item dump_encoders

  Imager::File::HEIF->dump_encoders

Dump information about each encoder configured for C<libheif> to
standard output.  See the C</encoders> method for programmatic access.

For example:

  265 HEVC encoder (4.1+1-1d117be) (x265):
    Format: hevc
    Lossless: Yes
    Lossy: Yes
    Parameters:
      quality (int): 0 ... 100 (default 50)
      lossless (boolean): (default false)
      preset (str): "ultrafast" "superfast" "veryfast" "faster" "fast" "medium" "slow" "slower" "veryslow" "placebo" (default "slow")
      tune (str): "psnr" "ssim" "grain" "fastdecode" (default "ssim")
      tu-intra-depth (int): 1 ... 4 (default 2)
      complexity (int): 0 ... 100 (default 0)
      chroma (str): "420" "422" "444" (default "420")

The first line for each is a descriptive name of the encoder followed
by the identifier for that encoder, which can be supplied as
C<heif_encoder> when writing an image.

C<Format> is the compression supported by this encoder.

C<Lossless> reports whether the encoder supports lossless encoding.

C<Lossy> reports whether the encoder supports lossy encoding.

C<Parameters> lists the paremeters supported by this encoder, which
can be set when writing.

=item dump_decoders

  Imager::File::HEIF->dump_decoders

Dump information about each encoder.  This provides very little
information and may list a decoder more than once if it supports more
than one (de-)compression.

  libde265 HEVC decoder, version 1.0.15 (libde265):
    Format: hevc
  FFMPEG HEVC decoder 7.1.3-0+deb13u1 (ffmpeg):
    Format: hevc
  libjpeg-turbo 2.1.5 (libjpeg 6.2) (jpeg):
    Format: jpeg

=item have_decoder_for($compression)

  if (Imager::File::HEIF->have_decoder_for("jpeg")) {
    ...

Returns true if C<libheif> supports decoding the given compression
type.  Throws an exception for a compression type that this version of
C<libheif> doesn't support.

=item have_encoder_for($compression)

  if (Imager::File::HEIF->have_encoder_for("jpeg")) {
    ...

Returns true if C<libheif> supports encoding the given compression
type.  Throws an exception for a compression type that this version of
C<libheif> doesn't support.

=item compression_names

Returns a list of compression names suitable for the have_encoder_for,
have_decoder_for and encoders methods, or for the C<heif_compression>
write parameter.

This includes the C<"undefined"> (not the perl C<undef>) method only
accepted by the L</encoders> method.

=item encoders

=item encoders($compression)

Returns a list of L<Imager::File::HEIF::Encoder> objects, which
provides information about each encoder the C<libheif>
Imager::File::HEIF was built against.

If C<$compression> is supplied only decoders supporting that
compression are returned.  This defaults to C<"undefined"> (not the
perl C<undef>) which returns all encoders.

If an unknown compression name is supplied this method will throw an
exception.

=back

=head1 PATENTS

The h.265 compression libheif uses is covered by patents, if you use
this code for commercial purposes you may need to license those
patents.

=head1 LICENSING

Imager::File::HEIF itself and Imager are licensed under the same terms
as Perl itself, and C<libheif> is licensed under the LGPL 3.0.

But C<libx264>, which C<libheif> is typically built to use for
encoding, is licensed under the GPL 2.0, and the owners provide a
L<fairly strict interpretation of that
license|https://www.x265.org/x265-licensing-faq/>.  They also sell
commercial licenses.

=head1 INSTALLATION

To install Imager::File::HEIF you need Imager installed and you need
C<libheif>, C<libde265> and C<libx265> and their development files.

Imager::File::HEIF requires at least version 1.11.0 of C<libheif>, but
in general you want the very latest version you can get.
Imager::File::HEIF has been tested up to version 1.21.2 of C<libheif>.

1.14 through 1.16 need C<LIBDE265> support installed as part of the
library, not as a plugin.

=head1 STANDARD IMAGER TAGS

Imager::File::HEIF supports the C<i_xres> and C<i_yres> tags, but only
for setting or retrieving the pixel aspect ratio.  As generally a
photographic or movie format, HEIF doesn't support physical
resolution, which is generally a print or scan mechanism.

C<i_aspect_only> is ignored on writing, C<i_xres> and C<i_yres> are
treated as an aspect ratio.

When you read a HEIF image C<i_xres> and C<i_yres> are set from the
aspect ratio and C<i_aspect_only> is set to 1.

=head1 CONTROLLING COMPRESSION

You can control output through a number of tags, (implicitly set on
the images via write() or write_multi()):

=over

=item *

C<heif_lossless> - if non-zero the image is compressed in "lossless"
mode.  Note that in both lossy and lossless modes the image is
converted from the RGB colorspace to the YCbCr colorspace, which will
lose information.  In lossless mode the C<heif_quality> value is
ignored and irrelevant.  Default: set by the C<libheif> encoder.

=item *

C<heif_quality> - a value from 0 to 100 representing the quality of
lossy compression.  Default: set by the C<libheif> encoder.

=item *

C<heif_compression> - the compression type to use, this defaults to
"hevc".  The values supported depend on the version of C<libheif> and
how it was built.  You can use different compression methods for
different images in a multi-image file, but don't be too surprised if
readers fail to read it.

Using a compression other than C<hevc> with the C<.heif> extension may
confuse other software.

Be aware this chooses the compression inside the ISOBMFF file,
selecting C<jpeg> compression does not produce a JPEF/JFIF file.

=item *

C<heif_encoder> - the identifier of the encoder to use, this also sets
the compression to use, if you also supply C<heif_compression> and it
doesn't match the compression used by this encoder writing will fail.
Default: an encoder is selected by C<libheif> based on the compression
selected.

=back

Other parameters set by the encoder can also be set by setting a tag
with that name with a C<heif_> prefix.  You can see a list of
parameters for each encoder using the dump_encoders() method, or by
calling the parameters() method on the encoder object returned by the
encoders() method.

So you can set the C<chroma> with the C<heif_chroma> tag:

  $img->write(..., heif_chroma => "444")...

Parameter names can contain dashes and these are reflected in the tag
names:

  # from the AOM AV1 encoder
  $img->write(..., "heif_alpha-quality" => 80) ...

If the encoder has C<quality> or C<lossless> parameters those are
handled by their dedicated APIs, not via the general "parameter" API.

If setting such a parameter fails, writing will fail.

Unfortunately the only way to see if the parameter was recognized is
to enable logging and examine the log.

B<WARNING>: from my testing, using the rough measure done by Imager
i_img_diff(), lossy at 80 quality turned out closer to the original
image than lossless.

=head1 RESOURCE USAGE

HEIF processing is fairly resource intensive, and libheif uses
multiple decoding threads by default when you read a HEIF image.

With C<libheif> 1.13.0 or later you can set
C<$Imager::File::HEIF::MaxThreads> to the maximum number of threads to
use.  If this is negative or not defined the default is used, which is
defined by C<libheif>.

=head1 BUGS

Imager::File::HEIF have_decoder_for() returns false for C<av1> before
libheif 1.13, neither Imager::File::HEIF nor the libheif tools were
able to decode C<av1> encoded files created by the libheif tool, even
with C<av1> support enabled in libheif.

=head1 TODO

=over

=item *

10-bit/sample and 12-bit/sample images.  Based on
L<https://github.com/strukturag/libheif/issues/40> this might not be
supported completely yet.

=item *

reading metadata (any to read?)

=item *

writing metadata.  We don't seem to have the animation metadata that
webp does. (image sequences seems to have it)

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

=head1 GLOSSARY

=over

=item ISOBMFF

ISO Base Media File Format - the container file format defined by
ISO/IEC 14496-12 used by HEIF, AVIF, JPEG2000 and many non-image
formats. See https://en.wikipedia.org/wiki/ISO_base_media_file_format.

=back

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=head1 SEE ALSO

L<Imager>, L<Imager::Files>.

https://en.wikipedia.org/wiki/High_Efficiency_Image_File_Format

https://github.com/strukturag/libheif

https://github.com/strukturag/libde265 - x265 decoder

https://www.x265.org/ - x265 encoder

=cut
