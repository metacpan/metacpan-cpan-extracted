
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


MODULE = Gtk::HPaned		PACKAGE = Gtk::HPaned	PREFIX = gtk_hpaned_

#ifdef GTK_HPANED

Gtk::HPaned
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_HPANED(gtk_hpaned_new());
	OUTPUT:
	RETVAL

#endif
