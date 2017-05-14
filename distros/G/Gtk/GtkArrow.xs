
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


MODULE = Gtk::Arrow		PACKAGE = Gtk::Arrow		PREFIX = gtk_arrow_

#ifdef GTK_ARROW

Gtk::Arrow
new(Class, arrow_type, shadow_type)
	SV *	Class
	Gtk::ArrowType	arrow_type
	Gtk::ShadowType	shadow_type
	CODE:
	RETVAL = GTK_ARROW(gtk_arrow_new(arrow_type, shadow_type));
	OUTPUT:
	RETVAL

void
gtk_arrow_set(arrow, arrow_type, shadow_type)
	Gtk::Arrow	arrow
	Gtk::ArrowType	arrow_type
	Gtk::ShadowType	shadow_type

#endif
