
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::HScrollbar		PACKAGE = Gtk::HScrollbar

#ifdef GTK_HSCROLLBAR

Gtk::HScrollbar_Sink
new(Class, adjustment)
	SV *	Class
	Gtk::Adjustment	adjustment
	CODE:
	RETVAL = (GtkHScrollbar*)(gtk_hscrollbar_new(adjustment));
	OUTPUT:
	RETVAL

#endif
