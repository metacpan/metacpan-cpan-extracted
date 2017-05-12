
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::Entry		PACKAGE = Gnome::Entry		PREFIX = gnome_entry_

#ifdef GNOME_ENTRY

Gnome::Entry_Sink
new(Class, history_id)
	SV *	Class
	char *	history_id
	CODE:
	RETVAL = (GnomeEntry*)(gnome_entry_new(history_id));
	OUTPUT:
	RETVAL

Gtk::Widget_Up
gnome_entry_gtk_entry(entry)
	Gnome::Entry	entry

void
gnome_entry_set_history_id(entry, history_id)
	Gnome::Entry	entry
	char *	history_id

void
gnome_entry_prepend_history(entry, save, text)
	Gnome::Entry	entry
	int	save
	char *	text

void
gnome_entry_append_history(entry, save, text)
	Gnome::Entry	entry
	int	save
	char *	text

void
gnome_entry_save_history(entry)
	Gnome::Entry	entry

void
gnome_entry_load_history(entry)
	Gnome::Entry	entry

void
gnome_entry_set_max_saved (entry, max_saved)
	Gnome::Entry	entry
	unsigned int	max_saved

#endif

