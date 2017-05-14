
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



MODULE = Gtk::Fixed		PACKAGE = Gtk::Fixed		PREFIX = gtk_fixed_

#ifdef GTK_FIXED

Gtk::Fixed
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_FIXED(gtk_fixed_new());
	OUTPUT:
	RETVAL

void
gtk_fixed_put(self, widget, x, y)
	Gtk::Fixed	self
	Gtk::Widget	widget
	int	x
	int	y

void
gtk_fixed_move(self, widget, x, y)
	Gtk::Fixed	self
	Gtk::Widget	widget
	int	x
	int	y

#endif