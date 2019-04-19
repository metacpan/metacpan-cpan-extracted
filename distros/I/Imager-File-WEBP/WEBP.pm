package Imager::File::WEBP;
use strict;
use Imager;
use vars qw($VERSION @ISA);

BEGIN {
  $VERSION = "0.005";

  require XSLoader;
  XSLoader::load('Imager::File::WEBP', $VERSION);
}

Imager->register_reader
  (
   type=>'webp',
   single => 
   sub { 
     my ($im, $io, %hsh) = @_;

     my $page = $hsh{page};
     defined $page or $page = 0;
     $im->{IMG} = i_readwebp($io, $page);

     unless ($im->{IMG}) {
       $im->_set_error(Imager->_error_as_msg);
       return;
     }

     return $im;
   },
   multiple =>
   sub {
     my ($io, %hsh) = @_;

     my @imgs = i_readwebp_multi($io);
     unless (@imgs) {
       Imager->_set_error(Imager->_error_as_msg);
       return;
     }

     return map bless({ IMG => $_, ERRSTR => undef }, "Imager"), @imgs;
   },
  );

Imager->register_writer
  (
   type=>'webp',
   single => 
   sub { 
     my ($im, $io, %hsh) = @_;

     $im->_set_opts(\%hsh, "i_", $im);
     $im->_set_opts(\%hsh, "webp_", $im);

     unless (i_writewebp($im->{IMG}, $io, $hsh{webp_config})) {
       $im->_set_error(Imager->_error_as_msg);
       return;
     }
     return $im;
   },
   multiple =>
   sub {
     my ($class, $io, $opts, @ims) = @_;

     Imager->_set_opts($opts, "webp_", @ims);

     my @work = map $_->{IMG}, @ims;
     my $result = i_writewebp_multi($io, $opts->{webp_config}, @work);
     unless ($result) {
       $class->_set_error($class->_error_as_msg);
       return;
     }

     return 1;
   },
  );

__END__

=head1 NAME

Imager::File::WEBP - read and write WEBP files

=head1 SYNOPSIS

  use Imager;

  my $img = Imager->new;
  $img->read(file=>"foo.webp")
    or die $img->errstr;

  # type won't be necessary if the extension is webp from Imager 1.008
  $img->write(file => "foo.webp", type => "webp")
    or die $img->errstr;

=head1 DESCRIPTION

Implements .webp file support for Imager.

Due to the limitations of C<webp> grayscale images are written as RGB
images.

=head1 TAGS

=over

=item *

C<webp_mode> - set when reading an image and used when writing.
Possible values:

=over

=item *

C<lossy> - write in lossy mode.  This is the default.

=item *

C<lossless> - write in lossless mode.

=back

=item *

C<webp_quality> - the lossy compression quality, a floating point
number from 0 (bad) to 100 (better).  Default: 80.

=back

If Imager::File::WEBP was built with Imager 1.010 then EXIF metadata
will also be read from the file.  See the description at
L<Imager::Files/JPEG>.

=head2 Animation tags

These only have meaning for files with more than one image.

Tags that can be set for the whole file, only the tag value from the
first image is used when writing:

=over

=item *

C<webp_loop_count> - the number of times to loop the animation.  When
writing an animation this is fetched only from the first image.  When
reading, the same file global value is set for every image read.
Default: 0.

=item *

C<webp_background> - the background color for the animation.  When
writing an animation this is fetched only from the first image.  When
reading, the same file global value is set for every image read.
Default: white.

=back

The following can be set separately for each image in the file:

=over

=item *

C<webp_left>, C<webp_top> - position of the frame within the animation
frame.  Only has meaning for multiple image files.  Odd numbers are
stored as the even number just below.  Default: 0.

=item *

C<webp_duration> - duration of the frame in milliseconds.  Default:
100.

=item *

C<webp_dispose> - the disposal method for the frame:

=over

=item *

C<background> - restore to the background before displaying the next
frame.

=item *

C<none> - leave the canvas as is when drawing the next frame.

=back

Default: C<background>.

=item *

C<webp_blend> - the blend method for the frame:

=over

=item *

C<alpha> - alpha combine the frame with canvas.

=item *

C<none> - replace the area under the image with the frame.

=back

If the frame has no alpha channel this option makes no difference.

Default: C<alpha>.

=back

=head2 More complex compression configuration

If you want more control over the work and parameters C<libwebp> uses
to compress your image, you can supply a several other tags, or
encapsulate those parameters in a configuration object.

At the simplest level you can just supply parameters to C<<
$image->write() >> or C<< Imager->write_multi() >>, which are then set
as tags:

  $im->write(file => "foo.webp", type => "webp", webp_target_size => 10_000);

You can also create a configuration object and supply that:

  my $cfg = Imager::File::WEBP::Config->new(webp_target_size => 10_000);
  $im->write(file => "foo.webp", type => "webp", webp_config => $cfg);

If you do supply a configuration object then any tags supplied are
used to modify a copy of the configuration object rather than creating
a new configuration for the image.  In particular this means that the
C<webp_preset> parameter/tag will be ignored if you supply
C<webp_config>.

