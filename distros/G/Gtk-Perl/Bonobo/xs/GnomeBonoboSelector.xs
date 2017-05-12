
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkExt.h"
#include "PerlGnomeBonoboInt.h"

#include "GnomeBonoboDefs.h"

MODULE = Gnome::BonoboSelector		PACKAGE = Gnome::BonoboSelector		PREFIX = gnome_bonobo_selector_

#ifdef GNOME_BONOBO_SELECTOR

Gnome::BonoboSelector_Sink
new(Class, title, ...)
	SV *	Class
	char *	title
	CODE: 
	{
		char ** interfs = (char**)g_malloc0(sizeof(char*)*(items-1));
		int i;
		for (i=2; i < items; ++i)
			interfs[i-2] = SvPV(ST(i), PL_na);
		interfs[i] = NULL;
		RETVAL = (GnomeBonoboSelector*)(gnome_bonobo_selector_new(title, interfs));
	}
	OUTPUT:
	RETVAL

char *
gnome_bonobo_selector_get_selected_goad_id (selector)
	Gnome::BonoboSelector	selector

char*
select_goad_id(Class, title, ...)
	SV *	Class
	char *	title
	CODE: 
	{
		char ** interfs = (char**)g_malloc0(sizeof(char*)*(items-1));
		int i;
		for (i=2; i < items; ++i)
			interfs[i-2] = SvPV(ST(i), PL_na);
		interfs[i] = NULL;
		RETVAL = gnome_bonobo_select_goad_id(title, interfs);
	}
	OUTPUT:
	RETVAL

#endif

