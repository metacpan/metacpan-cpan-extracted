
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::DockBand		PACKAGE = Gnome::DockBand		PREFIX = gnome_dock_band_

#ifdef GNOME_DOCK_BAND

Gnome::DockBand_Sink
new (Class)
	SV *	Class
	CODE:
	RETVAL =  (GnomeDockBand*)(gnome_dock_band_new());
	OUTPUT:
	RETVAL

void
gnome_dock_band_set_orientation (band, orientation)
	Gnome::DockBand	band
	Gtk::Orientation	orientation

Gtk::Orientation
gnome_dock_band_get_orientation (band)
	Gnome::DockBand	band

bool
gnome_dock_band_insert (band, child, offset, position)
	Gnome::DockBand	band
	Gtk::Widget	child
	unsigned int	offset
	int	position

bool
gnome_dock_band_prepend (band, child, offset)
	Gnome::DockBand	band
	Gtk::Widget	child
	unsigned int	offset

bool
gnome_dock_band_append (band, child, offset)
	Gnome::DockBand	band
	Gtk::Widget	child
	unsigned int	offset

void
gnome_dock_band_set_child_offset (band, child, offset)
	Gnome::DockBand	band
	Gtk::Widget	child
	unsigned int	offset

unsigned int
gnome_dock_band_get_child_offset (band, child)
	Gnome::DockBand	band
	Gtk::Widget	child

 ##void
 ##gnome_dock_band_move_child (band, new_num, old_child)
 ##	Gnome::DockBand	band
 ##	GList old_child
 ##	unsigned int new_num

unsigned int
gnome_dock_band_get_num_children (band)
	Gnome::DockBand	band

void
gnome_dock_band_drag_begin (band, item)
	Gnome::DockBand	band
	Gnome::DockItem	item

bool
gnome_dock_band_drag_to (band, item, x, y)
	Gnome::DockBand	band
	Gnome::DockItem	item
	int	x
	int	y

void
gnome_dock_band_get_item_by_name (band, name)
	Gnome::DockBand	band
	char *	name
	PPCODE:
	{
		GnomeDockItem *item;
		guint position, offset;

		item = gnome_dock_band_get_item_by_name (band, name, &position, &offset);
		if (GIMME != G_ARRAY) {
			EXTEND(sp, 1);
			PUSHs(sv_2mortal(newSVGnomeDockItem(item)));
		} else {
			EXTEND(sp, 3);
			PUSHs(sv_2mortal(newSVGnomeDockItem(item)));
			PUSHs(sv_2mortal(newSViv(position)));
			PUSHs(sv_2mortal(newSViv(offset)));
		}
	}


void
gnome_dock_band_layout_add (band, layout, placement, band_num)
	Gnome::DockBand	band
	Gnome::DockLayout	layout
	Gnome::DockPlacement	placement
	unsigned int	band_num


#endif

