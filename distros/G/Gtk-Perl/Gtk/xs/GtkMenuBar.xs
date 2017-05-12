
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::MenuBar		PACKAGE = Gtk::MenuBar		PREFIX = gtk_menu_bar_

#ifdef GTK_MENU_BAR

Gtk::MenuBar_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkMenuBar*)(gtk_menu_bar_new());
	OUTPUT:
	RETVAL

void
gtk_menu_bar_append(menubar, child)
	Gtk::MenuBar	menubar
	Gtk::Widget	child
	ALIAS:
		Gtk::MenuBar::append = 0
		Gtk::MenuBar::prepend = 1
	CODE:
	if (ix == 0)
		gtk_menu_bar_append(menubar, child);
	else if (ix == 1)
		gtk_menu_bar_prepend(menubar, child);

void
gtk_menu_bar_insert(menubar, child, position)
	Gtk::MenuBar	menubar
	Gtk::Widget	child
	int	position

# if GTK_HVER >= 0x010105

void
gtk_menu_bar_set_shadow_type (menubar, type)
	Gtk::MenuBar	menubar
	Gtk::ShadowType	type
	
#endif

#endif
