
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::VRuler		PACKAGE = Gtk::VRuler	PREFIX = gtk_vruler_

#ifdef GTK_VRULER

Gtk::VRuler_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkVRuler*)(gtk_vruler_new());
	OUTPUT:
	RETVAL

#endif
