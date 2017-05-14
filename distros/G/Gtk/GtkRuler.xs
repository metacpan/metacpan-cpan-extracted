
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


MODULE = Gtk::Ruler		PACKAGE = Gtk::Ruler	PREFIX = gtk_ruler_

#ifdef GTK_RULER

void
gtk_ruler_set_metric(self, metric)
	Gtk::Ruler	self
	Gtk::MetricType	metric

void
gtk_ruler_set_range(self, lower, upper, position, max_size)
	Gtk::Ruler	self
	double	lower
	double	upper
	double	position
	double	max_size

void
gtk_ruler_draw_ticks(self)
	Gtk::Ruler	self

void
gtk_ruler_draw_pos(self)
	Gtk::Ruler	self

#endif
