/*
 * Copyright (c) 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA  02110-1301  USA.
 */

#include "gtk2perl.h"

#if ! GTK_CHECK_VERSION (2, 22, 0)
/* plain fields before the accessor funcs
   of course the plain fields are better :-( */
#define gdk_image_get_bits_per_pixel(image)  ((image)->bits_per_pixel)
#define gdk_image_get_bytes_per_pixel(image) ((image)->bpp)
#define gdk_image_get_bytes_per_line(image)  ((image)->bpl)
#define gdk_image_get_byte_order(image)      ((image)->byte_order)
#define gdk_image_get_depth(image)           ((image)->depth)
#define gdk_image_get_height(image)          ((image)->height)
#define gdk_image_get_image_type(image)      ((image)->type)
#define gdk_image_get_visual(image)          ((image)->visual)
#define gdk_image_get_width(image)   	     ((image)->width)
#define gdk_image_get_pixels(image)  	     ((image)->mem)
#endif

MODULE = Gtk2::Gdk::Image	PACKAGE = Gtk2::Gdk::Image	PREFIX = gdk_image_

=for position DESCRIPTION

=head1 DESCRIPTION

A C<Gtk2::Gdk::Image> is a 2-D array of pixel values in client-side
memory.  It can optionally use shared memory with the X server for
fast copying to or from a window or pixmap.

If you're thinking of using this then look at C<Gtk2::Gdk::Pixbuf>
first.  GdkPixbuf has many more features, in particular file read and
write (PNG, JPEG, etc).  But a GdkImage lets you work directly in
pixel values instead of expanding to RGB components.

See L<Gtk2::Gdk::Drawable> for C<draw_image>, C<get_image> and
C<copy_to_image> methods to draw or fetch images to or from a window
or pixmap.

The various C<get> methods are Gtk 2.22 style.  For previous versions
they're direct field access.

=cut

GdkImage_noinc_ornull *
gdk_image_new (class, type, visual, width, height)
	GdkImageType  type
	GdkVisual    *visual
	gint	      width
	gint	      height
    C_ARGS:
	type, visual, width, height

# #ifndef GDK_DISABLE_DEPRECATED
## now called gdk_drawable_get_image(), for no discernible reason
# GdkImage*  gdk_image_get       (GdkDrawable  *drawable,
# 				gint	      x,
# 				gint	      y,
# 				gint	      width,
# 				gint	      height);
## not needed
# GdkImage * gdk_image_ref       (GdkImage     *image);
# void       gdk_image_unref     (GdkImage     *image);
# #endif /* GDK_DISABLE_DEPRECATED */

void
gdk_image_put_pixel (image, x, y, pixel)
	GdkImage     *image
	gint	      x
	gint	      y
	guint32	      pixel

guint32
gdk_image_get_pixel (image, x, y)
	GdkImage     *image
	gint	      x
	gint	      y

void
gdk_image_set_colormap (image, colormap)
	GdkImage    *image
        GdkColormap *colormap

GdkColormap*
gdk_image_get_colormap (image)
	GdkImage    *image


## This looks like a perfectly good function, and a good way to get
## bitmap or whatever data into an image.  It seems to be declared
## "broken" because it happens to have used malloc() instead of
## g_malloc(), and/or takes over the block of memory it was handed,
## which are pretty minor matters really ... :-(

#ifdef GDK_ENABLE_BROKEN

## Untested, probably should look at the visual bytes-per-whatever for
## the SV length check.
##
## =for arg data (string)
## =cut
## GdkImage_noinc *
## gdk_image_new_bitmap (class, visual, data, width, height)
## 	GdkVisual     *visual
## 	SV            *data
## 	gint          width
## 	gint          height
## PREINIT:
## 	char *malloced_data, *data_ptr;
## 	size_t want_len;
## 	STRLEN data_len;
## CODE:
## 	want_len = (height * (int) ((width + 7) / 8));
## 	data_ptr = SvPVbyte (data, data_len);
## 	if (data_len != want_len) {
## 		croak ("Bitmap data length %u should be %u",
## 		       data_len, want_len);
## 	}
## 	malloced_data = malloc (want_len);
## 	if (malloced_data == NULL) {
## 		croak ("Cannot malloc memory");
## 	}
## 	RETVAL = gdk_image_new_bitmap (visual, data, width, height);

#endif /* GDK_ENABLE_BROKEN */

## not needed
# #ifndef GDK_DISABLE_DEPRECATED
# #define gdk_image_destroy              g_object_unref
# #endif /* GDK_DISABLE_DEPRECATED */


##-----------------------------------------------------------------------------
## Field accessors

GdkImageType
gdk_image_get_image_type (image)
	GdkImage *image

GdkVisual *
gdk_image_get_visual (image)
	GdkImage *image

GdkByteOrder
gdk_image_get_byte_order (image)
	GdkImage *image

gint
gdk_image_get_bytes_per_pixel (image)
	GdkImage *image
    ALIAS:
	get_bytes_per_line = 1
	get_bits_per_pixel = 2
	get_depth          = 3
	get_width          = 4
	get_height         = 5
    CODE:
	/* the guint16 fields expand to gint for RETVAL */
	switch (ix) {
	case 0:  RETVAL = gdk_image_get_bytes_per_pixel(image); break;
	case 1:  RETVAL = gdk_image_get_bytes_per_line(image);  break;
	case 2:  RETVAL = gdk_image_get_bits_per_pixel(image);  break;
	case 3:  RETVAL = gdk_image_get_depth(image);           break;
	case 4:  RETVAL = gdk_image_get_width(image);           break;
	default: /* case 5 */
		 RETVAL = gdk_image_get_height(image);          break;
	}
    OUTPUT:
	RETVAL

=for signature string = $image->get_pixels()
=for apidoc
Return a copy of the raw pixel data memory from C<$image>.  This is
C<bytes_per_line * height> many bytes.
=cut
## This is a copy similar to the way C<Gtk2::Gdk::Pixbuf> C<get_pixels>
## copies.  Perhaps in the future some sort of C<get_pixels_substr> could
## get just part of it, or C<put_bytes> or 4-arg substr write to part of it,
## as an alternative to individual C<get_pixel> / C<put_pixel>.
##
## A magic sv which could be read and written to modify the image data
## might be cute, but is probably more trouble than its worth.  substr
## fetch/store funcs would make it clearer what's being done.
##
## If a magic scalar held a reference then there's a gremlin in Perl
## 5.10 lvalue C<substr> where such an sv gets kept alive in the
## function scratchpad, risking the underlying GdkImage kept alive
## longer than it should be.  Or if it didn't hold a reference you'd
## have to rely on the application to keep the GdkImage alive while
## the raw memory was being manipulated.
##
SV *
gdk_image_get_pixels (image)
	GdkImage *image
    CODE:
        /* Crib note: memory block size is "bytes_per_line * height" per the
           shmget() or malloc() in _gdk_image_new_for_depth() of
           gdkimage-x11.c */
	RETVAL = newSVpv ((char *) image->mem, image->bpl * image->height);
    OUTPUT:
	RETVAL
