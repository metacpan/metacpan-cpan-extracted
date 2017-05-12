
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::VButtonBox		PACKAGE = Gtk::VButtonBox		PREFIX = gtk_vbutton_box_

#ifdef GTK_VBUTTON_BOX

Gtk::VButtonBox_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkVButtonBox*)(gtk_vbutton_box_new());
	OUTPUT:
	RETVAL

int
gtk_vbutton_box_get_spacing_default(Class)
	CODE:
	RETVAL = gtk_vbutton_box_get_spacing_default();
	OUTPUT:
	RETVAL

Gtk::ButtonBoxStyle
gtk_vbutton_box_get_layout_default(Class)
	CODE:
	RETVAL = gtk_vbutton_box_get_layout_default();
	OUTPUT:
	RETVAL

void
gtk_vbutton_box_set_spacing_default(Class, spacing)
	int		spacing
	CODE:
	gtk_vbutton_box_set_spacing_default(spacing);

void
gtk_vbutton_box_set_layout_default(Class, layout)
	Gtk::ButtonBoxStyle		layout
	CODE:
	gtk_vbutton_box_set_layout_default(layout);

#endif
