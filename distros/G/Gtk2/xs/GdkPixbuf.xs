/*
 * Copyright (c) 2003-2008, 2010-2013 by the gtk2-perl team (see the file
 * AUTHORS)
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
 *
 * $Id$
 */

#define GDK_PIXBUF_ENABLE_BACKEND 1 /* for gdk_pixbuf_set_option() prototype */
#include "gtk2perl.h"

/* for backwards-compatibility: */
#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif

static void
gtk2perl_pixbuf_destroy_notify (guchar * pixels,
                                gpointer data)
{
	PERL_UNUSED_VAR (data);
	Safefree (pixels);
}

#if GTK_CHECK_VERSION (2, 2, 0)

SV *
newSVGdkPixbufFormat (GdkPixbufFormat * format)
{
	gchar * s;
	gchar ** strv;
	int j;
	AV * av;
	HV * stash, * hv = newHV ();

	s = gdk_pixbuf_format_get_name (format);
	gperl_hv_take_sv_s (hv, "name", newSVGChar (s));
	g_free (s);

	s = gdk_pixbuf_format_get_description (format);
	gperl_hv_take_sv_s (hv, "description", newSVGChar (s));
	g_free (s);

	strv = gdk_pixbuf_format_get_mime_types (format);
	av = newAV ();
	for (j = 0 ; strv && strv[j] ; j++)
		av_store (av, j, newSVGChar (strv[j]));
	gperl_hv_take_sv_s (hv, "mime_types", newRV_noinc ((SV*) av));
	g_strfreev (strv);

	strv = gdk_pixbuf_format_get_extensions (format);
	av = newAV ();
	for (j = 0 ; strv && strv[j] ; j++)
		av_store (av, j, newSVGChar (strv[j]));
	gperl_hv_take_sv_s (hv, "extensions", newRV_noinc ((SV*) av));
	g_strfreev (strv);

	gperl_hv_take_sv_s (hv, "is_writable",
			    newSVuv (gdk_pixbuf_format_is_writable (format)));

#if GTK_CHECK_VERSION (2,6,0)
{
	gboolean b;

	b = gdk_pixbuf_format_is_scalable (format);
	gperl_hv_take_sv_s (hv, "is_scalable", newSVuv (b));

	b = gdk_pixbuf_format_is_disabled (format);
	gperl_hv_take_sv_s (hv, "is_disabled", newSVuv (b));

	s = gdk_pixbuf_format_get_license (format);
	gperl_hv_take_sv_s (hv, "license", newSVGChar (s));
	g_free (s);
}
#endif

	/* Store the original format pointer in the hash so that
	   SvGdkPixbufFormat can retrieve and return it. */
	_gperl_attach_mg ((SV*) hv, format);

	stash = gv_stashpv ("Gtk2::Gdk::PixbufFormat", TRUE);
	return sv_bless ((SV*) newRV_noinc ((SV*) hv), stash);
}

GdkPixbufFormat *
SvGdkPixbufFormat (SV * sv)
{
	MAGIC *mg;

	if (!gperl_sv_is_defined (sv) || !SvROK (sv)
	    || !(mg = _gperl_find_mg (SvRV (sv))))
		return NULL;

	return (GdkPixbufFormat *) mg->mg_ptr;
}

#endif /* 2.2.0 */


#if GTK_CHECK_VERSION(2, 4, 0)

static gboolean
save_to_sv_callback (const gchar * data,
                     gsize count,
                     GError ** error,
                     gpointer user_data)
{
        SV * sv = user_data;

        sv_catpvn_nomg (sv, data, count);
        /* XXX no way to find out if that failed. */
	PERL_UNUSED_VAR (error);

        return TRUE;
}

#endif /* 2.4.0 */


MODULE = Gtk2::Gdk::Pixbuf	PACKAGE = Gtk2::Gdk::Pixbuf	PREFIX = gdk_pixbuf_

=for enum GdkPixbufError
=cut

=for enum GdkPixbufAlphaMode
=cut

=for enum GdkColorspace
=cut

 ## void gdk_pixbuf_render_threshold_alpha (GdkPixbuf * pixbuf, GdkBitmap * bitmap, int src_x, int src_y, int dest_x, int dest_y, int width, int height, int alpha_threshold);
void
gdk_pixbuf_render_threshold_alpha (pixbuf, bitmap, src_x, src_y, dest_x, dest_y, width, height, alpha_threshold)
	GdkPixbuf * pixbuf
	GdkBitmap * bitmap
	int src_x
	int src_y
	int dest_x
	int dest_y
	int width
	int height
	int alpha_threshold

 ## void gdk_pixbuf_render_to_drawable (GdkPixbuf *pixbuf, GdkDrawable *drawable, GdkGC *gc, int src_x, int src_y, int dest_x, int dest_y, int width, int height, GdkRgbDither dither, int x_dither, int y_dither)
void
gdk_pixbuf_render_to_drawable (pixbuf, drawable, gc, src_x, src_y, dest_x, dest_y, width, height, dither, x_dither, y_dither)
	GdkPixbuf *pixbuf
	GdkDrawable *drawable
	GdkGC *gc
	int src_x
	int src_y
	int dest_x
	int dest_y
	int width
	int height
	GdkRgbDither dither
	int x_dither
	int y_dither

 ## void gdk_pixbuf_render_to_drawable_alpha (GdkPixbuf *pixbuf, GdkDrawable *drawable, int src_x, int src_y, int dest_x, int dest_y, int width, int height, GdkPixbufAlphaMode alpha_mode, int alpha_threshold, GdkRgbDither dither, int x_dither, int y_dither)
