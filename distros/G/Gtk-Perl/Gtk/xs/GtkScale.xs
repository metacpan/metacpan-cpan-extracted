
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Scale		PACKAGE = Gtk::Scale	PREFIX = gtk_scale_

#ifdef GTK_SCALE

void
gtk_scale_set_digits(scale, digits)
	Gtk::Scale	scale
	int	digits

void
gtk_scale_set_draw_value(scale, draw_value)
	Gtk::Scale	scale
	int	draw_value

void
gtk_scale_set_value_pos(scale, pos)
	Gtk::Scale	scale
	Gtk::PositionType	pos

int
gtk_scale_get_value_width(scale)
	Gtk::Scale	scale
	ALIAS:
		Gtk::Scale::value_width = 1
	CODE:
#if GTK_HVER < 0x010106
	RETVAL = gtk_scale_value_width(scale);
#else
	RETVAL = gtk_scale_get_value_width(scale);
#endif
	OUTPUT:
	RETVAL

void
gtk_scale_draw_value(scale)
	Gtk::Scale	scale

#endif
