
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::HPaned		PACKAGE = Gtk::HPaned	PREFIX = gtk_hpaned_

#ifdef GTK_HPANED

Gtk::HPaned_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkHPaned*)(gtk_hpaned_new());
	OUTPUT:
	RETVAL

#endif
