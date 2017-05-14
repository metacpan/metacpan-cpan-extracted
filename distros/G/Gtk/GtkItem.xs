
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


MODULE = Gtk::Item		PACKAGE = Gtk::Item		PREFIX = gtk_item_

#ifdef GTK_ITEM

void
gtk_item_select(item)	
	Gtk::Item	item

void
gtk_item_deselect(item)	
	Gtk::Item	item

void
gtk_item_toggle(item)	
	Gtk::Item	item

#endif
