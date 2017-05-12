
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlBonoboInt.h"

#include "BonoboDefs.h"
#include "GtkDefs.h"
#include "GnomeDefs.h"

MODULE = Gnome::BonoboCanvasComponent		PACKAGE = Gnome::BonoboCanvasComponent		PREFIX = bonobo_canvas_component_

#ifdef BONOBO_CANVAS_COMPONENT

Gnome::BonoboCanvasComponent
bonobo_canvas_component_construct (comp, item)
	Gnome::BonoboCanvasComponent	comp
	Gnome::CanvasItem	item

Gnome::BonoboCanvasComponent
bonobo_canvas_component_new (Class, item)
	SV *	Class
	Gnome::CanvasItem	item
	CODE:
	RETVAL = bonobo_canvas_component_new (item);
	OUTPUT:
	RETVAL

Gnome::CanvasItem
bonobo_canvas_component_get_item (comp)
	Gnome::BonoboCanvasComponent	comp

void
bonobo_canvas_component_grab (comp, mask, cursor, time)
	Gnome::BonoboCanvasComponent	comp
	guint	mask
	Gtk::Gdk::Cursor	cursor
	guint32	time

void
bonobo_canvas_component_ungrab (comp, time)
	Gnome::BonoboCanvasComponent	comp
	guint32	time

CORBA::Object
bonobo_canvas_component_get_ui_container (comp)
	Gnome::BonoboCanvasComponent	comp

#endif

