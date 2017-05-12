
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Plug		PACKAGE = Gtk::Plug		PREFIX = gtk_plug_

#ifdef GTK_PLUG

Gtk::Plug_Sink
new(Class, socket_id)
	SV *	Class
	int     socket_id
	CODE:
	RETVAL = (GtkPlug*)(gtk_plug_new(socket_id));
	OUTPUT:
	RETVAL

Gtk::Gdk::Window
socket_window(plug)
	Gtk::Plug     plug
	CODE:
		RETVAL = plug->socket_window;
	OUTPUT:
	RETVAL

int
same_app(plug)
	Gtk::Plug     plug
	CODE:
		RETVAL = plug->same_app;
	OUTPUT:
	RETVAL

#endif

