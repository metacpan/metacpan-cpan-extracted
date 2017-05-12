
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Entry		PACKAGE = Gtk::Entry	PREFIX = gtk_entry_

#ifdef GTK_ENTRY

Gtk::Entry_Sink
new(Class, max_length=0)
	SV *	Class
	int	max_length
	ALIAS:
		Gtk::Entry::new = 0
		Gtk::Entry::new_with_max_length = 1
	CODE:
	if (items == 1)
		RETVAL = (GtkEntry*)(gtk_entry_new());
	else
		RETVAL = (GtkEntry*)(gtk_entry_new_with_max_length(max_length));
	OUTPUT:
	RETVAL

void
gtk_entry_set_text(entry, text)
	Gtk::Entry	entry
	char *	text
	ALIAS:
		Gtk::Entry::set_text = 0
		Gtk::Entry::append_text = 1
		Gtk::Entry::prepend_text = 2
	CODE:
	switch (ix) {
	case 0: gtk_entry_set_text(entry, text); break;
	case 1: gtk_entry_append_text(entry, text); break;
	case 2: gtk_entry_prepend_text(entry, text); break;
	}

void
gtk_entry_set_position(entry, position)
	Gtk::Entry	entry
	int	position

char *
gtk_entry_get_text(entry)
	Gtk::Entry	entry

void
gtk_entry_select_region (entry, start=0, end=-1)
	Gtk::Entry  entry
	int start
	int end

void
gtk_entry_set_visibility (entry, visibility=TRUE)
	Gtk::Entry  entry
	bool visibility

void
gtk_entry_set_editable (entry, editable=TRUE)
	Gtk::Entry  entry
	bool editable

void
gtk_entry_set_max_length (entry, max)
	Gtk::Entry  entry
	int max

#endif
