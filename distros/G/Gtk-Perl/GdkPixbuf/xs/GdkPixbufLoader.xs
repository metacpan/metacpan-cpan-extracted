
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGdkPixbufInt.h"

#include "GdkPixbufDefs.h"

MODULE = Gtk::Gdk::PixbufLoader		PACKAGE = Gtk::Gdk::PixbufLoader		PREFIX = gdk_pixbuf_loader_

#ifdef GDK_PIXBUF_LOADER

Gtk::Gdk::PixbufLoader_Sink
gdk_pixbuf_loader_new (Class)
	SV	*Class
	CODE:
	RETVAL = (GdkPixbufLoader*)(gdk_pixbuf_loader_new());
	OUTPUT:
	RETVAL

bool
gdk_pixbuf_loader_write (loader, buf)
	Gtk::Gdk::PixbufLoader	loader
	SV	*buf
	CODE:
	{
		STRLEN blen;
		char *cbuf = SvPV(buf, blen);
		RETVAL = gdk_pixbuf_loader_write (loader, cbuf, blen);
	}
	OUTPUT:
	RETVAL

Gtk::Gdk::Pixbuf
gdk_pixbuf_loader_get_pixbuf (loader)
	Gtk::Gdk::PixbufLoader	loader
	
Gtk::Gdk::PixbufAnimation
gdk_pixbuf_loader_get_animation (loader)
	Gtk::Gdk::PixbufLoader	loader
	
void
gdk_pixbuf_loader_close (loader)
	Gtk::Gdk::PixbufLoader	loader

#endif

