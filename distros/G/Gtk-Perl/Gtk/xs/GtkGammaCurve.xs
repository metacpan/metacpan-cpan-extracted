
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::GammaCurve		PACKAGE = Gtk::GammaCurve	PREFIX = gtk_gamma_curve_

#ifdef GTK_GAMMA_CURVE

Gtk::GammaCurve_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkGammaCurve*)(gtk_gamma_curve_new());
	OUTPUT:
	RETVAL

Gtk::Widget_Up
curve(curve)
	Gtk::GammaCurve	curve
	CODE:
	RETVAL = curve->curve;
	OUTPUT:
	RETVAL

#endif
