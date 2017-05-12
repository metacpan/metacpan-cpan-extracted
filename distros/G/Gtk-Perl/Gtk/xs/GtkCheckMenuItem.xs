
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::CheckMenuItem		PACKAGE = Gtk::CheckMenuItem	PREFIX = gtk_check_menu_item_

#ifdef GTK_CHECK_MENU_ITEM

Gtk::CheckMenuItem_Sink
new(Class, label=0)
	SV *	Class
	char *	label
	ALIAS:
		Gtk::CheckMenuItem::new = 0
		Gtk::CheckMenuItem::new_with_label = 1
	CODE:
	if (!label)
		RETVAL = (GtkCheckMenuItem*)(gtk_check_menu_item_new());
	else
		RETVAL = (GtkCheckMenuItem*)(gtk_check_menu_item_new_with_label(label));
	OUTPUT:
	RETVAL


void
gtk_check_menu_item_set_active(check_menu_item, state)
	Gtk::CheckMenuItem	check_menu_item
	int	state
	ALIAS:
		Gtk::CheckMenuItem::set_state = 1
	CODE:
#if GTK_HVER < 0x010113
	/* DEPRECATED */
	gtk_check_menu_item_set_state(check_menu_item, state);
#else
	gtk_check_menu_item_set_active(check_menu_item, state);
#endif

void
gtk_check_menu_item_toggled(check_menu_item)
	Gtk::CheckMenuItem	check_menu_item

void
gtk_check_menu_item_set_show_toggle(check_menu_item, always)
	Gtk::CheckMenuItem	check_menu_item
	bool	always

int
active(check_menu_item, new_value=0)
	Gtk::CheckMenuItem	check_menu_item
	int	new_value
	CODE:
		RETVAL = check_menu_item->active;
		if (items>1)
			check_menu_item->active = new_value;
	OUTPUT:
	RETVAL


#endif
