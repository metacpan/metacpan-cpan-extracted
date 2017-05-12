
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkExt.h"
#include "PerlGnomeBonoboInt.h"

#include "GnomeBonoboDefs.h"

MODULE = Gnome::BonoboItem		PACKAGE = Gnome::BonoboItem		PREFIX = gnome_bonobo_item_

#ifdef GNOME_BONOBO_ITEM

Gnome::BonoboItem_Sink
new(Class, parent, embeddable)
	SV *	Class
	Gnome::CanvasGroup	parent
	Gnome::ObjectClient	embeddable
	CODE:
	RETVAL = (BonoboItem*)(gnome_bonobo_item_new(parent, embeddable));
	OUTPUT:
	RETVAL

#endif

