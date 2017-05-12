
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::HandleBox		PACKAGE = Gtk::HandleBox	PREFIX = gtk_handle_box_

#ifdef GTK_HANDLE_BOX

Gtk::HandleBox_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkHandleBox*)(gtk_handle_box_new());
	OUTPUT:
	RETVAL

#if GTK_HVER >= 0x01010F

void
gtk_handle_box_set_shadow_type(handlebox, type)
	Gtk::HandleBox	handlebox
	Gtk::ShadowType	type

void
gtk_handle_box_set_handle_position(handlebox, position)
	Gtk::HandleBox	handlebox
	Gtk::PositionType	position

void
gtk_handle_box_set_snap_edge(handlebox, edge)
	Gtk::HandleBox	handlebox
	Gtk::PositionType	edge

#endif


#endif
