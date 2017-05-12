
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"
#include "GnomeAppletDefs.h"
#include <applet-widget.h>

static void     callXS (void (*subaddr)(CV* cv), CV *cv, SV **mark) 
{
	int items;
	dSP;
	PUSHMARK (mark);
	(*subaddr)(cv);

	PUTBACK;  /* Forget the return values */
}

MODULE = Gnome::Applet		PACKAGE = Gnome::Applet		PREFIX = applet_

INCLUDE: ../build/boxed.xsh

INCLUDE: ../build/objects.xsh

INCLUDE: ../build/extension.xsh

