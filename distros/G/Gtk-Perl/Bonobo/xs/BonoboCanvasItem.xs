
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"

MODULE = Gnome::BonoboCanvasItem		PACKAGE = Gnome::BonoboCanvasItem		PREFIX = bonobo_canvas_item_

#ifdef BONOBO_CANVAS_ITEM

void
bonobo_canvas_item_set_bounds (item, x1, y1, x2, y2)
	Gnome::BonoboCanvasItem	item
	double	x1
	double	y1
	double	x2
	double	y2

#endif

