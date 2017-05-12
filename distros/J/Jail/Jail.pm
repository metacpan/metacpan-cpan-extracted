package Jail;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw(
	     EDGE_NOPAD EDGE_PADSRC EDGE_PADDST EDGE_WRAP EDGE_REFLECT
	     RT_NEARNB RT_BILINEAR RT_BIBUBIC RT_MINIFY
);

$VERSION = '0.8';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
                croak "Your vendor has not defined qw macro $constname";
        }
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Jail $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Jail - SGIPerl extension for grabbing video, modifying images and display images

=head1 SYNOPSIS

C<use Jail;>

C<$font = openBDF Font ("helvetica50.bdf");>
C<if ($font-E<gt>getStatus) {>
C<    print $font-E<gt>getErrorString() . "\n";>
C<    exit(1);>
C<}>

C<$dateStr = localtime(time);>
C<$glArray = $font-E<gt>C<getText("$dateStr",$count)>;>
C<$glyph   = merge Glyph ($glArray, $count);>

C<$glyph-E<gt>setForeground(255,255,255,0);>

C<$jg = new JailGlyph();>
C<$jg-E<gt>addGlyph($glyph);>
C<if ($jg-E<gt>getStatus()) {>
C<    print $jg-E<gt>getErrorString() . "\n";>
C<    exit(1);>
C<}>

C<$imgStream = new JailArray();>
C<if (!$imgStream-E<gt>getVideoStream(2)) {>
C<    $imgStream-E<gt>printError();>
C<    exit(1);>
C<}>

C<$image = $imgStream-E<gt>pop();>

C<$wi = $image-E<gt>getWidth();>
C<$hi = $image-E<gt>getHeight();>
C<$wg = $jg-E<gt>getWidth();>
C<$hg = $jg-E<gt>getHeight();>

C<if (!$jg-E<gt>blittInImage($image, $wi - $wg, $hi - $hg)) {>
C<    print "BLITT1: ";>
C<    print $jg-E<gt>getErrorString() . "\n";>
C<    print $image-E<gt>getErrorString() . "\n";>
C<    exit(1);>
C<}
C<$image-E<gt>blur(180,5,5);>
C<$image-E<gt>rotateZoom(45, 0.6, 0.6);>
C<
C<if (!$image-E<gt>save("/tmp/jail_2.sgi","SGI")) {>
C<    $image-E<gt>printError();>
C<    exit(1);>
C<}

C<$image = $imgStream-E<gt>pop();>
C<$image-E<gt>sharp(2.5);>
C<$wi = $image-E<gt>getWidth();>
C<$hi = $image-E<gt>getHeight();>

C<if (!$jg-E<gt>blittInImage($image, $wi - $wg, $hi - $hg)) {>
C<    print "BLITT2: ";>
C<    print $jg-E<gt>getErrorString() . "\n";>
C<    print $image-E<gt>getErrorString() . "\n";>
C<    exit(1);>
C<}
C<if (!$image-E<gt>save("/tmp/jail_1.gif","GIF")) {>
C<    $image-E<gt>printError();>
C<    exit(1);>
C<}>

=head1 DESCRIPTION

  Jail - Just an_other Image Library

  This extension is running _only_ on SGI IRIX systems. You need the 
  Image Vision Library, Video Library and STL.
  You need a X11 Display _only_ if you want to display an image.

  The newest version you can get under http://www.artcom.net/~karo/Jail/.
  You can get there also a precompiled version.

=head1 CLASS INTERFACE

A 'better' documentation are may be the examples.

=head1 Exported functions and flags

 The package C<Jail> exports the following functions 

=head2 Jail Object

=over 2

=cut 

=item new Jail(...)

=item load(filename)

Load an existing image. The method guesses the right file type.

=item save(filename, imgFormat)

Save this image with a given filename. The imgFormat is one of the supported
file formats from the I<Image Vision Library>. Have a look under
C<File Formats> or execute the I<imgformats> command.

=item saveFile(filehandle, imgFormat)

Save this image to a already opened filehandle. For the imgFormat see above.
This function works only for the B<GIF> format. The I<IL> seeks during saving
on the filedescriptor, I try to get the I<IL> output over a pipe. That does
not work. YET

=item getWidth()

