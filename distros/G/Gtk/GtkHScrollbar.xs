
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


MODULE = Gtk::HScrollbar		PACKAGE = Gtk::HScrollbar

#ifdef GTK_HSCROLLBAR

Gtk::HScrollbar
new(Class, adjustment)
	SV *	Class
	Gtk::Adjustment	adjustment
	CODE:
	RETVAL = GTK_HSCROLLBAR(gtk_hscrollbar_new(adjustment));
	OUTPUT:
	RETVAL

#endif
