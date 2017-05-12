
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::HSeparator		PACKAGE = Gtk::HSeparator

#ifdef GTK_HSEPARATOR

Gtk::HSeparator_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkHSeparator*)(gtk_hseparator_new());
	OUTPUT:
	RETVAL

#endif
