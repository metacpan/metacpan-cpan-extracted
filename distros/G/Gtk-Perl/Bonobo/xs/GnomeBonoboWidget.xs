
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkExt.h"
#include "PerlGnomeBonoboInt.h"

#include "GnomeBonoboDefs.h"

MODULE = Gnome::BonoboWidget		PACKAGE = Gnome::BonoboWidget		PREFIX = gnome_bonobo_widget_

#ifdef GNOME_BONOBO_WIDGET

Gnome::BonoboWidget_Sink
new (Class, desc, uih)
	SV *	Class
	char *	desc
	Gnome::UIHandler	uih
	CODE:
	RETVAL = (GnomeBonoboWidget*)(gnome_bonobo_widget_new(desc, uih));
	OUTPUT:
	RETVAL

#endif

