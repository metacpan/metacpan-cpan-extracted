
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


MODULE = Gtk::Scale		PACKAGE = Gtk::Scale	PREFIX = gtk_scale_

#ifdef GTK_SCALE

void
gtk_scale_set_digits(self, digits)
	Gtk::Scale	self
	int	digits

void
gtk_scale_set_draw_value(self, draw_value)
	Gtk::Scale	self
	int	draw_value

void
gtk_scale_set_value_pos(self, pos)
	Gtk::Scale	self
	Gtk::PositionType	pos

int
gtk_scale_value_width(self)
	Gtk::Scale	self

void
gtk_scale_draw_value(self)
	Gtk::Scale	self

#endif
