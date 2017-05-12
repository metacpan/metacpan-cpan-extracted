
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Range		PACKAGE = Gtk::Range	PREFIX = gtk_range_

#ifdef GTK_RANGE

Gtk::Adjustment
gtk_range_get_adjustment(range)
	Gtk::Range	range

void
gtk_range_set_update_policy(range, policy)
	Gtk::Range	range
	Gtk::UpdateType	policy

void
gtk_range_set_adjustment(range, adjustment)
	Gtk::Range	range
	Gtk::Adjustment	adjustment

void
gtk_range_draw_background(range)
	Gtk::Range	range
	ALIAS:
		Gtk::Range::draw_background = 0
		Gtk::Range::draw_trough = 1
		Gtk::Range::draw_slider = 2
		Gtk::Range::draw_step_forw = 3
		Gtk::Range::draw_step_back = 4
		Gtk::Range::slider_update = 5
		Gtk::Range::default_hslider_update = 6
		Gtk::Range::default_vslider_update = 7
		Gtk::Range::clear_background = 8
	CODE:
	switch (ix) {
	case 0: gtk_range_draw_background(range); break;
	case 1: gtk_range_draw_trough(range); break;
	case 2: gtk_range_draw_slider(range); break;
	case 3: gtk_range_draw_step_forw(range); break;
	case 4: gtk_range_draw_step_back(range); break;
	case 5: gtk_range_slider_update(range); break;
	case 6: gtk_range_default_hslider_update(range); break;
	case 7: gtk_range_default_vslider_update(range); break;
	case 8: gtk_range_clear_background(range); break;
	}

void
gtk_range_trough_click(range, x, y, jump_perc=0)
	Gtk::Range	range
	int	x
	int	y
	gfloat	&jump_perc
	OUTPUT:
	jump_perc

void
gtk_range_default_htrough_click(range, x, y, jump_perc=0)
	Gtk::Range	range
	int	x
	int	y
	gfloat &jump_perc
	OUTPUT:
	jump_perc

void
gtk_range_default_vtrough_click(range, x, y, jump_perc=0)
	Gtk::Range	range
	int	x
	int	y
	gfloat &jump_perc
	OUTPUT:
	jump_perc

void
gtk_range_default_hmotion(range, xdelta, ydelta)
	Gtk::Range	range
	int	xdelta
	int	ydelta

void
gtk_range_default_vmotion(range, xdelta, ydelta)
	Gtk::Range	range
	int	xdelta
	int	ydelta

#if 0

double
gtk_range_calc_value(range, position)
	Gtk::Range	range
	int	position

#endif

#endif
