
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::ICE		PACKAGE = Gnome::ICE	PREFIX = gnome_ice_

void
gnome_ice_init(Class)
	CODE:
	gnome_ice_init();


