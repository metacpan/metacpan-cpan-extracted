
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::ProgressBar11		PACKAGE = Gtk::ProgressBar		PREFIX = gtk_progress_bar_

#ifdef GTK_PROGRESS_BAR

Gtk::ProgressBar_Sink
new_with_adjustment(Class, adjustment)
	SV *	Class
	Gtk::Adjustment	adjustment
	CODE:
	RETVAL = (GtkProgressBar*)(gtk_progress_bar_new_with_adjustment(adjustment));
	OUTPUT:
	RETVAL

void
gtk_progress_bar_set_bar_style(progressbar, style)
	Gtk::ProgressBar	progressbar
	Gtk::ProgressBarStyle	style

void
gtk_progress_bar_set_discrete_blocks(progressbar, blocks)
	Gtk::ProgressBar	progressbar
	int	blocks

void
gtk_progress_bar_set_activity_step(progressbar, step)
	Gtk::ProgressBar	progressbar
	int	step

void
gtk_progress_bar_set_activity_blocks(progressbar, blocks)
	Gtk::ProgressBar	progressbar
	int	blocks

void
gtk_progress_bar_set_orientation(progressbar, orientation)
	Gtk::ProgressBar	progressbar
	Gtk::ProgressBarOrientation	orientation

#endif
