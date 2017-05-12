
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gtk::Socket		PACKAGE = Gtk::Socket		PREFIX = gtk_socket_

#ifdef GTK_SOCKET

Gtk::Socket_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_SOCKET(gtk_socket_new());
	OUTPUT:
	RETVAL

void
gtk_socket_steal(self, wid)
	Gtk::Socket     self
	int             wid

Gtk::Gdk::Window
plug_window(self)
	Gtk::Socket     self
	CODE:
		RETVAL = self->plug_window;
	OUTPUT:
	RETVAL

int
same_app(self)
	Gtk::Socket     self
	CODE:
		RETVAL = self->same_app;
	OUTPUT:
	RETVAL

#endif