You can also initialize the configuration object from an image:

  my $cfgim = Imager->new(xsize => 1, ysize => 1);
  $cfgim->settag(name => "webp_target_size", value => 10_000);
  my $cfg = Imager::File::WEBP::Config->new($cfgim);

Once you have a configuration object you can fetch or update its members:

  my $old_target_size = $cfg->target_size;
  $cfg->target_size(20_000);

Note that when called as a setter these methods return a success flag,
B<not> the old value.

Parameters only available when creating a new configuration object:

=over

=item *

C<webp_preset> - a string that can be any of "default", "picture",
"photo", "drawing", "icon" or "text".  This adjusts the default values
for C<sns_strength>, C<filter_sharpness>, C<filter_strength> and
C<preprocessing>.

=back

Any other value can be supplied as either an initialization parameter
(with the C<webp_> prefix, or modified or retrieved with an accessor
on the configuration object (without the C<webp_> prefix.

These are:

=over

=item *

C<webp_quality> - the quality of conversion, a floating point value
between 0 and 100 inclusive..  This is exactly the same as the simpler
C<webp_quality> parameter above.

=item *

C<webp_method> - quality/speed trade-off (0=fast, 6=slower-better)

=item *

C<webp_image_hint> - any of C<default>, C<picture>, C<photo>,
C<graph>.  This is unrelated to C<webp_preset> and it only used for
lossless compression at this point.  Only C<graph> appears to act any
differently at this point going by the source.

=item *

C<webp_target_size> - if non-zero, set the desired target size in
bytes.  Takes precedence over the C<webp_quality> parameter.

=item *

C<webp_target_psnr> - if non-zero, specifies the minimal distortion to
try to achieve. Takes precedence over C<webp_target_size>.

=item *

C<webp_segments> - maximum number of segments to use, in [1..4].

=item *

C<webp_sns_strength> - Spatial Noise Shaping. Integer 0=off, 100=maximum.

=item *

C<webp_filter_strength> - integer range: [0 = off .. 100 = strongest].

=item *

C<webp_filter_sharpness> - integer range: [0 = off .. 7 = least sharp].

=item *

C<webp_filter_type> - filtering type: integer 0 = simple, 1 = strong
(only used if filter_strength > 0 or autofilter > 0).

=item *

C<webp_autofilter> - Auto adjust filter's strength [0 = off, 1 = on].

=item *

C<webp_alpha_compression> - Algorithm for encoding the alpha plane (0
= none, 1 = compressed with WebP lossless). Default is 1.

=item *

C<webp_alpha_filtering> - Predictive filtering method for alpha plane.
0: none, 1: fast, 2: best. Default is 1.

=item *

C<webp_alpha_quality> Between 0 (smallest size) and 100
(lossless). Default is 100.

=item *

C<webp_pass> - number of entropy-analysis passes (in [1..10]).

=item *

C<webp_preprocessing> - preprocessing filter (0=none, 1=segment-smooth)

=item *

C<webp_partitions> - log2(number of token partitions) in [0..3].
Default is set to 0 for easier progressive decoding.

=item *

C<webp_partition_limit> - quality degradation allowed to fit the 512k limit on
prediction modes coding (0: no degradation, 100: maximum possible degradation).

=item *

C<webp_emulate_jpeg_size> - If true, compression parameters will be
remapped to better match the expected output size from JPEG
compression. Generally, the output size will be similar but the
degradation will be lower.  Requires encoder ABI version 0x200 or higher.

=item *

C<webp_thread_level> - If non-zero, try and use multi-threaded
encoding.  Requires encoder ABI version 0x201 or higher.

=item *

C<webp_low_memory> - If set, reduce memory usage (but increase CPU
use).  Requires encoder ABI version 0x201 or higher.

=item *

C<webp_near_lossless> - Near lossless encoding [0 = max loss .. 100 =
off (default)].  Requires encoder ABI version 0x205 or higher.

=item *

C<webp_exact> - if non-zero, preserve the exact RGB values under
transparent area. Otherwise, discard this invisible RGB information
for better compression. The default value is 0.  Must be 0 or 1.
Requires encoder ABI version 0x209.

=item *

C<webp_use_sharp_yuv> - if needed, use sharp (and slow) RGB->YUV
conversion.  Requires encoder ABI version 0x20e or higher.

=back

The above is largely from:

L<https://developers.google.com/speed/webp/docs/api#advanced_encoding_api>

with some typo fixes and adjustments.

=over

=item Imager::File::WEBP::encoder_abi_version() - returns the encoder ABI version.

=back

=head1 INSTALLATION

To install Imager::File::WEBP you need Imager installed and you need
libwebp 0.5.0 or later and the libwebpmux distributed with libwebp.

=head1 TODO

These aren't intended immediately, but are possible future
enhancements.

=head2 Compression level support for lossless images

The simple lossless API doesn't include a compression level parameter,
which complicates this.  It may not be worth doing anyway.

=head2 Parse EXIF metadata

To fix this I'd probably pull imexif.* out of Imager::File::JPEG and
make it part of the Imager API.

Maybe also add extended EXIF/Geotagging via libexif or Exiftool.

=head2 Error handling tests (and probably implementation)

I think this is largely done.

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=head1 SEE ALSO

Imager, Imager::Files.

=cut
