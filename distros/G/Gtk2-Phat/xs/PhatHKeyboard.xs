#include "phatperl.h"

MODULE = Gtk2::Phat::HKeyboard	PACKAGE = Gtk2::Phat::HKeyboard	PREFIX = phat_hkeyboard_

PROTOTYPES: DISABLE

GtkWidget *
phat_hkeyboard_new (class, adjustment, numkeys, show_labels)
		GtkAdjustment *adjustment
		int numkeys
		gboolean show_labels
	C_ARGS:
		adjustment, numkeys, show_labels
