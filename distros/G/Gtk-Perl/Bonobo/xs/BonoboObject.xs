
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"

MODULE = Gnome::BonoboObject		PACKAGE = Gnome::BonoboObject		PREFIX = bonobo_object_

#ifdef BONOBO_OBJECT

void
bonobo_object_add_interface (object, newobj)
	Gnome::BonoboObject	object
	Gnome::BonoboObject	newobj

void
bonobo_object_add_interface_obj (object, newobj)
	Gnome::BonoboObject	object
	CORBA::Object	newobj
	CODE:
	{
		BonoboObjectClient * newobj = bonobo_object_client_from_corba (newobj);
		bonobo_object_add_interface (object, newobj);
	}

Gnome::BonoboObject
bonobo_object_query_local_interface (object, repo_id)
	Gnome::BonoboObject	object
	char *	repo_id

CORBA::Object
bonobo_object_query_interface (object, repo_id)
	Gnome::BonoboObject	object
	char *	repo_id

CORBA::Object
bonobo_object_corba_objref (object)
	Gnome::BonoboObject	object


void
bonobo_object_ref (object)
	Gnome::BonoboObject	object

void
bonobo_object_idle_unref (object)
	Gnome::BonoboObject	object

void
bonobo_object_unref (object)
	Gnome::BonoboObject	object

#endif