void
gdk_pixbuf_render_to_drawable_alpha (pixbuf, drawable, src_x, src_y, dest_x, dest_y, width, height, alpha_mode, alpha_threshold, dither, x_dither, y_dither)
	GdkPixbuf *pixbuf
	GdkDrawable *drawable
	int src_x
	int src_y
	int dest_x
	int dest_y
	int width
	int height
	GdkPixbufAlphaMode alpha_mode
	int alpha_threshold
	GdkRgbDither dither
	int x_dither
	int y_dither

=for apidoc
=for signature pixmap = $pixbuf->render_pixmap_and_mask_for_colormap ($colormap, $alpha_threshold)
=for signature (pixmap, mask) = $pixbuf->render_pixmap_and_mask_for_colormap ($colormap, $alpha_threshold)
=cut
void
gdk_pixbuf_render_pixmap_and_mask_for_colormap (pixbuf, colormap, alpha_threshold)
	GdkPixbuf *pixbuf
	GdkColormap *colormap
	int alpha_threshold
        PPCODE:
{
        GdkPixmap *pm;
        GdkBitmap *bm;

        gdk_pixbuf_render_pixmap_and_mask_for_colormap (pixbuf, colormap, &pm, GIMME_V == G_ARRAY ? &bm : 0, alpha_threshold);
        XPUSHs (sv_2mortal (newSVGdkPixmap_noinc (pm)));
        if (GIMME_V == G_ARRAY)
                XPUSHs (sv_2mortal (newSVGdkBitmap_noinc (bm)));
}


=for apidoc
=for signature pixmap = $pixbuf->render_pixmap_and_mask ($alpha_threshold)
=for signature (pixmap, mask) = $pixbuf->render_pixmap_and_mask ($alpha_threshold)
=cut
void
gdk_pixbuf_render_pixmap_and_mask (pixbuf, alpha_threshold)
	GdkPixbuf *pixbuf
	int alpha_threshold
        PPCODE:
{
        GdkPixmap *pm;
        GdkBitmap *bm;

        gdk_pixbuf_render_pixmap_and_mask (pixbuf, &pm, GIMME_V == G_ARRAY ? &bm : 0, alpha_threshold);
        XPUSHs (sv_2mortal (newSVGdkPixmap_noinc (pm)));
        if (GIMME_V == G_ARRAY)
                XPUSHs (sv_2mortal (newSVGdkBitmap_noinc (bm)));
}

=for apidoc get_from_image
=for signature pixbuf = Gtk2::Gdk::Pixbuf->get_from_image ($src, $cmap, $src_x, $src_y, $dest_x, $dest_y, $width, $height)
=for signature pixbuf = $pixbuf->get_from_image ($src, $cmap, $src_x, $src_y, $dest_x, $dest_y, $width, $height)
=for arg src (GdkImage)
Fetch pixels from a Gtk2::Gdk::Image as a Gtk2::Gdk::Pixbuf.
Returns a new Gtk2::Gdk::Pixbuf if you use the class form, or I<$pixbuf> if
you call it on an existing pixbuf.
=cut

=for apidoc
=for signature pixbuf = Gtk2::Gdk::Pixbuf->get_from_drawable ($src, $cmap, $src_x, $src_y, $dest_x, $dest_y, $width, $height)
=for signature pixbuf = $pixbuf->get_from_drawable ($src, $cmap, $src_x, $src_y, $dest_x, $dest_y, $width, $height)
=for arg src (GdkDrawable)
Fetch pixels from a Gtk2::Gdk::Drawable as a Gtk2::Gdk::Pixbuf.
Returns a new Gtk2::Gdk::Pixbuf if you use the class form, or I<$pixbuf> if
you call it on an existing pixbuf.
=cut
 ## GdkPixbuf *gdk_pixbuf_get_from_drawable (GdkPixbuf *dest, GdkDrawable *src, GdkColormap *cmap, int src_x, int src_y, int dest_x, int dest_y, int width, int height);
SV *
gdk_pixbuf_get_from_drawable (dest_or_class, src, cmap, src_x, src_y, dest_x, dest_y, width, height)
	SV * dest_or_class
	SV * src
	GdkColormap_ornull *cmap
	int src_x
	int src_y
	int dest_x
	int dest_y
	int width
	int height
    ALIAS:
	get_from_image = 1
    PREINIT:
	GdkPixbuf * pixbuf, * dest;
    CODE:
	dest = (gperl_sv_is_defined (dest_or_class) && SvROK (dest_or_class))
	     ? SvGdkPixbuf (dest_or_class)
	     : NULL;
	if (ix == 1)
		pixbuf = gdk_pixbuf_get_from_image (dest,
		                                    SvGdkImage (src),
		                                    cmap, src_x, src_y,
		                                    dest_x, dest_y,
		                                    width, height);
	else
		pixbuf = gdk_pixbuf_get_from_drawable (dest,
		                                       SvGdkDrawable (src),
		                                       cmap, src_x, src_y,
		                                       dest_x, dest_y,
		                                       width, height);
	if (!pixbuf)
		XSRETURN_UNDEF;
	/* we own the output pixbuf if there was no destination supplied. */
	RETVAL = gperl_new_object (G_OBJECT (pixbuf), dest != pixbuf);
    OUTPUT:
	RETVAL



