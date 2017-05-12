
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::DrawingArea		PACKAGE = Gtk::DrawingArea		PREFIX = gtk_drawing_area_

#ifdef GTK_DRAWING_AREA

Gtk::DrawingArea_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkDrawingArea*)(gtk_drawing_area_new());
	OUTPUT:
	RETVAL

void
gtk_drawing_area_size(darea, width, height)
	Gtk::DrawingArea	darea
	int	width
	int	height

#endif
