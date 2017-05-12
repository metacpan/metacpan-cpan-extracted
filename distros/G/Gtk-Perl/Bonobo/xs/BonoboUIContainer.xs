
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"

MODULE = Gnome::BonoboUIContainer		PACKAGE = Gnome::BonoboUIContainer		PREFIX = bonobo_ui_container_

#ifdef BONOBO_UI_CONTAINER

Gnome::BonoboUIContainer
bonobo_ui_container_new (Class)
	SV *	Class
	CODE:
	RETVAL = bonobo_ui_container_new();
	OUTPUT:
	RETVAL

void
bonobo_ui_container_set_win (container, win)
	Gnome::BonoboUIContainer	container
	Gnome::BonoboWindow	win


#endif