##  GQuark gdk_pixbuf_error_quark (void) G_GNUC_CONST 

### handled by Glib::Object
##  GdkPixbuf *gdk_pixbuf_ref (GdkPixbuf *pixbuf) 
##  void gdk_pixbuf_unref (GdkPixbuf *pixbuf) 

##  GdkColorspace gdk_pixbuf_get_colorspace (const GdkPixbuf *pixbuf) 
GdkColorspace
gdk_pixbuf_get_colorspace (pixbuf)
	GdkPixbuf *pixbuf

##  int gdk_pixbuf_get_n_channels (const GdkPixbuf *pixbuf) 
int
gdk_pixbuf_get_n_channels (pixbuf)
	GdkPixbuf *pixbuf

##  gboolean gdk_pixbuf_get_has_alpha (const GdkPixbuf *pixbuf) 
gboolean
gdk_pixbuf_get_has_alpha (pixbuf)
	GdkPixbuf *pixbuf

##  int gdk_pixbuf_get_bits_per_sample (const GdkPixbuf *pixbuf) 
int
gdk_pixbuf_get_bits_per_sample (pixbuf)
	GdkPixbuf *pixbuf

##  guchar *gdk_pixbuf_get_pixels (const GdkPixbuf *pixbuf) 
=for apidoc
Return a copy of the bytes comprising the pixel data of C<$pixbuf>.

As described in the Gdk Pixbuf reference manual (the "Note" section of
"The GdkPixbuf Structure"), the last row does not extend to the
rowstride, but ends with the last byte of the last pixel.  The length
of the C<get_pixels> return reflects this.
=cut
SV *
gdk_pixbuf_get_pixels (pixbuf)
	GdkPixbuf *pixbuf
    PREINIT:
	guchar * pixels;
	STRLEN size;
    CODE:
	/* For reference, most pixbuf mallocs are height*rowstride, for
	   example gdk_pixbuf_new() does that.  But gdk_pixbuf_copy()
	   mallocs only the lesser "last row unpadded" size.  If the code
	   here used height*rowstride it would read past the end of such a
	   block.

	   Most of the time rowstride is the next multiple of 4, and a
	   malloced block is the next multiple of 4 too, so it's ok, but for
	   a bigger rowstride it's not.

	   The following calculation adapted from gdk_pixbuf_copy() circa
	   Gtk 2.16.  bits_per_sample is only ever 8 currently, making it
	   simply n_channels many bytes-per-pixel, but the calculation
	   anticipates bits not a multiple of 8.  */

	size = ((gdk_pixbuf_get_height(pixbuf) - 1)
		* gdk_pixbuf_get_rowstride(pixbuf)
		+ gdk_pixbuf_get_width(pixbuf)
		* ((gdk_pixbuf_get_n_channels(pixbuf)
		    * gdk_pixbuf_get_bits_per_sample(pixbuf) + 7) / 8));
	pixels = gdk_pixbuf_get_pixels (pixbuf);
	RETVAL = newSVpv ((gchar *) pixels, size);
    OUTPUT:
	RETVAL

##  int gdk_pixbuf_get_width (const GdkPixbuf *pixbuf) 
int
gdk_pixbuf_get_width (pixbuf)
	GdkPixbuf *pixbuf

##  int gdk_pixbuf_get_height (const GdkPixbuf *pixbuf) 
int
gdk_pixbuf_get_height (pixbuf)
	GdkPixbuf *pixbuf

##  int gdk_pixbuf_get_rowstride (const GdkPixbuf *pixbuf) 
int
gdk_pixbuf_get_rowstride (pixbuf)
	GdkPixbuf *pixbuf

## G_CONST_RETURN gchar * gdk_pixbuf_get_option (GdkPixbuf *pixbuf, const gchar *key)
const gchar_ornull *
gdk_pixbuf_get_option (pixbuf, key)
	GdkPixbuf * pixbuf
	const gchar * key

#if GTK_CHECK_VERSION (2, 2, 0)

gboolean gdk_pixbuf_set_option (GdkPixbuf *pixbuf, const gchar *key, const gchar *value);

#endif /* 2.2 */

##  GdkPixbuf *gdk_pixbuf_new (GdkColorspace colorspace, gboolean has_alpha, int bits_per_sample, int width, int height) 
GdkPixbuf_noinc *
gdk_pixbuf_new (class, colorspace, has_alpha, bits_per_sample, width, height)
	GdkColorspace colorspace
	gboolean has_alpha
	int bits_per_sample
	int width
	int height
    C_ARGS:
	colorspace, has_alpha, bits_per_sample, width, height

##  GdkPixbuf *gdk_pixbuf_copy (const GdkPixbuf *pixbuf) 
GdkPixbuf_noinc *
gdk_pixbuf_copy (pixbuf)
	GdkPixbuf *pixbuf

##  GdkPixbuf *gdk_pixbuf_new_subpixbuf (GdkPixbuf *src_pixbuf, int src_x, int src_y, int width, int height) 
GdkPixbuf_noinc *
gdk_pixbuf_new_subpixbuf (src_pixbuf, src_x, src_y, width, height)
	GdkPixbuf *src_pixbuf
	int src_x
	int src_y
	int width
	int height

