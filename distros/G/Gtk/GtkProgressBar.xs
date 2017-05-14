
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



MODULE = Gtk::ProgressBar		PACKAGE = Gtk::ProgressBar		PREFIX = gtk_progress_bar_

#ifdef GTK_PROGRESS_BAR

Gtk::ProgressBar
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_PROGRESS_BAR(gtk_progress_bar_new());
	OUTPUT:
	RETVAL

void
gtk_progress_bar_update(self, percentage)
	Gtk::ProgressBar	self
	double	percentage

double
percentage(self)
	Gtk::ProgressBar	self
	CODE:
	RETVAL = self->percentage;
	OUTPUT:
	RETVAL

#endif
