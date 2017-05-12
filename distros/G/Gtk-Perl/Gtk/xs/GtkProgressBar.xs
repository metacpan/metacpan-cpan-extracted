
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::ProgressBar		PACKAGE = Gtk::ProgressBar		PREFIX = gtk_progress_bar_

#ifdef GTK_PROGRESS_BAR

Gtk::ProgressBar_Sink
new(Class)
	CODE:
	RETVAL = (GtkProgressBar*)(gtk_progress_bar_new());
	OUTPUT:
	RETVAL

void
gtk_progress_bar_update(progressbar, percentage)
	Gtk::ProgressBar	progressbar
	double	percentage

# FIXME: DEPRECATED?

double
percentage(progressbar)
	Gtk::ProgressBar	progressbar
	CODE:
#if GTK_HVER < 0x010100	
	RETVAL = progressbar->percentage;
#else
	RETVAL = gtk_progress_get_current_percentage(GTK_PROGRESS(progressbar));
#endif
	OUTPUT:
	RETVAL

#endif
