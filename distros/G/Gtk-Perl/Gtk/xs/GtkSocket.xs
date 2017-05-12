
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Socket		PACKAGE = Gtk::Socket		PREFIX = gtk_socket_

#ifdef GTK_SOCKET

Gtk::Socket_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkSocket*)(gtk_socket_new());
	OUTPUT:
	RETVAL

void
gtk_socket_steal(socket, wid)
	Gtk::Socket     socket
	int             wid

Gtk::Gdk::Window
plug_window(socket)
	Gtk::Socket     socket
	CODE:
		RETVAL = socket->plug_window;
	OUTPUT:
	RETVAL

int
same_app(socket)
	Gtk::Socket     socket
	CODE:
		RETVAL = socket->same_app;
	OUTPUT:
	RETVAL

#endif