##  GdkPixbuf *gdk_pixbuf_new_from_file (const char *filename, GError **error) 
=for apidoc __gerror__
=cut
GdkPixbuf_noinc *
gdk_pixbuf_new_from_file (class, filename)
	GPerlFilename filename
    PREINIT:
        GError *error = NULL;
    CODE:
	RETVAL = gdk_pixbuf_new_from_file (filename, &error);
	if (!RETVAL)
		gperl_croak_gerror (filename, error);
    OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION(2,4,0)

## GdkPixbuf *gdk_pixbuf_new_from_file_at_size (const char *filename, int width, int height, GError **error);
=for apidoc __gerror__
=cut
GdkPixbuf_noinc *
gdk_pixbuf_new_from_file_at_size (class, GPerlFilename filename, int width, int height)
    PREINIT:
        GError *error = NULL;
    CODE:
	RETVAL = gdk_pixbuf_new_from_file_at_size
	                              (filename, width, height, &error);
	if (!RETVAL)
		gperl_croak_gerror (filename, error);
    OUTPUT:
	RETVAL

#endif

#if GTK_CHECK_VERSION(2,6,0)

## GdkPixbuf * gdk_pixbuf_new_from_file_at_scale (const char *filename, int width, int height, gboolean preserve_aspect_ratio, GError **error)
=for apidoc __gerror__
=cut
GdkPixbuf_noinc *
gdk_pixbuf_new_from_file_at_scale (class, GPerlFilename filename, int width, int height, gboolean preserve_aspect_ratio)
    PREINIT:
        GError *error = NULL;
    CODE:
	RETVAL = gdk_pixbuf_new_from_file_at_scale
	                              (filename, width, height,
	                               preserve_aspect_ratio, &error);
	if (!RETVAL)
		gperl_croak_gerror (filename, error);
    OUTPUT:
	RETVAL

#endif

###  GdkPixbuf *gdk_pixbuf_new_from_data (const guchar *data, GdkColorspace colorspace, gboolean has_alpha, int bits_per_sample, int width, int height, int rowstride, GdkPixbufDestroyNotify destroy_fn, gpointer destroy_fn_data) 
=for apidoc
=for arg data (scalar) packed binary pixel data, usually made with pack()
=for arg has_alpha true if the image data includes an alpha channel (opacity information).
=for arg width in pixels.
=for arg height in pixels.
=for arg rowstride distance in bytes between row starts; usually 3*width for rgb data, 4*width if I<$has_alpha> is true.

Creates a new Gtk2::Gdk::Pixbuf out of in-memory image data.  Currently only
RGB images with 8 bits per sample are supported.

In C this function allows you to wrap a GdkPixbuf structure around existing
pixel data.  In Perl, we have to use C<pack> to generate a scalar containing
the pixel data, and pass that scalar to C<new_from_data>, which copies the
scalar to keep it around.  It also manages the memory automagically, so there's
no need for a destruction notifier function.  This all means that if you change
your copy of the data scalar later, the pixbuf will I<not> reflect that, but
because of the way perl manages string data and scalars, it would be pretty
fragile to do that in the first place.  If you need to modify a pixbuf's data
after it has been created, you can create new pixbufs for the changed regions
and use C<< $pixbuf->composite >>, or try a different approach (possibly use a
server-side pixmap and gdk drawing primitives, or something like libart).

=cut
GdkPixbuf_noinc *
gdk_pixbuf_new_from_data (class, data, colorspace, has_alpha, bits_per_sample, width, height, rowstride)
	SV * data
	GdkColorspace colorspace
	gboolean has_alpha
	int bits_per_sample
	int width
	int height
	int rowstride
    PREINIT:
	char *data_ptr, *pix_ptr;
	STRLEN len;
    CODE:
	data_ptr = SvPV (data, len);
	Newx (pix_ptr, len, char);
	Copy (data_ptr, pix_ptr, len, char);
	RETVAL = gdk_pixbuf_new_from_data ((const guchar *) pix_ptr,
	                                   colorspace, has_alpha,
					   bits_per_sample,
					   width, height, rowstride,
					   gtk2perl_pixbuf_destroy_notify,
					   NULL);
    OUTPUT:
	RETVAL

##  GdkPixbuf *gdk_pixbuf_new_from_xpm_data (const char **data) 
=for apidoc
=for arg ... xpm data as a list of strings (see discussion)
X Pixel Map (XPM) files are designed to be easy to edit and easy to include
directly into C programs.  The file format is the C syntax of the declaration
and initialization of a variable containing an array of strings.
C<new_from_xpm_data> allows you to create an image from such data included
directly in your program source.

Since XPM files are C syntax, you must mangle that source a bit to work in a
Perl program.  For example, this is a valid xpm, but it is not valid Perl code:

 /* XPM */
 static char * test_xpm[] = {
 "4 4 3 1",
 " 	c None",
 ".	c red",
 "+	c blue",
 ".. +",
 ". ++",
 " ++.",
 "++.."};

You'll need to change the array declaration format, and change the
double-quoted strings to single-quoted to avoid Perl interpreting
any chars in the strings as special.

 my @test_xpm = (
 '4 4 3 1',
 ' 	c None',
 '.	c red',
 '+	c blue',
 '.. +',
 '. ++',
 ' ++.',
 '++..');

 $pixbuf = Gtk2::Gdk::Pixbuf->new_from_xpm_data (@test_xpm);

