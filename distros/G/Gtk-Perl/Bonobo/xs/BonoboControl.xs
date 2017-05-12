
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"
#include "GtkDefs.h"

MODULE = Gnome::BonoboControl		PACKAGE = Gnome::BonoboControl		PREFIX = bonobo_control_

#ifdef BONOBO_CONTROL

Gnome::BonoboControl
bonobo_control_new (Class, widget)
	SV *	Class
	Gtk::Widget	widget
	CODE:
	RETVAL = bonobo_control_new (widget);
	OUTPUT:
	RETVAL

Gtk::Widget
bonobo_control_get_widget (control)
	Gnome::BonoboControl	control

void
bonobo_control_set_automerge (control, automerge)
	Gnome::BonoboControl	control
	bool	automerge

bool
bonobo_control_get_automerge (control)
	Gnome::BonoboControl	control

#if 0

void
bonobo_control_set_property (control, first_prop)
	Gnome::BonoboControl	control
	char *	first_prop

void
bonobo_control_get_property (control, first_prop)
	Gnome::BonoboControl	control
	char *	first_prop

#endif

Gnome::BonoboUIComponent
bonobo_control_get_ui_component (control)
	Gnome::BonoboControl	control

void
bonobo_control_set_ui_component (control, component)
	Gnome::BonoboControl	control
	Gnome::BonoboUIComponent	component

CORBA::Object
bonobo_control_get_remote_ui_container (control)
	Gnome::BonoboControl	control

void
bonobo_control_set_control_frame (control, control_frame)
	Gnome::BonoboControl	control
	CORBA::Object	control_frame

CORBA::Object
bonobo_control_get_control_frame (control)
	Gnome::BonoboControl	control

void
bonobo_control_set_properties (control, pb)
	Gnome::BonoboControl	control
	Gnome::BonoboPropertyBag	pb

Gnome::BonoboPropertyBag
bonobo_control_get_properties (control)
	Gnome::BonoboControl	control

CORBA::Object
bonobo_control_get_ambient_properties (control)
	Gnome::BonoboControl	control
	CODE:
	TRY(RETVAL = bonobo_control_get_ambient_properties (control, &ev));
	OUTPUT:
	RETVAL

void
bonobo_control_activate_notify (control, activated)
	Gnome::BonoboControl	control
	bool	activated

#endif

