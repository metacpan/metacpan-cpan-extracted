
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


MODULE = Gtk::ListItem		PACKAGE = Gtk::ListItem		PREFIX = gtk_list_item_

#ifdef GTK_LIST_ITEM

Gtk::ListItem
new(Class, string=0)
	SV *	Class
	char *	string
	CODE:
	if (!string)
		RETVAL = GTK_LIST_ITEM(gtk_list_item_new());
	else
		RETVAL = GTK_LIST_ITEM(gtk_list_item_new_with_label(string));
	OUTPUT:
	RETVAL

Gtk::ListItem
new_with_label(Class, string)
	SV *	Class
	char *	string
	CODE:
	RETVAL = GTK_LIST_ITEM(gtk_list_item_new_with_label(string));
	OUTPUT:
	RETVAL

void
gtk_list_item_select(self)
	Gtk::ListItem	self

void
gtk_list_item_deselect(self)
	Gtk::ListItem	self

#endif
