
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"
#include "GtkDefs.h"

typedef void (*BonoboViewVerbFunc)(BonoboView *view, const char *verb_name, void *user_data);


MODULE = Gnome::BonoboView		PACKAGE = Gnome::BonoboView		PREFIX = bonobo_view_

#ifdef BONOBO_VIEW

Gnome::BonoboView
bonobo_view_new (Class, widget)
	SV *	Class
	Gtk::Widget	widget
	CODE:
	RETVAL = bonobo_view_new (widget);
	OUTPUT:
	RETVAL

void
bonobo_view_set_embeddable (view, embeddable)
	Gnome::BonoboView	view
	Gnome::BonoboEmbeddable	embeddable

Gnome::BonoboEmbeddable
bonobo_view_get_embeddable (view)
	Gnome::BonoboView	view

void
bonobo_view_set_view_frame (view, view_frame)
	Gnome::BonoboView	view
	CORBA::Object	view_frame

CORBA::Object
bonobo_view_get_view_frame (view)
	Gnome::BonoboView	view

CORBA::Object
bonobo_view_get_remote_ui_container (view)
	Gnome::BonoboView	view

Gnome::BonoboUIComponent
bonobo_view_get_ui_component (view)
	Gnome::BonoboView	view

void
bonobo_view_activate_notify (view, activated)
	Gnome::BonoboView	view
	bool	activated
						  
#endif

