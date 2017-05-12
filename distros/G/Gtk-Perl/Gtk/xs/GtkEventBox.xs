
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::EventBox		PACKAGE = Gtk::EventBox	PREFIX = gtk_event_box_

#ifdef GTK_EVENT_BOX

Gtk::EventBox_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkEventBox*)(gtk_event_box_new());
	OUTPUT:
	RETVAL

#endif