Returns the width of the image in pixels.

=item getHeight()

Returns the height of the image in pixels.

=item getChannels()

Returns for the image the amount of channels.

=item getImageFormatName()

This method is usefull if you have loaded an image. So you can get
the file format for that image.

=item copyTile(destX, destY, width, height, srcImage, srcX, srcY)

Copy a tile from C<srcImage> with the given coord. to this image.

=item add(addImg, [bias])

Add a image logical to this image.

=item setPixel(x,y, r,g,b,[a])

Set a pixel with the given color

=item duplicate()

Get a copy of this image.

=item getVideoSnapshot()

Get a image from the default video input.
See also videoin(1) and videopanel(1).

=item rotateZoom(angle, zoomX, zoomY, [resample])

Rotate this image with a given angle. And/Or zoom this image.
 0 <= angle < 360
 0.0 < zoomFactor <= 1.0
See also ilRotZoomImg(3)

=item blur(blur, width, height, [bias], [edgeMode])

This method blurs an image by convolving it with a 2D gaussian kernel.
Parameter: 
  blur         : the degree of blur
  width,height : the kernel size

See also ilGBlurImg(3)

=item sharp(sharpness, [radius], [edgeMode])

This method sharpens the source image, by convolving it with a special
sharpening kernel.  The size of the kernel and the degree of sharpness
can be controlled by the radius and sharpness parameters.

See also ilSharpenImg(3)

=item compass(angle, [bias], [kernSize], [edgeMode])

This method performs a directional gradient transform of the image. This is 
similar to doing a first derivative operation in the direction of the gradient.
Given a direction, a square kernel is generated and then the source image is
convolved with this kernel.  A kernel size and additive bias can be supplied.

See also ilCompassImg(3)

=item laplace([bias], [edgeMode], [kern])

This method performs a 2D convolution on an image using one of two
predefined 3x3 Laplacian kernels. The resulting image is edge-enhanced.

kern := 1 | 2

See also ilLaplaceImg(3)

=item edgeDetection([biasVal], [edgeMode])

This method performs two orthogonal 2D convolutions on an image using
two predefined 2x2 Roberts kernels. The resulting image is edge enhanced.

See also ilRobertsImg(3)

=item blendImg(doImg, alphaValue | alphaImg,[compose])

This method takes an other image which will be blend into this image. 
If you specify the alphaValue indicate thatthe alpha values are to be taken
from the alpha channel of the foreground and background images. The alpha 
pixels are normalized to the range (0.0-1.0), based on the minimum and maximum
pixel values of the foreground and background images.
If you specify an alphaImg the first channel of that is interpreted as alpha
channel for the blending.

See also ilBlendImg(3)

=item display()

This displays the image in a window.. damn this is totaly buggy

=item printError()

=item getStatus()

Normaly the return value is 0. Otherwise an error occured.

=item getErrorString()

=back

=head2 JailArray Object

=over 2

=item new JailArray

=item size()

Returns the amount of images.

=item push(Jail)

Push an image to the end of the array.

=item Jail pop()

Pops and returns the last image in the array.

=item Jail shift()

Shifts the first image of the array off and returns it.

=item unshift(Jail)

Prepends an other image to the front of the array.

=item loadIndexed(prefix,startSuffix,suffix,amount)

Loads images with a given prefix, an additional number and a given suffix.
For Example: 
  prefix:      blub
  startSuffix: 23
  suffix:      .gif
  amount:      3

  So the method would load 3 images: blub23.gif, blub24.gif and blub25.gif

=item saveIndexed(prefix,startSuffix,suffix)

Saves images with the same name convention as loadIndexed.

=item getVideoStream(amount)

Get a videostream of C<amount> images.

=item printError()

=item getStatus()

=item getErrorString()

=back

=head2 Font Object

=over 2

=item openBDF(filename)

This static factory method loads a BDF font with the given filename and 
returns a Font Object. BDF stands for Glyph Bitmap Distribution Format. 
See: http://www.adobe.com/supportservice/devrelations/typeforum/ftypes.html
You can get BDF fonts from the X source or get them from your X server, have
a look: fstobdf(1), xfontsel(1)

=item getText(text, countVar)

This methods builds a GlyphArray Object from a given text. In the countVar
Variable will be the amount of found Glyphs returned.

