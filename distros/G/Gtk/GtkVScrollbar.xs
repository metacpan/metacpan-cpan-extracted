
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


MODULE = Gtk::VScrollbar		PACKAGE = Gtk::VScrollbar

#ifdef GTK_VSCROLLBAR

Gtk::VScrollbar
new(Class, adjustment)
	SV *	Class
	Gtk::Adjustment	adjustment
	CODE:
	RETVAL = GTK_VSCROLLBAR(gtk_vscrollbar_new(adjustment));
	OUTPUT:
	RETVAL

#endif
