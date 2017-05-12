
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::VPaned		PACKAGE = Gtk::VPaned	PREFIX = gtk_vpaned_

#ifdef GTK_VPANED

Gtk::VPaned_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkVPaned*)(gtk_vpaned_new());
	OUTPUT:
	RETVAL

#endif
