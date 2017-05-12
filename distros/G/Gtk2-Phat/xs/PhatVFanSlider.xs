#include "phatperl.h"

MODULE = Gtk2::Phat::VFanSlider	PACKAGE = Gtk2::Phat::VFanSlider	PREFIX = phat_vfan_slider_

PROTOTYPES: DISABLE

GtkWidget *
phat_vfan_slider_new (class, adjustment)
		GtkAdjustment *adjustment
	C_ARGS:
		adjustment

GtkWidget *
phat_vfan_slider_new_with_range (class, value, lower, upper, step)
		double value
		double lower
		double upper
		double step
	C_ARGS:
		value, lower, upper, step
