
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Pixmap		PACKAGE = Gtk::Pixmap		PREFIX = gtk_pixmap_

#ifdef GTK_PIXMAP

Gtk::Pixmap_Sink
new(Class, pixmap, mask)
	SV *	Class
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::Bitmap_OrNULL	mask
	CODE:
	RETVAL = (GtkPixmap*)(gtk_pixmap_new(pixmap,mask));
	OUTPUT:
	RETVAL

void
gtk_pixmap_set(pixmap, val, mask )
	Gtk::Pixmap	pixmap
	Gtk::Gdk::Pixmap_OrNULL	val
	Gtk::Gdk::Bitmap_OrNULL	mask


# FIXME: Reasonable return values?

void
gtk_pixmap_get(pixmap)
	Gtk::Pixmap	pixmap
	PPCODE:
	{
		GdkPixmap * result = 0;
		GdkBitmap * mask = 0;
		gtk_pixmap_get(pixmap, &result, (GIMME == G_ARRAY) ? &mask : 0);
		if (result) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkPixmap(result)));
		}
		if (mask) {
			EXTEND(sp,1);
			PUSHs(sv_2mortal(newSVGdkBitmap(mask)));
		}
	}

#if GTK_HVER > 0x010103

void
gtk_pixmap_set_build_insensitive (pixmap, build)
	Gtk::Pixmap	pixmap
	int	build

#endif

#endif
