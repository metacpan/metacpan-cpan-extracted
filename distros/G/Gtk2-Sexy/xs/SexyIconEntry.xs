#include <sexyperl.h>

MODULE = Gtk2::Sexy::IconEntry	PACKAGE = Gtk2::Sexy::IconEntry	PREFIX = sexy_icon_entry_

PROTOTYPES: disable

GtkWidget *
sexy_icon_entry_new (class)
	C_ARGS:

void
sexy_icon_entry_set_icon (entry, position, icon);
		SexyIconEntry *entry
		SexyIconEntryPosition position
		GtkImage *icon

void
sexy_icon_entry_set_icon_highlight (entry, position, highlight)
		SexyIconEntry *entry
		SexyIconEntryPosition position
		gboolean highlight

GtkImage *
sexy_icon_entry_get_icon(entry, position)
		SexyIconEntry *entry
		SexyIconEntryPosition position

gboolean
sexy_icon_entry_get_icon_highlight (entry, position)
		SexyIconEntry *entry
		SexyIconEntryPosition position

void
sexy_icon_entry_add_clear_button (entry)
		SexyIconEntry *entry
