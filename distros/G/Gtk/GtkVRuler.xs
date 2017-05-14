
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


MODULE = Gtk::VRuler		PACKAGE = Gtk::VRuler	PREFIX = gtk_vruler_

#ifdef GTK_VRULER

Gtk::VRuler
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_VRULER(gtk_vruler_new());
	OUTPUT:
	RETVAL

#endif
