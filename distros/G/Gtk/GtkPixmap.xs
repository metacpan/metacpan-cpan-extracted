
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"

#include "GtkDefs.h"

#ifndef boolSV
# define boolSV(b) ((b) ? &sv_yes : &sv_no)
#endif


MODULE = Gtk::Pixmap		PACKAGE = Gtk::Pixmap		PREFIX = gtk_pixmap_

#ifdef GTK_PIXMAP

Gtk::Pixmap
new(Class, pixmap, mask)
	SV *	Class
	Gtk::Gdk::Pixmap	pixmap
	Gtk::Gdk::Bitmap	mask
	CODE:
	RETVAL = GTK_PIXMAP(gtk_pixmap_new(pixmap,mask));
	OUTPUT:
	RETVAL

void
gtk_pixmap_set(pixmap, val, mask )
	Gtk::Pixmap	pixmap
	Gtk::Gdk::Pixmap	val
	Gtk::Gdk::Bitmap	mask

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

#endif
