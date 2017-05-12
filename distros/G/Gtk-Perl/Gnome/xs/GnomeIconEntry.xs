
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::IconEntry		PACKAGE = Gnome::IconEntry		PREFIX = gnome_icon_entry_

#ifdef GNOME_ICON_ENTRY

Gnome::IconEntry_Sink
new (Class, history_id, browse_dialog_title)
	SV *	Class
	char *	history_id
	char *	browse_dialog_title
	CODE:
	RETVAL = (GnomeIconEntry*)(gnome_icon_entry_new(history_id, browse_dialog_title));
	OUTPUT:
	RETVAL

void
gnome_icon_entry_set_pixmap_subdir (ientry, subdir)
	Gnome::IconEntry	ientry
	char *	subdir

void
gnome_icon_entry_set_icon (ientry, filename)
	Gnome::IconEntry	ientry
	char *	filename

Gtk::Widget_Up
gnome_icon_entry_gnome_file_entry (ientry)
	Gnome::IconEntry	ientry

Gtk::Widget_Up
gnome_icon_entry_gnome_entry (ientry)
	Gnome::IconEntry	ientry

Gtk::Widget_Up
gnome_icon_entry_gtk_entry (ientry)
	Gnome::IconEntry	ientry

char*
gnome_icon_entry_get_filename (ientry)
	Gnome::IconEntry	ientry

#endif

