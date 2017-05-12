
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"

MODULE = Gnome::BonoboMoniker		PACKAGE = Gnome::BonoboMoniker		PREFIX = bonobo_moniker_

#ifdef BONOBO_MONIKER

#if 0

CORBA::Object
bonobo_moniker_corba_object_create (object)
	Gnome::BonoboObject	object

#endif

CORBA::Object
bonobo_moniker_get_parent (moniker)
	Gnome::BonoboMoniker	moniker
	CODE:
	TRY(RETVAL = bonobo_moniker_get_parent (moniker, &ev));
	OUTPUT:
	RETVAL

void
bonobo_moniker_set_parent (moniker, parent)
	Gnome::BonoboMoniker	moniker
	CORBA::Object	parent
	CODE:
	TRY(bonobo_moniker_set_parent (moniker, parent, &ev));

char*
bonobo_moniker_get_name (moniker)
	Gnome::BonoboMoniker	moniker

void
bonobo_moniker_set_name (moniker, name)
	Gnome::BonoboMoniker	moniker
	char*	name
	CODE:
	bonobo_moniker_set_name (moniker, name, strlen(name));

CORBA::Object
bonobo_moniker_client_new_from_name (Class, name)
	SV *	Class
	char *	name
	CODE:
	TRY(RETVAL = bonobo_moniker_client_new_from_name (name, &ev));
	OUTPUT:
	RETVAL

#endif

