#include "phatperl.h"

MODULE = Gtk2::Phat::Keyboard	PACKAGE = Gtk2::Phat::Keyboard	PREFIX = phat_keyboard_

PROTOTYPES: DISABLE

GtkAdjustment *
phat_keyboard_get_adjustment (keyboard)
		PhatKeyboard *keyboard

void
phat_keyboard_set_adjustment (keyboard, adjustment)
		PhatKeyboard *keyboard
		GtkAdjustment *adjustment
