
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Alignment		PACKAGE = Gtk::Alignment	PREFIX = gtk_alignment_

#ifdef GTK_ALIGNMENT

Gtk::Alignment_Sink
new(Class, xalign=0.5, yalign=0.5, xscale=1.0, yscale=1.0)
	SV *	Class
	double	xalign
	double	yalign
	double	xscale
	double	yscale
	CODE:
	RETVAL = (GtkAlignment*)(gtk_alignment_new(xalign, yalign, xscale, yscale));
	OUTPUT:
	RETVAL

void
gtk_alignment_set(alignment, xalign, yalign, xscale, yscale)
	Gtk::Alignment	alignment
	double	xalign
	double	yalign
	double	xscale
	double	yscale

#endif
