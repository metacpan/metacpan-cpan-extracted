
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



MODULE = Gtk::CheckMenuItem		PACKAGE = Gtk::CheckMenuItem	PREFIX = gtk_check_menu_item_

#ifdef GTK_CHECK_MENU_ITEM

Gtk::CheckMenuItem
new(Class, label=0)
	SV *	Class
	char *	label
	CODE:
	if (!label)
		RETVAL = GTK_CHECK_MENU_ITEM(gtk_check_menu_item_new());
	else
		RETVAL = GTK_CHECK_MENU_ITEM(gtk_check_menu_item_new_with_label(label));
	OUTPUT:
	RETVAL

Gtk::CheckMenuItem
new_with_label(Class, label)
	SV *	Class
	char *	label
	CODE:
	RETVAL = GTK_CHECK_MENU_ITEM(gtk_check_menu_item_new_with_label(label));
	OUTPUT:
	RETVAL

void
gtk_check_menu_item_set_state(check_menu_item, state)
	Gtk::CheckMenuItem	check_menu_item
	int	state

void
gtk_check_menu_item_toggled(check_menu_item)
	Gtk::CheckMenuItem	check_menu_item

void
gtk_check_menu_item_set_show_toggle(check_menu_item, always)
	Gtk::CheckMenuItem	check_menu_item
	bool	always

#endif
