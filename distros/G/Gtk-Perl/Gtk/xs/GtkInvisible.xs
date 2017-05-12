
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"

MODULE = Gtk::Invisible		PACKAGE = Gtk::Invisible		PREFIX = gtk_invisible_

#ifdef GTK_INVISIBLE

Gtk::Invisible_Sink
new (Class)
	SV *	Class
	CODE:
	RETVAL = (GtkInvisible*)(gtk_invisible_new());
	OUTPUT:
	RETVAL

#endif

