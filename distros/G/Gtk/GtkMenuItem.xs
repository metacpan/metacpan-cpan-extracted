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

MODULE = Gtk::MenuItem		PACKAGE = Gtk::MenuItem		PREFIX = gtk_menu_item_

#ifdef GTK_MENU_ITEM

Gtk::MenuItem
new(Class, label=0)
	SV *	Class
	char *	label
	CODE:
	if (label)
		RETVAL = GTK_MENU_ITEM(gtk_menu_item_new_with_label(label));
	else
		RETVAL = GTK_MENU_ITEM(gtk_menu_item_new());
	OUTPUT:
	RETVAL

Gtk::MenuItem
new_with_label(Class, label)
	SV *	Class
	char *	label
	CODE:
	RETVAL = GTK_MENU_ITEM(gtk_menu_item_new_with_label(label));
	OUTPUT:
	RETVAL

void
gtk_menu_item_set_submenu(self, child)
	Gtk::MenuItem	self
	Gtk::Widget	child

void
gtk_menu_item_remove_submenu (self)
	Gtk::MenuItem   self

void
gtk_menu_item_set_placement(self, placement)
	Gtk::MenuItem	self
	Gtk::SubmenuPlacement	placement

void
gtk_menu_item_accelerator_size(self)
	Gtk::MenuItem	self

void
gtk_menu_item_accelerator_text(self, buffer)
	Gtk::MenuItem	self
	char *	buffer

void
gtk_menu_item_configure(self, show_toggle, show_submenu)
	Gtk::MenuItem	self
	bool	show_toggle
	bool	show_submenu

void
gtk_menu_item_select(self)
	Gtk::MenuItem	self

void
gtk_menu_item_deselect(self)
	Gtk::MenuItem	self

void
gtk_menu_item_activate(self)
	Gtk::MenuItem	self

void
gtk_menu_item_right_justify(self)
	Gtk::MenuItem	self

#endif
