
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"

#include "GtkDefs.h"

#ifndef boolSV
# define boolSV(b) ((b) ? &sv_yes : &sv_no)
#endif

MODULE = Gtk::Alignment		PACKAGE = Gtk::Alignment	PREFIX = gtk_alignment_

#ifdef GTK_ALIGNMENT

Gtk::Alignment
new(Class, xalign, yalign, xscale, yscale)
	SV *	Class
	double	xalign
	double	yalign
	double	xscale
	double	yscale
	CODE:
	RETVAL = GTK_ALIGNMENT(gtk_alignment_new(xalign, yalign, xscale, yscale));
	OUTPUT:
	RETVAL

void
gtk_alignment_set(self, xalign, yalign, xscale, yscale)
	Gtk::Alignment	self
	double	xalign
	double	yalign
	double	xscale
	double	yscale

#endif
