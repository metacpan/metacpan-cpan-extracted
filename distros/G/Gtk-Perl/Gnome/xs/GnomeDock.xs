
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::Dock		PACKAGE = Gnome::Dock		PREFIX = gnome_dock_

#ifdef GNOME_DOCK

Gnome::Dock_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeDock*)(gnome_dock_new());
	OUTPUT:
	RETVAL

void
gnome_dock_allow_floating_items (dock, enable)
	Gnome::Dock	dock
	bool		enable

void
gnome_dock_add_item (dock, item, placement, band_num, position, offset, in_new_band)
	Gnome::Dock	dock
	Gnome::DockItem	item
	Gnome::DockPlacement	placement
	unsigned int	band_num
	int	position
	unsigned int	offset
	bool	in_new_band

void
gnome_dock_add_floating_item (dock, widget, x, y, orientation)
	Gnome::Dock	dock
	Gnome::DockItem	widget
	int	x
	int	y
	Gtk::Orientation	orientation

void
gnome_dock_set_client_area (dock, widget)
	Gnome::Dock	dock
	Gtk::Widget	widget

Gtk::Widget_Up
gnome_dock_get_client_area (dock)
	Gnome::Dock	dock

void
gnome_dock_get_item_by_name (dock, name)
	Gnome::Dock	dock
	char *	name
	PPCODE:
	{
		GnomeDockItem *item;
		guint band, position, offset;
		GnomeDockPlacement placement;

		item = gnome_dock_get_item_by_name (dock, name, &placement, &band, &position, &offset);
		if (GIMME != G_ARRAY) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGnomeDockItem(item)));
		} else {
			EXTEND(sp, 5);
			PUSHs(sv_2mortal(newSVGnomeDockItem(item)));
			PUSHs(sv_2mortal(newSVGnomeDockPlacement(placement)));
			PUSHs(sv_2mortal(newSViv(band)));
			PUSHs(sv_2mortal(newSViv(position)));
			PUSHs(sv_2mortal(newSViv(offset)));
		}
	}

Gnome::DockLayout
gnome_dock_get_layout (dock)
	Gnome::Dock	dock

bool
gnome_dock_add_from_layout (dock, layout)
	Gnome::Dock	dock
	Gnome::DockLayout	layout

#endif