[It's only two or three regexes... Perhaps we should distribute a script
to convert XPM files to the proper format?]
=cut
GdkPixbuf_noinc *
gdk_pixbuf_new_from_xpm_data (class, ...)
    PREINIT:
	char ** lines;
	int i;
    CODE:
	/* Add a NULL terminator to protect against a segv if too few lines
	 * are supplied.  GdkPixbuf's io-xpm.c's mem_buffer() recognizes that
	 * as an end of data.  (Not documented, so far as i can tell, but
	 * still a pretty good idea.) */
	lines = g_new (char *, items - 1 + 1);
	for (i = 1; i < items; i++)
		lines[i-1] = SvPV_nolen (ST (i));
	lines[i-1] = NULL;
	RETVAL = gdk_pixbuf_new_from_xpm_data((const char**)lines);
	g_free(lines);
    OUTPUT:
	RETVAL

## croaks on error
##  GdkPixbuf* gdk_pixbuf_new_from_inline (gint data_length, const guint8 *data, gboolean copy_pixels, GError **error) 
=for apidoc __gerror__
=for arg data (scalar) packed binary data, the format is special, see discussion
=for arg copy_pixels whether I<$data> should be copied, defaults to true

Gtk+ ships with a tool called C<gdk-pixbuf-csource>, which turns any image
understood by gdk-pixbuf into the C syntax of the declaration of a static
data structure containing that image data, to be #included directly into
your source code.  C<gdk_pixbuf_new_from_inline> creates a new GdkPixbuf
from that data structure.

Currently, this is not very easy to do from Perl.  The output of
C<gdk-pixbuf-csource> must be mangled rather ruthlessly to create valid
Perl code using pack and translation from C string escapes to valid Perl
string escapes (for encoding and interpretation isses).  Because Perl
scalars are garbage collected, it's rather rare to have the ability to use
static data, so I<$copy_pixels> defaults to true; if you can guarantee the
image data will outlive the pixbuf you can pass false here and save some
memory. 

For more information, see the description of C<gdk_pixbuf_new_from_inline>
in the C API reference at http://gtk.org/api/ .
=cut
GdkPixbuf_noinc *
gdk_pixbuf_new_from_inline (class, data, copy_pixels=TRUE)
	SV *data
	gboolean copy_pixels
    PREINIT:
	GError * error = NULL;
	STRLEN data_length;
	const guchar * raw_data;
    CODE:
	raw_data = (const guchar *) SvPV (data, data_length);
	RETVAL = gdk_pixbuf_new_from_inline (data_length, raw_data, 
	                                     copy_pixels, &error);
	if (!RETVAL)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL


### croaks on error
##  gboolean gdk_pixbuf_save (GdkPixbuf *pixbuf, const char *filename, const char *type, GError **error, ...) 
=for apidoc __gerror__
=for arg type name of file format (e.g. "jpeg", "png")
=for arg ... list of key-value save options

Save I<$pixbuf> to a file named I<$filename>, in the format I<$type>, which
is currently "jpeg" or "png".  The function will croak if there is an error,
which may arise from file- or image format-related issues.

Any values in I<...> should be key/value string pairs that modify the saving
parameters.  For example:

 $pixbuf->save ($filename, 'jpeg', quality => '100');

Currently only a few parameters exist.  JPEG images can be saved with a
"quality" parameter; its value should be in the range [0,100].  Text chunks can
be attached to PNG images by specifying parameters of the form "tEXt::key",
where key is an ASCII string of length 1-79.  The values are UTF-8 encoded
strings.  (This is a quote from the C API reference; note that the C API
reference is the canonical source for this information.)

=cut
void
gdk_pixbuf_save (pixbuf, filename, type, ...)
	GdkPixbuf *pixbuf
	GPerlFilename filename
	gchar *type
    PREINIT:
	GError * error = NULL;
	char ** option_keys = NULL;
	char ** option_vals = NULL;
	int i, nkeys;
	gboolean worked;
    CODE:
	/* collect key/val pairs from the argument stack and 
	 * call gdk_pixbuf_savev */
#define FIRST_KEY 3
	nkeys = items - FIRST_KEY;
	if (nkeys % 2)
		croak ("gdk_pixbuf_save expects options as key => value pairs "
		       "(odd number of arguments detected)");
	nkeys /= 2;
	/* always allocate them.  doesn't hurt.  always one longer for the
	 * null-terminator, which is set by g_new0. */
	option_keys = g_new0 (char *, nkeys + 1);
	option_vals = g_new0 (char *, nkeys + 1);

	for (i = 0 ; i < nkeys ; i++) {
		/* NOT copies of the strings.
		   option_vals[] are utf8 for png format "tEXt::Foo" etc.
		   option_keys[] are ascii-only circa gtk 2.18, but presume
		   any non-ascii there would be utf8 too. */
		option_keys[i] = SvGChar (ST (FIRST_KEY + i*2 + 0));
		option_vals[i] = SvGChar (ST (FIRST_KEY + i*2 + 1));
	}

	worked = gdk_pixbuf_savev (pixbuf, filename, type, 
	                           option_keys, option_vals, &error);
	/* don't free the strings themselves! */
	g_free (option_keys);
	g_free (option_vals);
	if (!worked)
		gperl_croak_gerror (filename, error);
#undef FIRST_KEY


#if GTK_CHECK_VERSION(2, 4, 0)

### croaks on error
##  gboolean gdk_pixbuf_save_to_buffer (GdkPixbuf *pixbuf, gchar ** buffer, gsize *buffer_size, const char *type, GError **error, ...) 
=for apidoc __gerror__
=for arg type name of file format (e.g. "jpeg", "png")
=for arg ... list of key-value save options

