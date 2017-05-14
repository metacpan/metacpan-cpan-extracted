
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


MODULE = Gtk::HSeparator		PACKAGE = Gtk::HSeparator

#ifdef GTK_HSEPARATOR

Gtk::HSeparator
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_HSEPARATOR(gtk_hseparator_new());
	OUTPUT:
	RETVAL

#endif
