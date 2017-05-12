
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"

MODULE = Gnome::BonoboObjectClient		PACKAGE = Gnome::BonoboObjectClient		PREFIX = bonobo_object_client_

#ifdef BONOBO_OBJECT_CLIENT

Gnome::BonoboObjectClient
bonobo_object_client_from_corba (Class, unknown)
	SV *	Class
	CORBA::Object	unknown
	CODE:
	RETVAL = bonobo_object_client_from_corba (unknown);
	OUTPUT:
	RETVAL

Gnome::BonoboObjectClient
bonobo_object_activate (Class, iid, flags)
	SV *	Class
	char *	iid
	int	flags
	CODE:
	RETVAL = bonobo_object_activate (iid, flags);
	OUTPUT:
	RETVAL

gboolean
bonobo_object_client_has_interface (object, interface_desc)
	Gnome::BonoboObjectClient	object
	char *	interface_desc
	CODE:
	TRY(RETVAL = bonobo_object_client_has_interface (object, interface_desc, &ev));
	OUTPUT:
	RETVAL

#endif

