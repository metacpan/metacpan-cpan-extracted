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


MODULE = Gtk::OptionMenu		PACKAGE = Gtk::OptionMenu		PREFIX = gtk_option_menu_

#ifdef GTK_OPTION_MENU

Gtk::OptionMenu
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_OPTION_MENU(gtk_option_menu_new());
	OUTPUT:
	RETVAL

void
gtk_option_menu_get_menu(self)
	Gtk::OptionMenu	self

void
gtk_option_menu_set_menu(self, menu)
	Gtk::OptionMenu	self
	Gtk::Widget	menu

void
gtk_option_menu_remove_menu(self)
	Gtk::OptionMenu	self

void
gtk_option_menu_set_history(self, index)
	Gtk::OptionMenu	self
	int	index

#endif
