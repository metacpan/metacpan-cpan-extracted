#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Box		PACKAGE = Gtk::Box	PREFIX = gtk_box_

#ifdef GTK_BOX

void
gtk_box_pack_start(box, child, expand, fill, padding)
	Gtk::Box	box
	Gtk::Widget	child
	int	expand
	int	fill
	int	padding
	ALIAS:
		Gtk::Box::pack_start = 0
		Gtk::Box::pack_end = 1
	CODE:
	if (ix == 0)
		gtk_box_pack_start(box, child, expand, fill, padding);
	else if (ix == 1)
		gtk_box_pack_end(box, child, expand, fill, padding);

void
gtk_box_pack_start_defaults(box, child)
	Gtk::Box	box
	Gtk::Widget	child
	ALIAS:
		Gtk::Box::pack_start_defaults = 0
		Gtk::Box::pack_end_defaults = 1
	CODE:
	if (ix == 0)
		gtk_box_pack_start_defaults(box, child);
	else if (ix == 1)
		gtk_box_pack_end_defaults(box, child);

void
gtk_box_set_homogeneous(box, homogeneous)
	Gtk::Box	box
	int	homogeneous

void
gtk_box_set_spacing(box, spacing)
	Gtk::Box	box
	int	spacing

void
gtk_box_reorder_child (box, child, pos)
	Gtk::Box    box
	Gtk::Widget child
	int pos

void
gtk_box_query_child_packing (box, child)
	Gtk::Box    box
	Gtk::Widget child
	PREINIT:
	int expand, fill, padding;
	GtkPackType pack_type;
	PPCODE:
		gtk_box_query_child_packing (box, child, &expand, &fill, &padding, &pack_type);
		EXTEND(sp,4);
		PUSHs(sv_2mortal(newSViv(expand)));
		PUSHs(sv_2mortal(newSViv(fill)));
		PUSHs(sv_2mortal(newSViv(padding)));
		PUSHs(sv_2mortal(newSViv(pack_type)));
		

void
gtk_box_set_child_packing (box, child, expand, fill, padding, pack_type)
	Gtk::Box    box
	Gtk::Widget child
	int expand
	int fill
	int padding
	Gtk::PackType pack_type

void
children(box)
	Gtk::Box	box
	PPCODE:
	{
		GList * list;
		if (GIMME != G_ARRAY) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSViv(g_list_length(box->children))));
		} else {
			for(list = box->children; list; list = list->next) {
				EXTEND(sp, 1);
				PUSHs(sv_2mortal(newSVGtkBoxChild((GtkBoxChild*)list->data)));
			}
		}
	}

#endif

MODULE = Gtk::Box		PACKAGE = Gtk::BoxChild	PREFIX = gtk_box_

#ifdef GTK_BOX

Gtk::Widget_Up
widget(child)
	Gtk::BoxChild	child
	CODE:
	RETVAL = child->widget;
	OUTPUT:
	RETVAL

int
padding(child)
	Gtk::BoxChild	child
	ALIAS:
		Gtk::BoxChild::padding = 0
		Gtk::BoxChild::expand = 1
		Gtk::BoxChild::fill = 2
		Gtk::BoxChild::pack = 3
	CODE:
	switch (ix) {
	case 0: RETVAL = child->padding; break;
	case 1: RETVAL = child->expand; break;
	case 2: RETVAL = child->fill; break;
	case 3: RETVAL = child->pack; break;
	}
	OUTPUT:
	RETVAL

#endif
