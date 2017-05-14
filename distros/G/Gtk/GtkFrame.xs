
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



MODULE = Gtk::Frame		PACKAGE = Gtk::Frame		PREFIX = gtk_frame_

#ifdef GTK_FRAME

Gtk::Frame
new(Class, label=0)
	SV *	Class
	char *	label
	CODE:
	RETVAL = GTK_FRAME(gtk_frame_new(label));
	OUTPUT:
	RETVAL

void
gtk_frame_set_label(self, label)
	Gtk::Frame	self
	char *	label

void
gtk_frame_set_label_align(self, xalign, yalign)
	Gtk::Frame	self
	double	xalign
	double	yalign

void
gtk_frame_set_shadow_type(self, shadow)
	Gtk::Frame	self
	Gtk::ShadowType	shadow

#endif
