
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"
#include "GtkDefs.h"

MODULE = Gnome::BonoboControlFrame		PACKAGE = Gnome::BonoboControlFrame		PREFIX = bonobo_control_frame_

#ifdef BONOBO_CONTROL_FRAME

Gnome::BonoboControlFrame
bonobo_control_frame_new (Class, uic)
	SV *	Class
	CORBA::Object	uic
	CODE:
	RETVAL = bonobo_control_frame_new (uic);
	OUTPUT:
	RETVAL

Gtk::Widget
bonobo_control_frame_get_widget (frame)
	Gnome::BonoboControlFrame	frame

void
bonobo_control_frame_set_ui_container (control_frame, uic)
	Gnome::BonoboControlFrame	control_frame
	CORBA::Object	uic

void
bonobo_control_frame_control_activate (control_frame)
	Gnome::BonoboControlFrame	control_frame

void
bonobo_control_frame_control_deactivate (control_frame)
	Gnome::BonoboControlFrame	control_frame

void
bonobo_control_frame_set_autoactivate (control_frame, autoactivate)
	Gnome::BonoboControlFrame	control_frame
	bool	autoactivate

bool
bonobo_control_frame_get_autoactivate (control_frame)
	Gnome::BonoboControlFrame	control_frame

CORBA::Object
bonobo_control_frame_get_control_property_bag (control_frame)
	Gnome::BonoboControlFrame	control_frame
	CODE:
	TRY(RETVAL = bonobo_control_frame_get_control_property_bag (control_frame, &ev));
	OUTPUT:
	RETVAL

void
bonobo_control_frame_set_propbag (control_frame, propbag)
	Gnome::BonoboControlFrame	control_frame
	Gnome::BonoboPropertyBag	propbag

Gnome::BonoboPropertyBag
bonobo_control_frame_get_propbag (control_frame)
	Gnome::BonoboControlFrame	control_frame

void
bonobo_control_frame_control_set_state (control_frame, state)
	Gnome::BonoboControlFrame	control_frame
	Gtk::StateType	state

void
bonobo_control_frame_set_autostate (control_frame, autostate)
	Gnome::BonoboControlFrame	control_frame
	bool	autostate

bool
bonobo_control_frame_get_autostate (control_frame)
	Gnome::BonoboControlFrame	control_frame

void
bonobo_control_frame_bind_to_control (control_frame, control)
	Gnome::BonoboControlFrame	control_frame
	CORBA::Object	control

CORBA::Object
bonobo_control_frame_get_control (control_frame)
	Gnome::BonoboControlFrame	control_frame

CORBA::Object
bonobo_control_frame_get_ui_container (control_frame)
	Gnome::BonoboControlFrame	control_frame

void
bonobo_control_frame_size_request (control_frame)
	Gnome::BonoboControlFrame	control_frame
	PPCODE:
	{
		int	desired_width, desired_height;
		bonobo_control_frame_size_request (control_frame, &desired_width, &desired_height);
		EXTEND(sp, 2);
		PUSHs(sv_2mortal(newSViv(desired_width)));
		PUSHs(sv_2mortal(newSViv(desired_height)));
	}

#endif

