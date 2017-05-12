
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gtk::PixmapMenuItem		PACKAGE = Gtk::PixmapMenuItem		PREFIX = gtk_pixmap_menu_item_

#ifdef GTK_PIXMAP_MENU_ITEM


Gtk::PixmapMenuItem_Sink
new (Class)
	SV *	Class
	CODE:
	RETVAL = (GtkPixmapMenuItem*)(gtk_pixmap_menu_item_new());
	OUTPUT:
	RETVAL

void
gtk_pixmap_menu_item_set_pixmap (menu_item, pixmap)
	Gtk::PixmapMenuItem	menu_item
	Gtk::Widget	pixmap


#endif

