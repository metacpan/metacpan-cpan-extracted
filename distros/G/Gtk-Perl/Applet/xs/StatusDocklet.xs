
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomeAppletInt.h"

#include "GnomeAppletDefs.h"
#include "GtkDefs.h"

MODULE = Gnome::StatusDocklet		PACKAGE = Gnome::StatusDocklet		PREFIX = status_docklet_

#ifdef STATUS_DOCKLET

Gnome::StatusDocklet_Sink
status_docklet_new (Class)
	SV *	Class
	CODE:
	RETVAL = (StatusDocklet*)(status_docklet_new ());
	OUTPUT:
	RETVAL

Gnome::StatusDocklet_Sink
status_docklet_new_full (Class, maximum_retries, handle_restarts)
	SV *	Class
	int	maximum_retries
	bool	handle_restarts
	CODE:
	RETVAL = (StatusDocklet*)(status_docklet_new_full (maximum_retries, handle_restarts));
	OUTPUT:
	RETVAL

void
status_docklet_run (docklet)
	Gnome::StatusDocklet	docklet

Gtk::Widget_Up
plug (docklet)
	Gnome::StatusDocklet docklet
	CODE:
	RETVAL = docklet->plug;
	OUTPUT:
	RETVAL

#endif

