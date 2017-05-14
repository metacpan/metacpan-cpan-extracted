
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


MODULE = Gtk::Window		PACKAGE = Gtk::Window		PREFIX = gtk_window_

#ifdef GTK_WINDOW

Gtk::Window
new(Class, type=0)
	SV *	Class
	Gtk::WindowType	type
	CODE:
	RETVAL = GTK_WINDOW(gtk_window_new(type));
	OUTPUT:
	RETVAL

void
set_title(self, title)
	Gtk::Window	self
	char *	title
	CODE:
	gtk_window_set_title(self, title);

void
gtk_window_set_wmclass(window, wmclass_name, wmclass_class)
	Gtk::Window window
	char* wmclass_name
	char* wmclass_class

void
gtk_window_set_focus(window, focus)
	Gtk::Window	window
	Gtk::Widget	focus

void
gtk_window_set_default(window, defaultw)
	Gtk::Window	window
	Gtk::Widget	defaultw

void
gtk_window_set_policy(window, allow_shrink, allow_grow, auto_shrink)
	Gtk::Window	window
	int	allow_shrink
	int	allow_grow
	int	auto_shrink

void
gtk_window_add_accelerator_table(window, table)
	Gtk::Window	window
	Gtk::AcceleratorTable	table

void
gtk_window_remove_accelerator_table(window, table)
	Gtk::Window	window
	Gtk::AcceleratorTable	table

void
gtk_window_position(window, position)
	Gtk::Window	window
	Gtk::WindowPosition	position

void
gtk_window_activate_focus(window)
	Gtk::Window window

void
gtk_window_activate_default(window)
	Gtk::Window window
	
#endif
