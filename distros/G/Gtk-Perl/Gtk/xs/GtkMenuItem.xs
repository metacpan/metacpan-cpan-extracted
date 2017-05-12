#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::MenuItem		PACKAGE = Gtk::MenuItem		PREFIX = gtk_menu_item_

#ifdef GTK_MENU_ITEM

Gtk::MenuItem_Sink
new(Class, label=0)
	SV *	Class
	char *	label
	ALIAS:
		Gtk::MenuItem::new = 0
		Gtk::MenuItem::new_with_label = 1
	CODE:
	if (label)
		RETVAL = (GtkMenuItem*)(gtk_menu_item_new_with_label(label));
	else
		RETVAL = (GtkMenuItem*)(gtk_menu_item_new());
	OUTPUT:
	RETVAL

void
gtk_menu_item_set_submenu(menu_item, child)
	Gtk::MenuItem	menu_item
	Gtk::Widget	child

void
gtk_menu_item_set_placement(menu_item, placement)
	Gtk::MenuItem	menu_item
	Gtk::SubmenuPlacement	placement

void
gtk_menu_item_configure(menu_item, show_toggle, show_submenu)
	Gtk::MenuItem	menu_item
	bool	show_toggle
	bool	show_submenu

void
gtk_menu_item_remove_submenu (menu_item)
	Gtk::MenuItem   menu_item
	ALIAS:
		Gtk::MenuItem::remove_submenu = 0
		Gtk::MenuItem::select = 1
		Gtk::MenuItem::deselect = 2
		Gtk::MenuItem::activate = 3
		Gtk::MenuItem::right_justify = 4
	CODE:
	switch (ix) {
	case 0: gtk_menu_item_remove_submenu (menu_item); break;
	case 1: gtk_menu_item_select (menu_item); break;
	case 2: gtk_menu_item_deselect (menu_item); break;
	case 3: gtk_menu_item_activate (menu_item); break;
	case 4: gtk_menu_item_right_justify (menu_item); break;
	}

#endif
