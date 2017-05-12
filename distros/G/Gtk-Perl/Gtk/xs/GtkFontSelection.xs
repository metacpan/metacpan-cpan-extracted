
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::FontSelection	PACKAGE = Gtk::FontSelection	PREFIX = gtk_font_selection_

#ifdef GTK_FONT_SELECTION

Gtk::FontSelection_Sink
gtk_font_selection_new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkFontSelection*)(gtk_font_selection_new());
	OUTPUT:
	RETVAL

char*
gtk_font_selection_get_font_name(font_selection)
	Gtk::FontSelection	font_selection

Gtk::Gdk::Font
gtk_font_selection_get_font(font_selection)
	Gtk::FontSelection	font_selection

bool
gtk_font_selection_set_font_name(font_selection, font_name)
	Gtk::FontSelection	font_selection
	char*			font_name

char*
gtk_font_selection_get_preview_text(font_selection)
	Gtk::FontSelection	font_selection

void
gtk_font_selection_set_preview_text(font_selection, text)
	Gtk::FontSelection	font_selection
	char*			text

#endif