Save I<$pixbuf> to a scalar buffer, in the format I<$type>, which is currently
"jpeg" or "png".  The function will croak if there is an error, which may arise
from image format-related issues.

The returned string contains binary data, which may have embedded nuls.  Don't
try to C<print> it.

See C<Gtk2::Gdk::Pixbuf::save> for more details.

=cut
SV *
gdk_pixbuf_save_to_buffer (pixbuf, type, ...)
	GdkPixbuf *pixbuf
	gchar *type
    PREINIT:
	GError * error = NULL;
	char ** option_keys = NULL;
	char ** option_vals = NULL;
	int i, nkeys;
    CODE:
	/* collect key/val pairs from the argument stack and 
	 * call gdk_pixbuf_save_to_bufferv */
#define FIRST_KEY 2
	nkeys = (items - FIRST_KEY) / 2;
	/* always allocate them.  doesn't hurt.  always one longer for the
	 * null-terminator, which is set by g_new0. */
	option_keys = g_new0 (char *, nkeys + 1);
	option_vals = g_new0 (char *, nkeys + 1);

	for (i = 0 ; i < nkeys ; i++) {
		/* NOT copies */
		option_keys[i] = SvPV_nolen (ST (FIRST_KEY + i*2 + 0));
		option_vals[i] = SvPV_nolen (ST (FIRST_KEY + i*2 + 1));
	}
#undef FIRST_KEY
        RETVAL = newSV (1024);
	sv_setpvn (RETVAL, "", 0);
        if (! gdk_pixbuf_save_to_callbackv (pixbuf,
                                            save_to_sv_callback, RETVAL,
                                            type, option_keys, option_vals,
                                            &error)) {
                SvREFCNT_dec (RETVAL);
                gperl_croak_gerror (NULL, error);
        }
	/* don't free the strings themselves! */
	g_free (option_keys);
	g_free (option_vals);
    OUTPUT:
	RETVAL

#endif /* 2.4 */

##  GdkPixbuf *gdk_pixbuf_add_alpha (const GdkPixbuf *pixbuf, gboolean substitute_color, guchar r, guchar g, guchar b) 
GdkPixbuf_noinc *
gdk_pixbuf_add_alpha (pixbuf, substitute_color, r, g, b)
	GdkPixbuf *pixbuf
	gboolean substitute_color
	guchar r
	guchar g
	guchar b

##  void gdk_pixbuf_copy_area (const GdkPixbuf *src_pixbuf, int src_x, int src_y, int width, int height, GdkPixbuf *dest_pixbuf, int dest_x, int dest_y) 
void
gdk_pixbuf_copy_area (src_pixbuf, src_x, src_y, width, height, dest_pixbuf, dest_x, dest_y)
	GdkPixbuf *src_pixbuf
	int src_x
	int src_y
	int width
	int height
	GdkPixbuf *dest_pixbuf
	int dest_x
	int dest_y

##  void gdk_pixbuf_saturate_and_pixelate (const GdkPixbuf *src, GdkPixbuf *dest, gfloat saturation, gboolean pixelate) 
void
gdk_pixbuf_saturate_and_pixelate (src, dest, saturation, pixelate)
	GdkPixbuf *src
	GdkPixbuf *dest
	gfloat saturation
	gboolean pixelate

##  void gdk_pixbuf_fill (GdkPixbuf *pixbuf, guint32 pixel) 
=for apidoc
=for arg pixel a packed RGBA value.
Clear I<$pixbuf> to contain only the value given in I<$pixel>.
=cut
void
gdk_pixbuf_fill (pixbuf, pixel)
	GdkPixbuf *pixbuf
	guint32 pixel

#if GTK_CHECK_VERSION (2, 6, 0)

GdkPixbuf_noinc * gdk_pixbuf_rotate_simple (const GdkPixbuf *src, GdkPixbufRotation angle);

GdkPixbuf_noinc * gdk_pixbuf_flip (const GdkPixbuf *src, gboolean horizontal);

#endif

##  void gdk_pixbuf_scale (const GdkPixbuf *src, GdkPixbuf *dest, int dest_x, int dest_y, int dest_width, int dest_height, double offset_x, double offset_y, double scale_x, double scale_y, GdkInterpType interp_type) 
void
gdk_pixbuf_scale (src, dest, dest_x, dest_y, dest_width, dest_height, offset_x, offset_y, scale_x, scale_y, interp_type)
	GdkPixbuf *src
	GdkPixbuf *dest
	int dest_x
	int dest_y
	int dest_width
	int dest_height
	double offset_x
	double offset_y
	double scale_x
	double scale_y
	GdkInterpType interp_type

##  void gdk_pixbuf_composite (const GdkPixbuf *src, GdkPixbuf *dest, int dest_x, int dest_y, int dest_width, int dest_height, double offset_x, double offset_y, double scale_x, double scale_y, GdkInterpType interp_type, int overall_alpha) 
void
gdk_pixbuf_composite (src, dest, dest_x, dest_y, dest_width, dest_height, offset_x, offset_y, scale_x, scale_y, interp_type, overall_alpha)
	GdkPixbuf *src
	GdkPixbuf *dest
	int dest_x
	int dest_y
	int dest_width
	int dest_height
	double offset_x
	double offset_y
	double scale_x
	double scale_y
	GdkInterpType interp_type
	int overall_alpha

