
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


MODULE = Gtk::VPaned		PACKAGE = Gtk::VPaned	PREFIX = gtk_vpaned_

#ifdef GTK_VPANED

Gtk::VPaned
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_VPANED(gtk_vpaned_new());
	OUTPUT:
	RETVAL

#endif
