
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::IconSelection		PACKAGE = Gnome::IconSelection		PREFIX = gnome_icon_selection_

#ifdef GNOME_ICON_SELECTION

Gnome::IconSelection_Sink
new (Class)
	SV *	Class
	CODE:
	RETVAL = (GnomeIconSelection*)(gnome_icon_selection_new());
	OUTPUT:
	RETVAL

void
gnome_icon_selection_add_defaults (gis)
	Gnome::IconSelection	gis

void
gnome_icon_selection_add_directory (gis, dir)
	Gnome::IconSelection	gis
	char *	dir

void
gnome_icon_selection_show_icons (gis)
	Gnome::IconSelection	gis

void
gnome_icon_selection_clear (gis, non_shown)
	Gnome::IconSelection	gis
	bool	non_shown

char*
gnome_icon_selection_get_icon (gis, full_path)
	Gnome::IconSelection	gis
	bool full_path

void
gnome_icon_selection_select_icon (gis, filename)
	Gnome::IconSelection	gis
	char *	filename

void
gnome_icon_selection_stop_loading (gis)
	Gnome::IconSelection	gis

#endif

