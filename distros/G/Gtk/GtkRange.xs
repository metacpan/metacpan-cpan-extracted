
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



MODULE = Gtk::Range		PACKAGE = Gtk::Range	PREFIX = gtk_range_

#ifdef GTK_RANGE

Gtk::Adjustment
gtk_range_get_adjustment(self)
	Gtk::Range	self

void
gtk_range_set_update_policy(self, policy)
	Gtk::Range	self
	Gtk::UpdateType	policy

void
gtk_range_set_adjustment(self, adjustment)
	Gtk::Range	self
	Gtk::Adjustment	adjustment

void
gtk_range_draw_background(self)
	Gtk::Range	self

void
gtk_range_draw_trough(self)
	Gtk::Range	self

void
gtk_range_draw_slider(self)
	Gtk::Range	self

void
gtk_range_draw_step_forw(self)
	Gtk::Range	self

void
gtk_range_draw_step_back(self)
	Gtk::Range	self

void
gtk_range_slider_update(self)
	Gtk::Range	self

void
gtk_range_trough_click(self, x, y, jump_perc=0)
	Gtk::Range	self
	int	x
	int	y
	gfloat	&jump_perc
	OUTPUT:
	jump_perc

void
gtk_range_default_hslider_update(self)
	Gtk::Range	self

void
gtk_range_default_vslider_update(self)
	Gtk::Range	self

void
gtk_range_default_htrough_click(self, x, y, jump_perc=0)
	Gtk::Range	self
	int	x
	int	y
	gfloat &jump_perc
	OUTPUT:
	jump_perc

void
gtk_range_default_vtrough_click(self, x, y, jump_perc=0)
	Gtk::Range	self
	int	x
	int	y
	gfloat &jump_perc
	OUTPUT:
	jump_perc

void
gtk_range_default_hmotion(self, xdelta, ydelta)
	Gtk::Range	self
	int	xdelta
	int	ydelta

void
gtk_range_default_vmotion(self, xdelta, ydelta)
	Gtk::Range	self
	int	xdelta
	int	ydelta

#if 0

double
gtk_range_calc_value(self, position)
	Gtk::Range	self
	int	position

#endif

#endif
