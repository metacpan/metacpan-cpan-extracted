
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::PropertyBox		PACKAGE = Gnome::PropertyBox		PREFIX = gnome_property_box_

#ifdef GNOME_PROPERTY_BOX

Gnome::PropertyBox_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GnomePropertyBox*)(gnome_property_box_new());
	OUTPUT:
	RETVAL

void
gnome_property_box_changed(box)
	Gnome::PropertyBox	box

void
gnome_property_box_append_page(box, child, tab_label)
	Gnome::PropertyBox	box
	Gtk::Widget	child
	Gtk::Widget	tab_label

void
gnome_property_box_set_modified (box, state)
	Gnome::PropertyBox	box
	bool	state

Gtk::Widget_Up
notebook (box)
	Gnome::PropertyBox	box
	CODE:
	RETVAL = box->notebook;
	OUTPUT:
	RETVAL

#endif