##  void gdk_pixbuf_composite_color (const GdkPixbuf *src, GdkPixbuf *dest, int dest_x, int dest_y, int dest_width, int dest_height, double offset_x, double offset_y, double scale_x, double scale_y, GdkInterpType interp_type, int overall_alpha, int check_x, int check_y, int check_size, guint32 color1, guint32 color2) 
void
gdk_pixbuf_composite_color (src, dest, dest_x, dest_y, dest_width, dest_height, offset_x, offset_y, scale_x, scale_y, interp_type, overall_alpha, check_x, check_y, check_size, color1, color2)
	GdkPixbuf *src
	GdkPixbuf *dest
	int dest_x
	int dest_y
	int dest_width
	int dest_height
	double offset_x
	double offset_y
	double scale_x
	double scale_y
	GdkInterpType interp_type
	int overall_alpha
	int check_x
	int check_y
	int check_size
	guint32 color1
	guint32 color2

##  GdkPixbuf *gdk_pixbuf_scale_simple (const GdkPixbuf *src, int dest_width, int dest_height, GdkInterpType interp_type) 
GdkPixbuf_noinc_ornull *
gdk_pixbuf_scale_simple (src, dest_width, dest_height, interp_type)
	GdkPixbuf *src
	int dest_width
	int dest_height
	GdkInterpType interp_type

##  GdkPixbuf *gdk_pixbuf_composite_color_simple (const GdkPixbuf *src, int dest_width, int dest_height, GdkInterpType interp_type, int overall_alpha, int check_size, guint32 color1, guint32 color2) 
GdkPixbuf_noinc_ornull *
gdk_pixbuf_composite_color_simple (src, dest_width, dest_height, interp_type, overall_alpha, check_size, color1, color2)
	GdkPixbuf *src
	int dest_width
	int dest_height
	GdkInterpType interp_type
	int overall_alpha
	int check_size
	guint32 color1
	guint32 color2

#if GTK_CHECK_VERSION (2, 11, 0)

GdkPixbuf_noinc * gdk_pixbuf_apply_embedded_orientation (GdkPixbuf *src);

#endif


MODULE = Gtk2::Gdk::Pixbuf	PACKAGE = Gtk2::Gdk::PixbufAnimation	PREFIX = gdk_pixbuf_animation_

BOOT:
	/* types like GdkPixbufGifAnim are unknown to us. */
	gperl_object_set_no_warn_unreg_subclass
					(GDK_TYPE_PIXBUF_ANIMATION, TRUE);

##  GdkPixbufAnimation *gdk_pixbuf_animation_new_from_file (const char *filename, GError **error) 
=for apidoc __gerror__
=cut
GdkPixbufAnimation_noinc *
gdk_pixbuf_animation_new_from_file (class, filename)
	GPerlFilename filename
    PREINIT:
	GError * error = NULL;
    CODE:
	RETVAL = gdk_pixbuf_animation_new_from_file (filename, &error);
	if (!RETVAL)
		gperl_croak_gerror (filename, error);
    OUTPUT:
	RETVAL

### handled by Glib::Object
###  GdkPixbufAnimation *gdk_pixbuf_animation_ref (GdkPixbufAnimation *animation) 
###  void gdk_pixbuf_animation_unref (GdkPixbufAnimation *animation) 

##  int gdk_pixbuf_animation_get_width (GdkPixbufAnimation *animation) 
int
gdk_pixbuf_animation_get_width (animation)
	GdkPixbufAnimation *animation

##  int gdk_pixbuf_animation_get_height (GdkPixbufAnimation *animation) 
int
gdk_pixbuf_animation_get_height (animation)
	GdkPixbufAnimation *animation

##  gboolean gdk_pixbuf_animation_is_static_image (GdkPixbufAnimation *animation) 
gboolean
gdk_pixbuf_animation_is_static_image (animation)
	GdkPixbufAnimation *animation

##  GdkPixbuf *gdk_pixbuf_animation_get_static_image (GdkPixbufAnimation *animation) 
GdkPixbuf *
gdk_pixbuf_animation_get_static_image (animation)
	GdkPixbufAnimation *animation

## there's no typemap for GTimeVal.
## GTimeVal is in GLib, same as unix' struct timeval.
## timeval is seconds and microseconds, which we can get from Time::HiRes.
## so, we'll take seconds and microseconds.  if neither is available,
## pass NULL to the wrapped function to get the current time.
###  GdkPixbufAnimationIter *gdk_pixbuf_animation_get_iter (GdkPixbufAnimation *animation, const GTimeVal *start_time) 
=for apidoc

The seconds and microseconds values are available from Time::HiRes, which is
standard since perl 5.8.0.  If both are undef or omitted, the function uses the
current time.

=cut
GdkPixbufAnimationIter_noinc *
gdk_pixbuf_animation_get_iter (animation, start_time_seconds=0, start_time_microseconds=0)
	GdkPixbufAnimation *animation
	guint start_time_seconds
	guint start_time_microseconds
    CODE:
	if (start_time_microseconds) {
		GTimeVal start_time;
		start_time.tv_sec = start_time_seconds;
		start_time.tv_usec = start_time_microseconds;
		RETVAL = gdk_pixbuf_animation_get_iter (animation,
		                                        &start_time);
	} else
		RETVAL = gdk_pixbuf_animation_get_iter (animation, NULL);
    OUTPUT:
	RETVAL

