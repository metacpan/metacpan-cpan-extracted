
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gtk::Plug		PACKAGE = Gtk::Plug		PREFIX = gtk_plug_

#ifdef GTK_PLUG

Gtk::Plug_Sink
new(Class, socket_id)
	SV *	Class
	int     socket_id
	CODE:
	RETVAL = GTK_PLUG(gtk_plug_new(socket_id));
	OUTPUT:
	RETVAL

Gtk::Gdk::Window
socket_window(self)
	Gtk::Plug     self
	CODE:
		RETVAL = self->socket_window;
	OUTPUT:
	RETVAL

int
same_app(self)
	Gtk::Plug     self
	CODE:
		RETVAL = self->same_app;
	OUTPUT:
	RETVAL

#endif

