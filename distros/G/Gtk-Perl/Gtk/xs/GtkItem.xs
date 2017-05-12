
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Item		PACKAGE = Gtk::Item		PREFIX = gtk_item_

#ifdef GTK_ITEM

void
gtk_item_select(item)	
	Gtk::Item	item
	ALIAS:
		Gtk::Item::select = 0
		Gtk::Item::deselect = 1
		Gtk::Item::toggle = 2
	CODE:
	switch (ix) {
	case 0: gtk_item_select(item); break;
	case 1: gtk_item_deselect(item); break;
	case 2: gtk_item_toggle(item); break;
	}

#endif
