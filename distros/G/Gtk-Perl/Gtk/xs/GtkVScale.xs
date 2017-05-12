
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::VScale		PACKAGE = Gtk::VScale

#ifdef GTK_VSCALE

Gtk::VScale_Sink
new(Class, adjustment)
	SV *	Class
	Gtk::Adjustment	adjustment
	CODE:
	RETVAL = (GtkVScale*)(gtk_vscale_new(adjustment));
	OUTPUT:
	RETVAL

#endif
