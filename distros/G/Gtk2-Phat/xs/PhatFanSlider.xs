#include "phatperl.h"

MODULE = Gtk2::Phat::FanSlider	PACKAGE = Gtk2::Phat::FanSlider	PREFIX = phat_fan_slider_

PROTOTYPES: DISABLE

void
phat_fan_slider_set_value (slider, value)
		PhatFanSlider *slider
		double value

double
phat_fan_slider_get_value (slider)
		PhatFanSlider *slider

void
phat_fan_slider_set_range (slider, lower, upper)
		PhatFanSlider *slider
		double lower
		double upper

void
phat_fan_slider_get_range (PhatFanSlider *slider, OUTLIST double lower, OUTLIST double upper)

void
phat_fan_slider_set_adjustment (slider, adjustment)
		PhatFanSlider *slider
		GtkAdjustment *adjustment

GtkAdjustment *
phat_fan_slider_get_adjustment (slider)
		PhatFanSlider *slider

void
phat_fan_slider_set_inverted (slider, inverted)
		PhatFanSlider *slider
		gboolean inverted

gboolean
phat_fan_slider_get_inverted (slider)
		PhatFanSlider *slider
