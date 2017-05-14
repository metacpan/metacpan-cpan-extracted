
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


MODULE = Gtk::HButtonBox		PACKAGE = Gtk::HButtonBox		PREFIX = gtk_hbutton_box_

#ifdef GTK_HBUTTON_BOX

Gtk::HButtonBox
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_HBUTTON_BOX(gtk_hbutton_box_new());
	OUTPUT:
	RETVAL

int
gtk_hbutton_box_get_spacing_default(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_hbutton_box_get_spacing_default();
	OUTPUT:
	RETVAL

int
gtk_hbutton_box_get_layout_default(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_hbutton_box_get_layout_default();
	OUTPUT:
	RETVAL

void
gtk_hbutton_box_set_layout_default(Class, layout)
	SV *	Class
	int	layout
	CODE:
	gtk_hbutton_box_set_layout_default(layout);

void
gtk_hbutton_box_set_spacing_default(Class, spacing)
	SV *	Class
	int	spacing
	CODE:
	gtk_hbutton_box_set_spacing_default(spacing);

#endif
