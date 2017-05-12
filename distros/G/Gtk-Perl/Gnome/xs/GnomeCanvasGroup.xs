
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::CanvasGroup		PACKAGE = Gnome::CanvasGroup		PREFIX = gnome_canvas_group_

#ifdef GNOME_CANVAS_GROUP

void
gnome_canvas_group_child_bounds(self, item)
	Gnome::CanvasGroup	self
	Gnome::CanvasItem_OrNULL	item

#endif

