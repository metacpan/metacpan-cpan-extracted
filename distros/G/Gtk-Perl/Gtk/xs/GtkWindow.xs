
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"


MODULE = Gtk::Window		PACKAGE = Gtk::Window		PREFIX = gtk_window_

#ifdef GTK_WINDOW

 #CONSTRUCTOR: yes
Gtk::Window_Sink
new(Class, type=0)
	SV *	Class
	Gtk::WindowType	type
	CODE:
	RETVAL = (GtkWindow*)(gtk_window_new(type));
	OUTPUT:
	RETVAL

void
set_title(window, title)
	Gtk::Window	window
	char *	title
	CODE:
	gtk_window_set_title(window, title);

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

#if GTK_HVER >= 0x010106

void
gtk_window_set_default_size(window, width, height)
	Gtk::Window	window
	gint	width
	gint	height

#endif

#if GTK_HVER >= 0x010102

void
gtk_window_set_modal(window, modal)
	Gtk::Window	window
	int	modal

#endif


#if GTK_HVER >= 0x010200

void
gtk_window_set_transient_for (window, parent)
	Gtk::Window	window
	Gtk::Window	parent

#endif

void
gtk_window_set_policy(window, allow_shrink, allow_grow, auto_shrink)
	Gtk::Window	window
	int	allow_shrink
	int	allow_grow
	int	auto_shrink

void
set_position(window, position)
	Gtk::Window	window
	Gtk::WindowPosition	position
	ALIAS:
		Gtk::Window::set_position = 0
		Gtk::Window::position = 1
	CODE:
#if GTK_HVER < 0x010106
	/* DEPRECATED */
	gtk_window_position(window, position);
#else
	gtk_window_set_position(window, position);
#endif

void
gtk_window_activate_focus(window)
	Gtk::Window window

void
gtk_window_activate_default(window)
	Gtk::Window window
	
#endif
