package Image::Imlib2;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
    TEXT_TO_RIGHT
    TEXT_TO_LEFT
    TEXT_TO_UP
    TEXT_TO_DOWN
    TEXT_TO_ANGLE
);
$VERSION = '2.03';

bootstrap Image::Imlib2 $VERSION;

Image::Imlib2->set_cache_size(0);

sub new_transparent {
    my ( $pkg, $x, $y ) = @_;
    my $pixel = pack( 'CCCC', 0, 0, 0, 0 );    # ARGB
    return Image::Imlib2->new_using_data( $x, $y, $pixel x ( $x * $y ) );
}

sub new_using_data {
    my ( $pkg, $x, $y, $data ) = @_;
    if ( defined $data && 4 * $x * $y == length $data ) {
        return $pkg->_new_using_data( $x, $y, $data );
    } else {
        return undef;
    }
}

sub autocrop {
    my $image = shift;
    my ( $x, $y, $w, $h ) = $image->autocrop_dimensions;
    return $image->crop( $x, $y, $w, $h );
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Image::Imlib2 - Interface to the Imlib2 image library

=head1 SYNOPSIS

  use Image::Imlib2;

  # create a new image
  my $image = Image::Imlib2->new(200, 200);

  # or load an image
  $image = Image::Imlib2->load("foo.png");

  # Enable the alpha channel support
  $image->has_alpha(1);

  # set a colour (rgba, so this is transparent orange)
  $image->set_color(255, 127, 0, 127);

  # draw a rectangle
  $image->draw_rectangle(50, 50, 50, 50);

  # draw a filled rectangle
  $image->fill_rectangle(150, 50, 50, 50);

  # draw a line
  $image->draw_line(0, 0, 200, 50);

  # set quality before saving
  $image->set_quality(50);

  # save out
  $image->save('out.png');

  # create a polygon
  my $poly = Image::Imlib2::Polygon->new();

  # add some points
  $poly->add_point(0, 0);
  $poly->add_point(100, 0);
  $poly->add_point(100, 100);
  $poly->add_point(0, 100);

  # fill the polygon
  $poly->fill();

  # draw it closed on image
  $image->draw_polygon($poly, 1);

  # create a color range
  my $cr = Image::Imlib2::ColorRange->new();

  # add a color
  my ($distance, $red, $green, $blue, $alpha) = (15, 200, 100, 50, 20);
  $cr->add_color($distance, $red, $green, $blue, $alpha);

  # draw it
  my($x, $y, $width, $height, $angle) = (20, 30, 200, 200, 1);
  $image->fill_color_range_rectangle($cr, $x, $y,
                                     $width, $height, $angle);

=head1 DESCRIPTION

B<Image::Imlib2> is a Perl port of Imlib2, a graphics library that
does image file loading and saving as well as manipulation, arbitrary
polygon support, etc. It does ALL of these operations FAST. It allows
you to create colour images using a large number of graphics
primitives, and output the images in a range of formats.

Image::Imlib2::Polygon and Image::Imlib2::ColorRange are described
following Image::Imlib2 but may be referenced before their
description.

Note that this is an early version of my attempt at a Perl interface
to Imlib2. Currently, the API is just to test things out. Not
everything is supported, but a great deal of functionality already
exists. If you think the API can be tweaked to be a bit more
intuitive, drop me a line!

Note that a development version of Imlib2 must be installed before
installing this module.

=head1 Exported constants

=head2 TEXT_TO_RIGHT

=head2 TEXT_TO_LEFT

=head2 TEXT_TO_UP

=head2 TEXT_TO_DOWN

=head2 TEXT_TO_ANGLE

To be used as the direction parameter for text functions that
accept it.

=head1 METHODS (Image::Imlib2)

=head2 new

This will create a new, blank image. If the dimensions aren't
specified, it will default to 256 x 256.

  my $image = Image::Imlib2->new(100, 100);

The contents of this image at creation time are undefined - they 
could be garbage memory. You should clear the image if necessary.

=head2 new_transparent

This will create a new fully-transparent image. If the dimensions
aren't specified, it will default to 256 x 256.

  my $image = Image::Imlib2->new_transparent(100, 100);

=head2 new_using_data

This will create a new image with the specified pixel data, which must
be a packed string. If the dimensions are not specified, it will
default to 256 x 256.

  my $pixel = pack('CCCC', 255, 127, 0, 255); # ARGB
  my $image = Image::Imlib2->new_using_data(100, 100, $pixel x (100*100));

=head2 load

This will load an existing graphics file and create a new image
object. It reads quite a few different image formats.

  my $image = Image::Imlib2->load("foo.png");

=head2 save

This saves the current image out. Currently this is in PNG if the
format has not been set using image_set_format().

  $image->save("out.png");

=head2 image_set_format (format)

This will set the image format for future save operations. format is a
string and may be "jpeg", "tiff", "png", etc. The exact number of
formats supported depends on how you built imlib2.

  $image->image_set_format("jpeg"); # Convert image to JPG

=head2 set_quality

This sets the quality of the saved picture - lower the quality to
get smaller filesizes.

  $image->set_quality(50);

=head2 set_color (r, g, b, a) or set_colour (r, g, b, a)

This sets the colour that the drawing primitives will use. You specify
the red, green, blue and alpha components, which should all range from
0 to 255. The alpha component specified how transparent the colour is:
0 is fully transparent (so drawing with it will be pointless), 127 is
half-transparent, and 255 is fully opaque. Many examples:

  $image->set_colour(255, 255, 255, 255); # white
  $image->set_colour(  0,   0,   0, 255); # black
  $image->set_colour(127, 127, 127, 255); # 50% gray
  $image->set_colour(255,   0,   0, 255); # red
  $image->set_colour(  0, 255,   0, 255); # green
  $image->set_colour(  0,   0, 255, 255); # blue
  $image->set_colour(255, 127,   0, 127); # transparent orange

Warning: this sets a global variable for the draw color.

=head2 draw_point (x, y)

This colours a point in the image in the currently-selected
colour. Note that the coordinate system used has (0, 0) at the top
left, with (50, 0) to the right of the top left, (0, 50) below the top
left, and (50, 50) to the bottom right of the top left.

  $image->draw_point(50, 50);

=head2 query_pixel (x, y)

This returns the colour of a pixel in the image. It returns the red,
green, blue and alpha components:

  my($r, $g, $b, $a) = $image->query_pixel(50,50);

=head2 draw_line (x1, y1, x2, y2)

This draws a line between two points in the currently-selected
colour. The following draws between the (0, 0) and (100, 100) points:

  $image->draw_line(0, 0, 100, 100);

=head2 draw_rectangle (x, y, w, h)

This draws a the outline of a rectangle with the top left point at (x,
y) and having width w and height h in the current colour.

  $image->draw_rectangle(0, 0, 50, 50);

=head2 fill_rectangle (x, y, w, h)

This draws a filled rectangle with the top left point at (x, y) and
having width w and height h in the current colour.

  $image->fill_rectangle(0, 0, 50, 50);

=head2 draw_ellipse (x, y, w, h)

This draws an ellipse which has center (x, y) and horizontal amplitude
of w and vertical amplitude of h in the current colour. Note that
setting w and h to the same value will draw a circle.

  $image->draw_ellipse(100, 100, 50, 50);

=head2 fill_ellipse (x, y, w, h)

This draws a filled ellipse which has center (x, y) and horizontal
amplitude of w and vertical amplitude of h in the current colour. Note
that setting w and h to the same value will draw a filled circle.

  $image->fill_ellipse(100, 100, 50, 50);

=head2 add_font_path (dir)

This function adds the directory path to the end of the current list
of directories to scan for truetype (TTF) fonts.

  $image->add_font_path("./ttfonts");

=head2 load_font (font)

This function will load a truetype font from the first directory in
the font path that contains that font. The font name format is
"font_name/size". For example. If there is a font file called cinema.ttf
somewhere in the font path you might use "cinema/20" to load a 20 pixel
sized font of cinema.

Note that this font will be used from now on, much like set_colour does
for colours.

  $image->load_font("cinema/20");

Warning: this sets a global variable for the current font.

=head2 get_text_size (text, direction, angle)

This function returns the width and height in pixels the text string
would use up if drawn with the current font.  direction and angle
are optional and deault to TEXT_TO_RIGHT and 0, respectively.

  my($w, $h) = $image->get_text_size("Imlib2 and Perl!");
  my($w1, $w2) = $image->get_text_size("Crazy text",
                                       TEXT_TO_UP, 1);

=head2 draw_text (x, y, text, direction, angle)

This draws the text using the current font and colour onto the image
at position (x, y).  direction and angle are optional and deault to
TEXT_TO_RIGHT and 0, respectively.

  $image->draw_text(50, 50, "Groovy, baby, yeah!");
  $image->draw_text(50, 50, "Sweet, baby, yeah!",
                    TEXT_TO_UP, 1.571);

=head2 autocrop

This creates a duplicate of the image which is automatically cropped
to remove the background colour from the outside of the image:

  my $cropped_image = $image->autocrop;

=head2 autocrop_dimensions

This returns the x, y, width and height rectangle in an image which
would hold the results of the autocrop method:

  my($x, $y, $w, $h) = $image->autocrop_dimensions;

=head2 crop (x, y, w, h)

This creates a duplicate of a x, y, width, height rectangle in the
current image and returns another image.

  my $cropped_image = $image->crop(0, 0, 50, 50);

=head2 blend (source_image, merge_alpha, sx, sy, sw, sh, dx, dy, dw, dh)

This will blend the source rectangle x, y, width, height from the
source_image onto the current image at the destination x, y location
scaled to the width and height specified. If merge_alpha is set to 1
it will also modify the destination image alpha channel, otherwise the
destination alpha channel is left untouched.

  $image->blend($cropped_image, 0, 0, 0, 50, 50, 200, 0, 50, 50);

=head2 blur (radius)

This will blur the image. A radius of 0 has no effect, 1 and above determine 
the blur matrix radius that determine how much to blur the image.

  $image->blur(1); 

=head2 sharpen (radius)

This sharpens the image. The radius affects how much to sharpen by.

  $image->sharpen(1); 
  
=head2 clone ()

This creates an exact duplicate of the current image.

  $cloned = $image->clone;   

=head2 draw_polygon (polygon, closed)

This will draw polygon (of type Imlib2::Image::Polygon) on the the image.
The the polygon is drawn closed is closed is 1 and open if closed is 0.

  $image->draw_polygon($poly, 1);

=head2 fill_color_range_rectangle(color_range, x, y, w, h, angle);

This uses the color range color_range to fille a rectangle with points
x, y, x+width, y+width.

  $image->fill_color_range_rectangle($cr, 10, 20, 100, 150, 0);

=head2 image_orientate (steps)

This will rotate the image by steps*90 degrees, so to rotate by 90 degrees
set to 1, for 180 degrees set to 2, etc.

  $image->image_orientate(1);                    # Rotate by 90 degrees.

=head2 create_rotated_image(radians)

Create a new image, rotated from the original by a number of radians.
For example, to rotate 45 degrees:

  my $rotated = $image->create_rotated_image(45 / 360 * 3.141519*2);

=head2 create_scaled_image (x, y)

Create a new image, scaled from the original to the dimensions given in x
and y. If x or y are 0, then retain the aspect ratio given in the other.

  $image2=$image->create_scaled_image(100,100);  # Scale to 100x100 pixels

=head2 create_transparent_image (alpha)

Create a new image, based upon the original but with a fixed alpha
value. This will create a transparent image that you can then blend
onto other images. Alpha ranges from 0 to 255:

  my $new = $image->create_transparent_image(64);

=head2 create_blended_image (percent)

Create a new image, which is percent% of source1 and (100-percent)% of
source2. This is used for fading bedtween two images. Percent ranges
from 0 to 100:

  my $new = $source1->create_blended_image($source2, 50);

=head2 flip_horizontal ()

This will flip/mirror the image horizontally.

  $image->flip_horizontal();

=head2 flip_vertical ()

This will flip/mirror the image vertically.

  $image->flip_vertical();

=head2 flip_diagonal ()

This will flip/mirror the current image diagonally (good for quick and dirty
90 degree rotations if used before to after a horizontal or vertical flip).

  $image->flip_diagonal();

=head2 has_alpha (BOOLEAN)

Queries and/or sets the alpha support flag for the image. Note that
alpha is on by default when you create an image:

   if ($image->has_alpha) {
      # do something requiring alpha support
   }
   # Enable the alpha channel
   $image->has_alpha(1);

=head2 set_cache_size (INT)

By default, Imlib2 will not cache any images loaded from disk.

If you set a cache size then Imlib2 will cache all loaded images (up 
to this size) and will use this cache to avoid loading images from disk.

Sets the size of the image cache. Reducing this value will cause the cache to
be emptied.  You can turn off caching all together by setting this to zero.

Even without a cache, as long as you have a reference to an image in memory
that image will be returned immediately without checking the disk.

  Image::Imlib2->set_cache_size(1024 * 1024);
  my $image = Image::Imlib2->load("foo.jpg"); # image loaded from disk
  ... later, somewhere else, after $image has gone away ...
  my $image = Image::Imlib2->load("foo.jpg"); # same image, even if changed on disk
  ... later, somewhere else, after $image has gone away ...
  Image::Imlib2->set_cache_size(0);
  my $image  = Image::Imlib2->load("foo.jpg"); # image loaded from disk  
  my $image2 = Image::Imlib2->load("foo.jpg"); # same image as before, not reloaded 

=head2 get_cache_size ()

Returns the maximum size of the Image cache.

=head2 set_changes_on_disk ()

Called on an Image::Imlib2 instance that you have loaded from disk, this
method tells imlib that it should take extra care when caching the image
for this filename.  Next time the load method is called for this image's
file name Imlib will  check the modification time for the file on disk
compared to the cached version and take appropriate action.

  my $image = Image::Imlib2->load("foo.jpg");
  $image->set_changes_on_disk();

  ...later...

  # reloads image from disk if mod time has changed (otherwise use cached)
  my $image = Image::Imlib2->load("foo.jpg"); 


Calling
this method on a loaded image tells Imlib2 to look at the disk and
compare mtimes with it's loaded copy - by default, this is not the case,
so even if a file changes on disk, it won't be re-loaded.

=head2 will_blend (BOOL)

Changes the setting for whether drawing blends with existing pixels in
the image or overwrites those pixels.  Defaults to true.  Returns the
new value.  If no argument is passed, just returns the current value.

Warning: this sets a global variable for blending.

=head2 find_colour

This returns the x and y coordinates for the first pixel of the
current colour it finds in the image. It returns undef if it doesn't
find the colour:

  # find a red pixel
  $i->set_colour(255, 0, 0, 255);
  my($rx, $ry) = $i->find_red;

=head2 fill

This flood fills the image, starting at the x and y coordinates and
filling every pixel under it with the current colour:

  $i->fill($x, $y);

=head1 METHODS (Image::Imlib2::Polygon)

=head2 new

This will create a new polygon for use with Image::Imlib2::draw_polygon.

  my $poly = Image::Imlib2::Polygon->new();

=head2 add_point (x, y)

Adds a point to the polygonal construct.

  $poly->add_point(10,10);

=head2 fill

Fills polygon in the current context.

  $poly->fill();

=head1 METHODS (Image::Imlib2::ColorRange)

=head2 new

Creates a new color range.

  my $cr = Image::Imlib2::ColorRange->new();

=head2 add_color (distance, red, green, blue, alpha)

Similar to set_colour, but adds the color to the color range at the
specified distance.

  $cr->add_color(10, 255, 127, 0, 66);

Warning: this sets a global variable for the draw color.

=head2 width

Returns the current width of the image.

  my $width = $image->width;

=head2 height

Returns the current height of the image.

  my $height = $image->height;

=head1 DEPRECATED METHOS

=head2 get_width

Returns the current width of the image. Use width() instead.

  my $width = $image->get_width;

=head2 get_height

Returns the current height of the image. Use height() instead.

  my $height = $image->get_height;

=head1 AUTHOR

Leon Brocard, acme@astray.com

=head1 COPYRIGHT

Copyright (c) 2000-9 Leon Brocard. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

