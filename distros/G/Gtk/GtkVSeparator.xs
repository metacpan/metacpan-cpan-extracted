
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


MODULE = Gtk::VSeparator		PACKAGE = Gtk::VSeparator

#ifdef GTK_VSEPARATOR

Gtk::VSeparator
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_VSEPARATOR(gtk_vseparator_new());
	OUTPUT:
	RETVAL

#endif