MODULE = Gtk2::Gdk::Pixbuf	PACKAGE = Gtk2::Gdk::PixbufAnimationIter	PREFIX = gdk_pixbuf_animation_iter_

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GDK_TYPE_PIXBUF_ANIMATION_ITER, TRUE);

int gdk_pixbuf_animation_iter_get_delay_time (GdkPixbufAnimationIter *iter) 

GdkPixbuf *gdk_pixbuf_animation_iter_get_pixbuf (GdkPixbufAnimationIter *iter) 

gboolean gdk_pixbuf_animation_iter_on_currently_loading_frame (GdkPixbufAnimationIter *iter) 

###  gboolean gdk_pixbuf_animation_iter_advance (GdkPixbufAnimationIter *iter, const GTimeVal *current_time) 
gboolean
gdk_pixbuf_animation_iter_advance (iter, current_time_seconds=0, current_time_microseconds=0)
	GdkPixbufAnimationIter *iter
	guint current_time_seconds
	guint current_time_microseconds
    CODE:
	if (current_time_microseconds) {
		GTimeVal current_time;
		current_time.tv_sec = current_time_seconds;
		current_time.tv_usec = current_time_microseconds;
		RETVAL = gdk_pixbuf_animation_iter_advance (iter,
		                                            &current_time);
	} else
		RETVAL = gdk_pixbuf_animation_iter_advance (iter, NULL);
     OUTPUT:
	RETVAL


MODULE = Gtk2::Gdk::Pixbuf	PACKAGE = Gtk2::Gdk::Pixbuf	PREFIX = gdk_pixbuf_

#if GTK_CHECK_VERSION(2,2,0)

## GdkPixbufFormat is an information structure, so we'll just hashify it so you
## can use Data::Dumper on it.

# returned strings should be freed
###  gchar *gdk_pixbuf_format_get_name (GdkPixbufFormat *format) 
###  gchar *gdk_pixbuf_format_get_description (GdkPixbufFormat *format) 
###  gchar ** gdk_pixbuf_format_get_mime_types (GdkPixbufFormat *format)
###  gchar ** gdk_pixbuf_format_get_extensions (GdkPixbufFormat *format)
###  gboolean gdk_pixbuf_format_is_writable (GdkPixbufFormat *format) 
###  gboolean gdk_pixbuf_format_is_scalable (GdkPixbufFormat *format)
###  gboolean gdk_pixbuf_format_is_disabled (GdkPixbufFormat *format)
###  gchar *gdk_pixbuf_format_get_license (GdkPixbufFormat *format)

###  GSList *gdk_pixbuf_get_formats (void) 
## list should be freed, but not formats
=for apidoc
Returns a list of hashes with information about the formats supported by
Gtk2::Gdk::Pixbuf.
=cut
void
gdk_pixbuf_get_formats (class=NULL)
    PREINIT:
	GSList * formats, * i;
    PPCODE:
	formats = gdk_pixbuf_get_formats ();
	for (i = formats ; i != NULL ; i = i->next) {
		XPUSHs (sv_2mortal (newSVGdkPixbufFormat (i->data)));
	}
	g_slist_free (formats);
	PERL_UNUSED_VAR (ax);

#endif /* >= 2.2.0 */

#if GTK_CHECK_VERSION(2,4,0)

###  GdkPixbufFormat *gdk_pixbuf_get_file_info (const gchar *filename, gint *width, gint *height)
=for apidoc
=for signature (format, width, height) = $pixbuf->get_file_info ($filename)

Parses enough of I<$filename> to determine and return the format and size.
If the format is unknown or the file can't be opened, returns an empty list.

=cut
void gdk_pixbuf_get_file_info (class, filename)
	GPerlFilename filename
    PREINIT:
	GdkPixbufFormat *format;
	gint width = -1;
	gint height = -1;
    PPCODE:
	format = gdk_pixbuf_get_file_info (filename, &width, &height);
	if (format) {
		EXTEND (sp, 3);
		PUSHs (sv_2mortal (newSVGdkPixbufFormat (format)));
		PUSHs (sv_2mortal (newSViv (width)));
		PUSHs (sv_2mortal (newSViv (height)));
	}

#endif

MODULE = Gtk2::Gdk::Pixbuf	PACKAGE = Gtk2::Gdk::PixbufFormat	PREFIX = gdk_pixbuf_format_

=for position DESCRIPTION

=head1 DESCRIPTION

A C<Gtk2::Gdk::PixbufFormat> has the following format information fields,
eg. C<< $format->{'name'} >>,

    name            string
    description     string
    mime_types      arrayref of strings
    extensions      arrayref of strings, eg. ['jpg','jpeg']
    is_writable     0 or 1
    is_scalable     0 or 1    # in Gtk 2.6 up
    is_disabled     0 or 1    # in Gtk 2.6 up
    license         string    # in Gtk 2.6 up

=cut

#if GTK_CHECK_VERSION(2, 2, 0)

void
DESTROY (sv)
	SV *sv
    CODE:
	_gperl_remove_mg (SvRV (sv));

#endif /* 2.2.0 */

#if GTK_CHECK_VERSION(2, 6, 0)

=for apidoc

Note that any change caused by this method will not immediately affect
I<$format-E<gt>{is_disabled}>.  You need to refetch the format in order to see
the new value.

=cut
void gdk_pixbuf_format_set_disabled (GdkPixbufFormat *format, gboolean disabled);

#endif /* 2.6.0 */
