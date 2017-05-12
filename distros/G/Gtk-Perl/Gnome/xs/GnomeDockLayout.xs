
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::DockLayout		PACKAGE = Gnome::DockLayout		PREFIX = gnome_dock_layout_

#ifdef GNOME_DOCK_LAYOUT

Gnome::DockLayout_Sink
new (Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeDockLayout*)(gnome_dock_layout_new());
	OUTPUT:
	RETVAL

bool
gnome_dock_layout_add_item (layout, item, placement, band_num, band_position, offset)
	Gnome::DockLayout	layout
	Gnome::DockItem	item
	Gnome::DockPlacement	placement
	gint	band_num
	gint	band_position
	gint	offset

bool
gnome_dock_layout_add_floating_item (layout, item, x, y, orientation)
	Gnome::DockLayout	layout
	Gnome::DockItem	item
	int	x
	int	y
	Gtk::Orientation	orientation

bool
gnome_dock_layout_remove_item (layout, item)
	Gnome::DockLayout	layout
	Gnome::DockItem	item

bool
gnome_dock_layout_remove_item_by_name (layout, name)
	Gnome::DockLayout	layout
	char *	name

SV*
gnome_dock_layout_create_string (layout)
	Gnome::DockLayout	layout
	CODE:
	{
		char * ret = gnome_dock_layout_create_string (layout);
		sv_setpv(RETVAL, ret);
		g_free(ret);
	}

bool
gnome_dock_layout_parse_string (layout, string)
	Gnome::DockLayout	layout
	char *	string

bool
gnome_dock_layout_add_to_dock (layout, dock)
	Gnome::DockLayout	layout
	Gnome::Dock	dock

#endif

