
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::AspectFrame		PACKAGE = Gtk::AspectFrame		PREFIX = gtk_aspect_frame_

#ifdef GTK_ASPECT_FRAME

Gtk::AspectFrame_Sink
new(Class, label, xalign=0.5, yalign=0.5, ratio=1.0, obey_child=TRUE)
	SV *	Class
	char *	label
	double	xalign
	double	yalign
	double	ratio
	bool	obey_child
	CODE:
	RETVAL = (GtkAspectFrame*)(gtk_aspect_frame_new(label, xalign, yalign, ratio, obey_child));
	OUTPUT:
	RETVAL

void
gtk_aspect_frame_set(aspect_frame, xalign, yalign, ratio, obey_child)
	Gtk::AspectFrame	aspect_frame
	double	xalign
	double	yalign
	double	ratio
	bool	obey_child

#endif
