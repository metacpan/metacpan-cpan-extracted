
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Fixed		PACKAGE = Gtk::Fixed		PREFIX = gtk_fixed_

#ifdef GTK_FIXED

Gtk::Fixed_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkFixed*)(gtk_fixed_new());
	OUTPUT:
	RETVAL

void
gtk_fixed_put(fixed, widget, x, y)
	Gtk::Fixed	fixed
	Gtk::Widget	widget
	int	x
	int	y

void
gtk_fixed_move(fixed, widget, x, y)
	Gtk::Fixed	fixed
	Gtk::Widget	widget
	int	x
	int	y

#endif
