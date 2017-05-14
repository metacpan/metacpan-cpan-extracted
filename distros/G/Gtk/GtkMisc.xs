
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


MODULE = Gtk::Misc		PACKAGE = Gtk::Misc		PREFIX = gtk_misc_

#ifdef GTK_MISC

void
gtk_misc_set_alignment(self, xalign, yalign)
	Gtk::Misc	self
	double	xalign
	double	yalign

void
gtk_misc_set_padding(self, xpad, ypad)
	Gtk::Misc	self
	double	xpad
	double	ypad

#endif