=item getCharsetEncoding()

Returns the encoding value for the font.

=item getName()

Returns the name.

=item getStatus()

=item getErrorString()

=back

=head2 Glyph Object

=over 2

=item merge(GlyphArray, count)

This static factory method returns a new Glyph Object which is build from
the given GlyphArray.

=item setName(name)

You set the Name for the Glyph object.

=item getName()

=item getEncoding()

Get the char encoding for the Glyph. For a C<merge>d Glyph it is always 0.

=item getBBXW()

Get the width of the Bounding Box.

=item getBBXH()

Get the height of the Bounding Box.

=item getBBXXO()

Get the X coord. of the virtual point Zero of the BBX.

=item getBBXYO()

Get the Y coord. of the virtual point Zero of the BBX.

=item setForeground(r,g,b,[a])

Select a color for the foreground of the Glyph. Every '1' in the Glyph will
be treated as foreground.If you select for 'a' color a 255, the foreground will
not be painted.

=item setBackground(r,g,b,[a])

Select a color for the background of the Glyph. Every '0' in the Glyph will
be treated as background.If you select for 'a' color a 255, the background will
not be painted.

=item getForegroundR()

=item getForegroundG()

=item getForegroundB()

=item getForegroundA()

=item getBackgroundR()

=item getBackgroundG()

=item getBackgroundB()

=item getBackgroundA()

=item print()

This is for debuging. This prints the glyph in ascii.

=back

=head2 GlyphArray Object

=head2 JailGlyph Object

=over 2

=item new JailGlyph()

=item addGlyph(glyph)

This method collects Glyph objects.

=item createImg()

This method returns a Jail object. The returned object depends on the added
Glyphs.

=item blittInImage(img, x, y)

This method expect a Jail object and a x and y coord. The added Glyphs will be
rendered in the given Jail image. 

=item getWidth()

This returns the witdh, for that the JailGlyph will create a Imgage. Thats the
same as:
    $jailObj = $JailglyphObj->createImg();
 -->>   $jailObj->getWidth();

=item getHeight()

=item getCurX()

Get the X coord of the virtual point zero.

=item getCurY()

=item printError()

=item getStatus()

=item getErrorString()

=back

=head2 Special Parameter

=over 2

=item bias

In general, bias is a constant value added to each pixel luminance value to 
make it scale correctly. If, for example, the raw pixel luminance covers 
values between 100 and 200, some operators are able to scale the luminance 
values over the entire depth of pixel luminance values, for example, 0 - 255. 
When you scale the luminance values in this way, you need a bias value that 
adjusts the initial, raw luminance value, 100, in this example, to zero. 

=item edgeMode

Specifies how the neighborhood is defined for pixels at the edge of the image.
Have look at the EDGE_* Flags.

=item resample

Determining the procedure used by IL to alter the geometric aspects of an image
Have a look under Flags RT_*

=item kernSize

SGI Docs:
The kernel is the group or neighborhood of pixels used in calculations to 
sharpen or blur an image. Generally, the larger the kernel radius, the more 
pronounced the effect of either sharpening or blurring the image using the 
Enhance subpanel. However, using a larger kernel radius also results in a 
more time-consuming process.

=item compose

arg, thats heavy to explain shortly please have look at ilBlendImg(3) and in
/usr/include/il/ilTypes.h

=back

=head2 Flags

=over 2

=item EDGE_NOPAD

No padding is done, and the output image shrinks by the size of the kernel 
minus one in each dimension.

=item EDGE_PADSRC

The edge of the input image is padded with the input images fill value so that a full-sized output image can be processed.

=item EDGE_PADDST

Similar to ilNoPad, except that the output, images border is sufficiently 
padded with its fill value so that the final image is the same size as the 
source image.

=item EDGE_WRAP

Sufficient data is taken from the opposite edge of the source image so that a 
full-sized output image can be processed. 

=item EDGE_REFLECT

Sufficient data near the edge of the image is reflected so that a full-sized 
output image can be processed without producing artifacts at the image edge. 
This mode gives the best results for most operators.

=item RT_NEARNB

Nearest, standing for Nearest Neighbor, works quickly but
produces lower-quality results.

=item RT_BILINEAR

