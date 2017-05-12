
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Editable		PACKAGE = Gtk::Editable		PREFIX = gtk_editable_

#ifdef GTK_EDITABLE

void
gtk_editable_select_region (editable, start=0, end=-1)
	Gtk::Editable editable
	int           start
	int           end

int
gtk_editable_insert_text (editable, new_text, position=-1)
	Gtk::Editable editable
	SV*           new_text
	int           position
	CODE:
	{
		STRLEN len;
		char * c = SvPV(new_text, len);
#if GTK_HVER < 0x010000

		/* FIXME: Do later versions correctly insert text in unrealized text widgets? */

		if (!GTK_WIDGET_REALIZED(GTK_WIDGET(editable)))
			gtk_widget_realize(GTK_WIDGET(editable));
#endif
		if (position < 0) {
			if (GTK_IS_ENTRY(editable))
				position = GTK_ENTRY(editable)->text_length;
			else if (GTK_IS_TEXT(editable))
				position = gtk_text_get_length(GTK_TEXT(editable));
			else
				warn("Expicitly set position in call to insert_text()");
		}
		gtk_editable_insert_text (editable, c, len, &position);
		RETVAL = position;
	}
	OUTPUT:
	RETVAL

void
gtk_editable_delete_text (editable, start=0, end=-1)
	Gtk::Editable editable
	int           start
	int           end

gstring
gtk_editable_get_chars (editable, start=0, end=-1)
	Gtk::Editable editable
	int           start
	int           end

void
gtk_editable_cut_clipboard (editable)
	Gtk::Editable editable
	ALIAS:
		Gtk::Editable::cut_clipboard = 0
		Gtk::Editable::copy_clipboard = 1
		Gtk::Editable::paste_clipboard = 2
		Gtk::Editable::delete_selection = 3
		Gtk::Editable::changed = 4
	CODE:
	switch (ix) {
	case 0: gtk_editable_cut_clipboard (editable); break;
	case 1: gtk_editable_copy_clipboard (editable); break;
	case 2: gtk_editable_paste_clipboard (editable); break;
	case 3: gtk_editable_delete_selection (editable); break;
	case 4: gtk_editable_changed (editable); break;
	}

void
gtk_editable_claim_selection (editable, claim, time=GDK_CURRENT_TIME)
	Gtk::Editable editable
	bool          claim
	int           time

int
gtk_editable_get_position (editable)
	Gtk::Editable editable

void
gtk_editable_set_position (editable, position)
	Gtk::Editable editable
	int           position

void
gtk_editable_set_editable (editable, is_editable=TRUE)
	Gtk::Editable editable
	bool          is_editable

guint
current_pos (editable)
	Gtk::Editable editable
	ALIAS:
		Gtk::Editable::current_pos = 0
		Gtk::Editable::selection_start_pos = 1
		Gtk::Editable::selection_end_pos = 2
		Gtk::Editable::has_selection = 3
	CODE:
	switch (ix) {
	case 0: RETVAL = editable->current_pos; break;
	case 1: RETVAL = editable->selection_start_pos; break;
	case 2: RETVAL = editable->selection_end_pos; break;
	case 3: RETVAL = editable->has_selection; break;
	}
	OUTPUT:
	RETVAL

#endif

