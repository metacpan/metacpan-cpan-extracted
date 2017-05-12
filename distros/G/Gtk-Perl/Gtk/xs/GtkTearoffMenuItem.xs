
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"

MODULE = Gtk::TearoffMenuItem		PACKAGE = Gtk::TearoffMenuItem		PREFIX = gtk_tearoff_menu_item_

#ifdef GTK_TEAROFF_MENU_ITEM

Gtk::TearoffMenuItem_Sink
new(Class)
	SV * Class
	CODE:
	RETVAL = (GtkTearoffMenuItem*)(gtk_tearoff_menu_item_new());
	OUTPUT:
	RETVAL

#endif

