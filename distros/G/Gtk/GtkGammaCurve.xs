
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



MODULE = Gtk::GammaCurve		PACKAGE = Gtk::GammaCurve	PREFIX = gtk_gamma_curve_

#ifdef GTK_GAMMA_CURVE

Gtk::GammaCurve
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_GAMMA_CURVE(gtk_gamma_curve_new());
	OUTPUT:
	RETVAL

upGtk::Widget
curve(curve)
	Gtk::GammaCurve	curve
	CODE:
	RETVAL = curve->curve;
	OUTPUT:
	RETVAL

#endif
