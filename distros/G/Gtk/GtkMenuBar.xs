
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


MODULE = Gtk::MenuBar		PACKAGE = Gtk::MenuBar		PREFIX = gtk_menu_bar_

#ifdef GTK_MENU_BAR

Gtk::MenuBar
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_MENU_BAR(gtk_menu_bar_new());
	OUTPUT:
	RETVAL

void
gtk_menu_bar_append(self, child)
	Gtk::MenuBar	self
	Gtk::Widget	child

void
gtk_menu_bar_prepend(self, child)
	Gtk::MenuBar	self
	Gtk::Widget	child

void
gtk_menu_bar_insert(self, child, position)
	Gtk::MenuBar	self
	Gtk::Widget	child
	int	position

#endif
