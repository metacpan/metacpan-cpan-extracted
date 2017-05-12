#include "gtk2-ex-geo.h"

/* This xs file provides methods for the struct gtk2_ex_geo_pixbuf:

- gtk2_ex_geo_pixbuf_create (create the struct and the cairo surface)
- gtk2_ex_geo_pixbuf_get_size
- gtk2_ex_geo_pixbuf_get_world
- gtk2_ex_geo_pixbuf_get_pixel_size
- gtk2_ex_geo_pixbuf_get_cairo_surface (get a handle to the cairo surface)
- gtk2_ex_geo_pixbuf_get_pixbuf (convert the cairo surface to a gdk pixbuf)
- gtk2_ex_geo_pixbuf_destroy (destroy the cairo surface and the struct)

and

- gtk2_ex_geo_pixbuf_destroy_notify (destroy the pixbuf))

*/

static void
gtk2_ex_geo_pixbuf_destroy_notify (guchar * pixels,
			   gpointer data)
{
	/*fprintf(stderr,"free %#x\n",pixels);*/
	free(pixels);
}

MODULE = Gtk2::Ex::Geo		PACKAGE = Gtk2::Ex::Geo

gtk2_ex_geo_pixbuf *
gtk2_ex_geo_pixbuf_create(int width, int height, double minX, double maxY, double pixel_size, int bgc1, int bgc2, int bgc3, int bga)
	CODE:
		gtk2_ex_geo_pixbuf *pb = malloc(sizeof(gtk2_ex_geo_pixbuf));
		if (pb) {
			pb->pixbuf = NULL;
			pb->destroy_fn = NULL;
			pb->image = malloc(4*width*height);
			pb->colorspace = GDK_COLORSPACE_RGB;
			pb->has_alpha = TRUE; /*FALSE;*/
			pb->image_rowstride = 4 * width;
			pb->rowstride = 4 * width;
			pb->bits_per_sample = 8;
			pb->height = height;
			pb->width = width;
			pb->world_min_x = minX;
			pb->world_max_y = maxY;
			pb->pixel_size = pixel_size;
			if (pb->image) {
				int i,j;
				for (i = 0; i < height; i++) for (j = 0; j < width; j++) {
					int k = 4*i*width+4*j;
					(pb->image)[k+3] = bga;
 					(pb->image)[k+2] = bgc1;
					(pb->image)[k+1] = bgc2;
					(pb->image)[k+0] = bgc3;
				}
			} else {
				free(pb);
				croak("Out of memory");
			}
		} else
			croak("Out of memory");
		RETVAL = pb;
	OUTPUT:
		RETVAL

AV *
gtk2_ex_geo_pixbuf_get_size(gtk2_ex_geo_pixbuf *pb)
	CODE:
		AV *av = (AV *)sv_2mortal((SV*)newAV());
		av_push(av, newSViv(pb->width));
		av_push(av, newSViv(pb->height));
		RETVAL = av;
  OUTPUT:
    RETVAL

AV *
gtk2_ex_geo_pixbuf_get_world(gtk2_ex_geo_pixbuf *pb)
	CODE:
		AV *av = (AV *)sv_2mortal((SV*)newAV());
		av_push(av, newSVnv(pb->world_min_x));
		av_push(av, newSVnv(pb->world_max_y-pb->height*pb->pixel_size));
		av_push(av, newSVnv(pb->world_min_x+pb->width*pb->pixel_size));
		av_push(av, newSVnv(pb->world_max_y));
		RETVAL = av;
  OUTPUT:
    RETVAL

double
gtk2_ex_geo_pixbuf_get_pixel_size(gtk2_ex_geo_pixbuf *pb)
	CODE:
		RETVAL = pb->pixel_size;
  OUTPUT:
    RETVAL

cairo_surface_t_noinc *
gtk2_ex_geo_pixbuf_get_cairo_surface(gtk2_ex_geo_pixbuf *pb)
	CODE:
		RETVAL = cairo_image_surface_create_for_data
			(pb->image, CAIRO_FORMAT_ARGB32, pb->width, pb->height, pb->image_rowstride);
	OUTPUT:
		RETVAL

GdkPixbuf_noinc *
gtk2_ex_geo_pixbuf_get_pixbuf(gtk2_ex_geo_pixbuf *pb)
	CODE:
		guint i, j;
		unsigned char *src, *dst;
		if (pb->pixbuf) free(pb->pixbuf);
		pb->pixbuf = NULL;
		pb->pixbuf = malloc(4*pb->width*pb->height);
		if (!pb->pixbuf)
			croak("Out of memory");
		pb->destroy_fn = gtk2_ex_geo_pixbuf_destroy_notify;
		dst = pb->pixbuf;
		src = pb->image;
		for (i = 0; i < pb->height; i++) {
			for (j = 0; j < pb->width; j++) {
#if G_BYTE_ORDER == G_LITTLE_ENDIAN
				dst[0] = src[2];
				dst[1] = src[1];
				dst[2] = src[0];
                                dst[3] = src[3];
#else
				dst[0] = src[1];
				dst[1] = src[2];
				dst[2] = src[3];
                                dst[3] = src[0];
#endif
				src += 4;
				dst += 4;
			}
		}
		RETVAL =
		gdk_pixbuf_new_from_data(pb->pixbuf,
				     pb->colorspace,
				     pb->has_alpha,
				     pb->bits_per_sample,
				     pb->width,
				     pb->height,
				     pb->rowstride,
				     pb->destroy_fn,
				     NULL);
	OUTPUT:
		RETVAL

void
gtk2_ex_geo_pixbuf_destroy(gtk2_ex_geo_pixbuf *pb)
	CODE:
		free(pb->image);
		free(pb);

