
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"
#include "GdkImlibTypes.h"


MODULE = Gnome::IconList		PACKAGE = Gnome::IconList		PREFIX = gnome_icon_list_

#ifdef GNOME_ICON_LIST

Gnome::IconList_Sink
new(Class, icon_width, adj, is_editable)
	SV*	Class
	guint	icon_width
	Gtk::Adjustment_OrNULL	adj
	bool	is_editable
	CODE:
	RETVAL = (GnomeIconList*)(gnome_icon_list_new(icon_width, adj, is_editable));
	OUTPUT:
	RETVAL

Gnome::IconList_Sink
new_flags(Class, icon_width, adj, flags)
	SV*	Class
	guint	icon_width
	Gtk::Adjustment_OrNULL	adj
	Gnome::IconListMode	flags
	CODE:
	RETVAL = (GnomeIconList*)(gnome_icon_list_new_flags(icon_width, adj, flags));
	OUTPUT:
	RETVAL

void
gnome_icon_list_set_hadjustment (gil, adj)
	Gnome::IconList	gil
	Gtk::Adjustment_OrNULL	adj

void
gnome_icon_list_set_vadjustment (gil, adj)
	Gnome::IconList	gil
	Gtk::Adjustment_OrNULL	adj

void
gnome_icon_list_freeze (gil)
	Gnome::IconList	gil

void
gnome_icon_list_thaw (gil)
	Gnome::IconList	gil

void
gnome_icon_list_insert (gil, pos, icon_filename, text)
	Gnome::IconList	gil
	int	pos
	char*	icon_filename
	char*	text

void
gnome_icon_list_insert_imlib (gil, pos, im, text)
	Gnome::IconList	gil
	int	pos
	Gtk::Gdk::ImlibImage	im
	char*	text

int
gnome_icon_list_append(gil, icon_filename, text)
	Gnome::IconList	gil
	char*	icon_filename
	char*	text

int
gnome_icon_list_append_imlib (gil, im, text)
	Gnome::IconList	gil
	Gtk::Gdk::ImlibImage	im
	char*	text

void
gnome_icon_list_clear (gil)
	Gnome::IconList	gil

void
gnome_icon_list_remove (gil, pos)
	Gnome::IconList	gil
	int	pos

void
gnome_icon_list_set_selection_mode (gil, mode)
	Gnome::IconList	gil
	Gtk::SelectionMode	mode

void
gnome_icon_list_select_icon (gil, idx)
	Gnome::IconList	gil
	int	idx

void
gnome_icon_list_unselect_icon (gil, idx)
	Gnome::IconList	gil
	int	idx

# missing gnome_icon_list_unselect_all

void
gnome_icon_list_set_icon_width (gil, width)
	Gnome::IconList	gil
	int	width

void
gnome_icon_list_set_row_spacing (gil, pixels)
	Gnome::IconList	gil
	int	pixels

void
gnome_icon_list_set_col_spacing (gil, pixels)
	Gnome::IconList	gil
	int	pixels

void
gnome_icon_list_set_text_spacing (gil, pixels)
	Gnome::IconList	gil
	int	pixels

void
gnome_icon_list_set_icon_border (gil, pixels)
	Gnome::IconList	gil
	int	pixels

void
gnome_icon_list_set_separators (gil, sep)
	Gnome::IconList	gil
	char*	sep

# missing set_data stuff

void
gnome_icon_list_moveto (gil, pos, yalign)
	Gnome::IconList	gil
	int	pos
	double	yalign

Gtk::Visibility
gnome_icon_list_icon_is_visible (gil, pos)
	Gnome::IconList	gil
	int	pos

int
gnome_icon_list_get_icon_at (gil, x, y)
	Gnome::IconList	gil
	int	x
	int	y

int
gnome_icon_list_get_items_per_line (gil)
	Gnome::IconList	gil



#endif

