
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



MODULE = Gtk::EventBox		PACKAGE = Gtk::EventBox	PREFIX = gtk_event_box_

#ifdef GTK_EVENT_BOX

Gtk::EventBox
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_EVENT_BOX(gtk_event_box_new());
	OUTPUT:
	RETVAL

#endif
