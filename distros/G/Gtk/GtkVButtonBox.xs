
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


MODULE = Gtk::VButtonBox		PACKAGE = Gtk::VButtonBox		PREFIX = gtk_vbutton_box_

#ifdef GTK_VBUTTON_BOX

Gtk::VButtonBox
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_VBUTTON_BOX(gtk_vbutton_box_new());
	OUTPUT:
	RETVAL

int
gtk_vbutton_box_get_spacing_default(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_vbutton_box_get_spacing_default();
	OUTPUT:
	RETVAL

int
gtk_vbutton_box_get_layout_default(Class)
	SV *	Class
	CODE:
	RETVAL = gtk_vbutton_box_get_layout_default();
	OUTPUT:
	RETVAL

void
gtk_vbutton_box_set_spacing_default(Class, spacing)
	SV *	Class
	int		spacing
	CODE:
	gtk_vbutton_box_set_spacing_default(spacing);

void
gtk_vbutton_box_set_layout_default(Class, layout)
	SV *	Class
	int		layout
	CODE:
	gtk_vbutton_box_set_layout_default(layout);

#endif
