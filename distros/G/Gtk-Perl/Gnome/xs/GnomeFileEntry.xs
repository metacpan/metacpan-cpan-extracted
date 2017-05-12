
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::FileEntry		PACKAGE = Gnome::FileEntry		PREFIX = gnome_file_entry_

#ifdef GNOME_FILE_ENTRY

Gnome::FileEntry_Sink
new(Class, history_id, browse_dialog_title)
	SV *	Class
	char *	history_id
	char *	browse_dialog_title
	CODE:
	RETVAL = (GnomeFileEntry*)(gnome_file_entry_new(history_id, browse_dialog_title));
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gnome_file_entry_gnome_entry(fentry)
	Gnome::FileEntry	fentry

Gtk::Widget_Up
gnome_file_entry_gtk_entry(fentry)
	Gnome::FileEntry	fentry

void
gnome_file_entry_set_title(fentry, browse_dialog_title)
	Gnome::FileEntry	fentry
	char *	browse_dialog_title

void
gnome_file_entry_set_modal (fentry, is_modal)
	Gnome::FileEntry	fentry
	int	is_modal

void
gnome_file_entry_set_directory (fentry, directory_entry)
	Gnome::FileEntry	fentry
	int	directory_entry

void
gnome_file_entry_set_default_path (fentry, path)
	Gnome::FileEntry	fentry
	char *	path

char*
gnome_file_entry_get_full_path (fentry, file_must_exist)
	Gnome::FileEntry	fentry
	int	file_must_exist

Gtk::Widget_Up
fsw (fentry)
	Gnome::FileEntry	fentry
	CODE:
	RETVAL = fentry->fsw;
	OUTPUT:
	RETVAL

#endif