Bilinear uses more complex, time-consuming methods than
Nearest Neighbor, but produces higher-quality results. 

=item RT_BIBUBIC

Bicubic is more time-consuming than either Nearest Neighbor
or Bilinear, but produces the best results. 

If you choose the Bicubic resampling method, you can also choose the
specific Bicubic Family, each of which produces a somewhat different
effect: B-Spline, which is the default option, produces smoother images.
Catmul produces more sharpening. Mitchell results in an effect between
that of the other two.

=item RT_MINIFY

The Minify method produces the best results if you are
reducing the magnification of an image. Again, however, it is a
more time-consuming process.

=back

=head2 Image Formats

See also imgformats(1)

=over 4

=item PNG

PNG implements the PNG file format using version 0.88 of the Portable Network 
Graphics library, libpng, and version 1.0 of the ZIP deflate/inflate
compression library, libzlib.

=item GIF

The GIF file format is used to read image files stored in the CompuServe 
Graphics Image File (GIF) format. GIF does not support paging. It stores images
in palette-color-compressed using the Lempel-Ziv & Welch algorithmThe 
compression algorithm has become the focus of patent infringement litigation 
which has inspired the creation of a new image format to replace GIF. This new
format is the Portable Network Graphics (PNG) image format. It is also 
supported by Jail.

=item RGB

=item SGI

SGI is the first format defined by Silicon Graphics for storing image data. SGI
files are typically stored in files suffixed by .bw, .rgb, .rgba, .sgi, or 
.screen. SGI files support full color, color palette, and monochrome images of
either one or two bytes per color component. Image data can be stored in either
raw form or run-length encoding (RLE) compression. You can create SGI files 
with RLE compression but you cannot later rewrite a portion of a compressed
SGI file.

=item TIFF

The TIFF file format, created by Aldus Corporation, is an extended version of
the Tag Image File Format, using version 3.4beta24 of Sam Lefflers TIFF 
library, libtiff. This library implements version 6.0 of the TIFF 
specification. 

=item JFIF

JFIF implements the JPEG file format using the JPEG library, libjpeg, made available by the Independent JPEG Group. In addition to providing the IFL
image I/O abstraction, the entire JPEG library is provided as is for use by software that has been developed for use with libjpeg.

=item PPM

PPM, PGM, and PBM implement the PPM, PGM, and PBM file formats using release 7,
December 1993 of the NETPBM libraries, libppm, libpgm, and libpbm.

=item Alias

The Alias file format supports both variations of the format: 8-bit RGB  and 
8-bit matte.

=item SOFTIMAGE

The SOFTIMAGE file format supports reading all types of image files and writes 
only mixed RLE compressed. There is no current support for depth buffer
files or rendered subregions.

=item YUV

The YUV file format is the standard 8-bit 4:2:2 (YUV) format used by the 
Sirius board and almost all digital disk recorders ( Abekas, Accom etc ).

=item PCD

The PCD file format supports image files produced by the Kodak Photo CD system.
Photo CD establishes a system for storing high-resolution, digital photographic
images on compact discs.

=item PCDO

Every Kodak Photo CD contains a file in the Kodak Photo CD Overview Pac format.
This format contains a low resolution representation of each image on the Photo
CD.

=item FIT

=back

=head2 Todo

=over 4

=item search for memory leaks

There is a small memory leak somewhere in the save routine. Do not know if
it is in my or in the SGI IL routines.

=item thrash hold

add a thrash hold operator

=item more filter

=item 24->8 Bit dithering

=item add some primitive geometry painting

=item Display

The display object is _VERY_ buggy and not finished yet.

=item Jail::saveFile() can only save GIF\'s and JPG\'s

Thats a SGI IFL Bug.

=item GIF -> GIF improvement

The Problem is the IL core dumpes if I am trying to copy a GIF. So i have
to convert GIF->RGB->GIF.

=item documentation

Write a better documentation

=back

=head1 BUGS

  Oh, yes there are some. Especially in the display routine.
  Please, please, please, send me a short note if you found a bug.

=head1 AUTHOR

  This module has been written by Benjamin Pannier (B<karo@artcom.net>).

=head1 SEE ALSO

http://www.artcom.net/~karo/Jail/
perl(1), il(3), ifl(3), vl(3)

=cut
