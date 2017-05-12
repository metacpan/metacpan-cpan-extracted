
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::HScale		PACKAGE = Gtk::HScale

#ifdef GTK_HSCALE

Gtk::HScale_Sink
new(Class, adjustment)
	SV *	Class
	Gtk::Adjustment	adjustment
	CODE:
	RETVAL = (GtkHScale*)(gtk_hscale_new(adjustment));
	OUTPUT:
	RETVAL

#endif
