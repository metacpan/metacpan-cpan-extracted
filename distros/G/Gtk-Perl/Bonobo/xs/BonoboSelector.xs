
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"

MODULE = Gnome::BonoboSelector		PACKAGE = Gnome::BonoboSelector		PREFIX = bonobo_selector_

#ifdef BONOBO_SELECTOR

Gnome::BonoboSelector_Sink
bonobo_selector_new (Class, title, interface, ...)
	SV *	Class
	char *	title
	char *	interface
	CODE:
	{
		char **ifaces;
		int i;

		ifaces = malloc(sizeof(char*)*(items-2+1));
		for (i=2; i < items; ++i)
			ifaces[i-2] = SvPV(ST(i), PL_na);

		ifaces[items-2] = NULL;
		RETVAL = bonobo_selector_new (title, ifaces);
		
		if (ifaces)
			free(ifaces);
	}
	OUTPUT:
	RETVAL

char*
bonobo_selector_get_selected_id (selector)
	Gnome::BonoboSelector	selector

char*
bonobo_selector_get_selected_name (selector)
	Gnome::BonoboSelector	selector

char*
bonobo_selector_get_selected_description (selector)
	Gnome::BonoboSelector	selector

#endif

