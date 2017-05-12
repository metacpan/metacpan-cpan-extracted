
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGnomeAppletInt.h"

#include "GnomeAppletDefs.h"

MODULE = Gnome::CappletWidget		PACKAGE = Gnome::CappletWidget		PREFIX = capplet_widget_

void
init(Class, app_id, version="")
	SV *    Class
	char *  app_id
	char *	version
	CODE:
	{
		AppletInit_internal(app_id, version, 0);
	}

Gnome::CappletWidget
new(Class)
	SV *	Class
	CODE:
	RETVAL = (CappletWidget*)(capplet_widget_new());
	OUTPUT:
	RETVAL

Gnome::CappletWidget
multi_new(Class, capid)
	SV *	Class
	int	capid
	CODE:
	RETVAL = (CappletWidget*)(capplet_widget_multi_new(capid));
	OUTPUT:
	RETVAL

void
capplet_widget_state_changed (capplet, undoable)
	Gnome::CappletWidget	capplet
	bool	undoable

void
gtk_main (Class)
	SV *	Class
	CODE:
	capplet_gtk_main();


