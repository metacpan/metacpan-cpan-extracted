
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::VSeparator		PACKAGE = Gtk::VSeparator

#ifdef GTK_VSEPARATOR

Gtk::VSeparator_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkVSeparator*)(gtk_vseparator_new());
	OUTPUT:
	RETVAL

#endif
