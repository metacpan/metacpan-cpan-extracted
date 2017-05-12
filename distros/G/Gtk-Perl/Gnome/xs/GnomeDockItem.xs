
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::DockItem		PACKAGE = Gnome::DockItem		PREFIX = gnome_dock_item_

#ifdef GNOME_DOCK_ITEM


Gnome::DockItem_Sink
new (Class, name, behavior)
	SV *	Class
	char *	name
	Gnome::DockItemBehavior behavior
	CODE:
	RETVAL = (GnomeDockItem*)(gnome_dock_item_new(name, behavior));
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gnome_dock_item_get_child (dock_item)
	Gnome::DockItem	dock_item

char*
gnome_dock_item_get_name (dock_item)
	Gnome::DockItem	dock_item

void
gnome_dock_item_set_shadow_type (dock_item, type)
	Gnome::DockItem	dock_item
	Gtk::ShadowType	type

Gtk::ShadowType
gnome_dock_item_get_shadow_type (dock_item)
	Gnome::DockItem	dock_item

bool
gnome_dock_item_set_orientation (dock_item, orientation)
	Gnome::DockItem	dock_item
	Gtk::Orientation	orientation

Gtk::Orientation
gnome_dock_item_get_orientation (dock_item)
	Gnome::DockItem	dock_item

Gnome::DockItemBehavior
gnome_dock_item_get_behavior (dock_item)
	Gnome::DockItem	dock_item


#endif

