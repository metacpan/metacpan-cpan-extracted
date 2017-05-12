#include "phatperl.h"

MODULE = Gtk2::Phat::VKeyboard	PACKAGE = Gtk2::Phat::VKeyboard	PREFIX = phat_vkeyboard_

PROTOTYPES: DISABLE

GtkWidget *
phat_vkeyboard_new (class, adjustment, numkeys, show_labels)
		GtkAdjustment *adjustment
		int numkeys
		gboolean show_labels
	C_ARGS:
		adjustment, numkeys, show_labels
