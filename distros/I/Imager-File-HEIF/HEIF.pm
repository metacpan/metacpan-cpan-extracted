package Imager::File::HEIF;
use strict;
use Imager;
use vars qw($VERSION @ISA);

BEGIN {
  $VERSION = "0.005";

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

Imager::File::HEIF requires at least version 1.9.0 of C<libheif>, but
in general you want the very latest version you can get.
Imager::File::HEIF has been tested up to version 1.17.3 of C<libheif>.

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

=head1 RESOURCE USAGE

HEIF processing is fairly resource intensive, and libheif uses
multiple decoding threads by default when you read a HEIF image.

With C<libheif> 1.13.0 or later you can set
C<$Imager::File::HEIF::MaxThreads> to the maximum number of threads to
use.  If this is negative or not defined the default is used, which is
defined by C<libheif>.

=head1 TODO

=over

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

https://github.com/strukturag/libheif

https://github.com/strukturag/libde265 - x265 decoder

https://www.x265.org/ - x265 encoder

=cut
