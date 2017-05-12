#include "phatperl.h"

MODULE = Gtk2::Phat::SliderButton	PACKAGE = Gtk2::Phat::SliderButton	PREFIX = phat_slider_button_

PROTOTYPES: DISABLE

GtkWidget *
phat_slider_button_new (class, adjustment, digits)
		GtkAdjustment *adjustment
		int digits
	C_ARGS:
		adjustment, digits

GtkWidget *
phat_slider_button_new_with_range (class, value, lower, upper, step, digits)
		double value
		double lower
		double upper
		double step
		int digits
	C_ARGS:
		value, lower, upper, step, digits

void
phat_slider_button_set_value (button, value)
		PhatSliderButton *button
		double value

double
phat_slider_button_get_value (button)
		PhatSliderButton *button

void
phat_slider_button_set_range (button, lower, upper)
		PhatSliderButton *button
		double lower
		double upper

void
phat_slider_button_get_range (PhatSliderButton *button, OUTLIST double lower, OUTLIST double upper)

void
phat_slider_button_set_adjustment (button, adjustment)
		PhatSliderButton *button
		GtkAdjustment *adjustment

GtkAdjustment *
phat_slider_button_get_adjustment (button)
		PhatSliderButton *button

void
phat_slider_button_set_increment (button, step, page)
		PhatSliderButton *button
		double step
		double page

void
phat_slider_button_get_increment (PhatSliderButton *button, OUTLIST double step, OUTLIST double page)

void
phat_slider_button_set_format (button, digits, prefix, postfix)
		PhatSliderButton *button
		int digits
		const char *prefix
		const char *postfix

void
phat_slider_button_get_format (PhatSliderButton *button, OUTLIST int digits, OUTLIST char *prefix, OUTLIST char *postfix)

void
phat_slider_button_set_threshold (button, threshold)
		PhatSliderButton *button
		guint threshold

int
phat_slider_button_get_threshold (button)
		PhatSliderButton *button
