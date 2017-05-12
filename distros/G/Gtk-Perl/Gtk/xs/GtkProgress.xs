
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Progress		PACKAGE = Gtk::Progress		PREFIX = gtk_progress_

#ifdef GTK_PROGRESS

void
gtk_progress_set_show_text(progress, show_text)
	Gtk::Progress	progress
	gint	show_text

void
gtk_progress_set_text_alignment(progress, x_align, y_align)
	Gtk::Progress	progress
	gfloat	x_align
	gfloat	y_align

void
gtk_progress_set_format_string(progress, format)
	Gtk::Progress	progress
	char *	format

void
gtk_progress_set_adjustment(progress, adjustment)
	Gtk::Progress	progress
	Gtk::Adjustment	adjustment

# FIXME: DEPRECATED? 

void
gtk_progress_reconfigure(progress, value, min, max)
	Gtk::Progress	progress
	gfloat	value
	gfloat	min
	gfloat	max
	ALIAS:
		Gtk::Progress::configure = 0
		Gtk::Progress::reconfigure = 1
	CODE:
#if (GTK_HVER < 0x010100) || (GTK_HVER > 0x010105)
	gtk_progress_configure(progress, value, min, max);
#else
	gtk_progress_reconfigure(progress, value, min, max);
#endif

void
gtk_progress_set_percentage(progress, percentage)
	Gtk::Progress	progress
	gfloat	percentage

void
gtk_progress_set_value(progress, value)
	Gtk::Progress	progress
	gfloat	value

gfloat
gtk_progress_get_value(progress)
	Gtk::Progress	progress

void
gtk_progress_set_activity_mode(progress, activity_mode)
	Gtk::Progress	progress
	guint	activity_mode

char *
gtk_progress_get_current_text(progress)
	Gtk::Progress	progress

char *
gtk_progress_get_text_from_value(progress, value)
	Gtk::Progress	progress
	gfloat	value

gfloat
gtk_progress_get_current_percentage(progress)
	Gtk::Progress	progress

void
gtk_progress_get_percentage_from_value(progress, value)
	Gtk::Progress	progress
	gfloat	value

#endif
