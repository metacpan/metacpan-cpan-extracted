
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Misc		PACKAGE = Gtk::Misc		PREFIX = gtk_misc_

#ifdef GTK_MISC

void
gtk_misc_set_alignment(misc, xalign, yalign)
	Gtk::Misc	misc
	double	xalign
	double	yalign

void
gtk_misc_set_padding(misc, xpad, ypad)
	Gtk::Misc	misc
	double	xpad
	double	ypad

#endif
