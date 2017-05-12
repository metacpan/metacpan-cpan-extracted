#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::OptionMenu		PACKAGE = Gtk::OptionMenu		PREFIX = gtk_option_menu_

#ifdef GTK_OPTION_MENU

Gtk::OptionMenu_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkOptionMenu*)(gtk_option_menu_new());
	OUTPUT:
	RETVAL

Gtk::Menu_OrNULL
gtk_option_menu_get_menu(optionmenu)
	Gtk::OptionMenu	optionmenu

void
gtk_option_menu_set_menu(optionmenu, menu)
	Gtk::OptionMenu	optionmenu
	Gtk::Menu	menu

void
gtk_option_menu_remove_menu(optionmenu)
	Gtk::OptionMenu	optionmenu

void
gtk_option_menu_set_history(optionmenu, index)
	Gtk::OptionMenu	optionmenu
	int	index

#endif
