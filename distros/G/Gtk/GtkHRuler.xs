
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


MODULE = Gtk::HRuler		PACKAGE = Gtk::HRuler

#ifdef GTK_HRULER

Gtk::HRuler
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_HRULER(gtk_hruler_new());
	OUTPUT:
	RETVAL

#endif
