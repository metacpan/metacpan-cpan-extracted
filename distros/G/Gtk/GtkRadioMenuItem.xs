
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


MODULE = Gtk::RadioMenuItem		PACKAGE = Gtk::RadioMenuItem		PREFIX = gtk_menu_item_

#ifdef GTK_RADIO_MENU_ITEM

Gtk::RadioMenuItem
new(Class, label=0, previous=0)
	SV *	Class
	SV *	label
	Gtk::RadioMenuItemOrNULL	previous
	CODE:
	{
		GSList * group = 0;
		if (previous)	
			group = gtk_radio_menu_item_group(previous);
		if (label && SvOK(label))
			RETVAL = GTK_RADIO_MENU_ITEM(gtk_radio_menu_item_new_with_label(group, SvPV(label,na)));
		else
			RETVAL = GTK_RADIO_MENU_ITEM(gtk_radio_menu_item_new(group));
	}
	OUTPUT:
	RETVAL

Gtk::RadioMenuItem
new_with_label(Class, label, previous=0)
	SV *	Class
	char *	label
	Gtk::RadioMenuItemOrNULL	previous
	CODE:
	{
		GSList * group = 0;
		if (previous)	
			group = gtk_radio_menu_item_group(previous);
		RETVAL = GTK_RADIO_MENU_ITEM(gtk_radio_menu_item_new_with_label(group, label));
	}
	OUTPUT:
	RETVAL

#endif
