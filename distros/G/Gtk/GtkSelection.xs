
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


MODULE = Gtk::Selection		PACKAGE = Gtk::Selection	PREFIX = gtk_selection_

#ifdef GTK_SELECTION

int
gtk_selection_owner_set(Class, widget, atom, time)
	SV *	Class
	Gtk::Widget	widget
	Gtk::Gdk::Atom	atom
	int	time
	CODE:
	RETVAL = gtk_selection_owner_set(widget, atom, time);
	OUTPUT:
	RETVAL

#endif
