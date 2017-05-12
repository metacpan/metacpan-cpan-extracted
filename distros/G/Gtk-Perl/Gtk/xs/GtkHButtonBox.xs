
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::HButtonBox		PACKAGE = Gtk::HButtonBox		PREFIX = gtk_hbutton_box_

#ifdef GTK_HBUTTON_BOX

Gtk::HButtonBox_Sink
new(Class)
	CODE:
	RETVAL = (GtkHButtonBox*)(gtk_hbutton_box_new());
	OUTPUT:
	RETVAL

int
gtk_hbutton_box_get_spacing_default(Class)
	CODE:
	RETVAL = gtk_hbutton_box_get_spacing_default();
	OUTPUT:
	RETVAL

Gtk::ButtonBoxStyle
gtk_hbutton_box_get_layout_default(Class)
	CODE:
	RETVAL = gtk_hbutton_box_get_layout_default();
	OUTPUT:
	RETVAL

void
gtk_hbutton_box_set_layout_default(Class, layout)
	Gtk::ButtonBoxStyle	layout
	CODE:
	gtk_hbutton_box_set_layout_default(layout);

void
gtk_hbutton_box_set_spacing_default(Class, spacing)
	int	spacing
	CODE:
	gtk_hbutton_box_set_spacing_default(spacing);

#endif
