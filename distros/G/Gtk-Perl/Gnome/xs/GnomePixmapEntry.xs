
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::PixmapEntry		PACKAGE = Gnome::PixmapEntry		PREFIX = gnome_pixmap_entry_

#ifdef GNOME_PIXMAP_ENTRY

Gnome::PixmapEntry_Sink
new (Class, history_id, browse_dialog_title, do_preview)
	SV *	Class
	char *	history_id
	char *	browse_dialog_title
	int	do_preview
	CODE:
	RETVAL = (GnomePixmapEntry*)(gnome_pixmap_entry_new(history_id, browse_dialog_title, do_preview));
	OUTPUT:
	RETVAL

void
gnome_pixmap_entry_set_pixmap_subdir (pentry, subdir)
	Gnome::PixmapEntry	pentry
	char *	subdir

Gtk::Widget_Up
gnome_pixmap_entry_gnome_file_entry (pentry)
	Gnome::PixmapEntry	pentry

Gtk::Widget_Up
gnome_pixmap_entry_gnome_entry (pentry)
	Gnome::PixmapEntry	pentry

Gtk::Widget_Up
gnome_pixmap_entry_gtk_entry (pentry)
	Gnome::PixmapEntry	pentry

void
gnome_pixmap_entry_set_preview (pentry, do_preview)
	Gnome::PixmapEntry	pentry
	int	do_preview

void
gnome_pixmap_entry_set_preview_size (pentry, preview_w, preview_h)
	Gnome::PixmapEntry	pentry
	int	preview_w
	int	preview_h

char*
gnome_pixmap_entry_get_filename (pentry)
	Gnome::PixmapEntry	pentry

#endif

