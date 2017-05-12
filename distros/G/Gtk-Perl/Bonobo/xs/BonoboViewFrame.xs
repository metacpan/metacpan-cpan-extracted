
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"
#include "GtkDefs.h"

MODULE = Gnome::BonoboViewFrame		PACKAGE = Gnome::BonoboViewFrame		PREFIX = bonobo_view_frame_

#ifdef BONOBO_VIEW_FRAME


Gnome::BonoboViewFrame
bonobo_view_frame_new (Class, client_site, uih)
	SV *	Class
	Gnome::BonoboClientSite	client_site
	CORBA::Object	uih
	CODE:
	RETVAL = bonobo_view_frame_new (client_site, uih);
	OUTPUT:
	RETVAL


void
bonobo_view_frame_bind_to_view (view_frame, view)
	Gnome::BonoboViewFrame	view_frame
	CORBA::Object	view

CORBA::Object
bonobo_view_frame_get_view (view_frame)
	Gnome::BonoboViewFrame	view_frame

Gnome::BonoboClientSite
bonobo_view_frame_get_client_site (view_frame)
	Gnome::BonoboViewFrame	view_frame

Gtk::Widget
bonobo_view_frame_get_wrapper (view_frame)
	Gnome::BonoboViewFrame	view_frame

void
bonobo_view_frame_set_covered (view_frame, covered)
	Gnome::BonoboViewFrame	view_frame
	bool	covered

CORBA::Object
bonobo_view_frame_get_ui_container (view_frame)
	Gnome::BonoboViewFrame	view_frame

void
bonobo_view_frame_view_activate (view_frame)
	Gnome::BonoboViewFrame	view_frame

void
bonobo_view_frame_view_deactivate (view_frame)
	Gnome::BonoboViewFrame	view_frame

void
bonobo_view_frame_set_zoom_factor (view_frame, zoom)
	Gnome::BonoboViewFrame	view_frame
	double	zoom

#endif

