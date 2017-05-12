
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::FontSelectionDialog	PACKAGE = Gtk::FontSelectionDialog	PREFIX = gtk_font_selection_dialog_

#ifdef GTK_FONT_SELECTION_DIALOG

Gtk::FontSelectionDialog_Sink
gtk_font_selection_dialog_new(Class, title)
	SV *	Class
	char*	title
	CODE:
	RETVAL = (GtkFontSelectionDialog*)(gtk_font_selection_dialog_new(title));
	OUTPUT:
	RETVAL

char*
gtk_font_selection_dialog_get_font_name(font_selection_dialog)
	Gtk::FontSelectionDialog	font_selection_dialog

Gtk::Gdk::Font
gtk_font_selection_dialog_get_font(font_selection_dialog)
	Gtk::FontSelectionDialog	font_selection_dialog

bool
gtk_font_selection_dialog_set_font_name(font_selection_dialog, font_name)
	Gtk::FontSelectionDialog	font_selection_dialog
	char*			font_name

char*
gtk_font_selection_dialog_get_preview_text(font_selection_dialog)
	Gtk::FontSelectionDialog	font_selection_dialog

void
gtk_font_selection_dialog_set_preview_text(font_selection_dialog, text)
	Gtk::FontSelectionDialog	font_selection_dialog
	char*			text

Gtk::Widget_Up
fontsel(font_selection_dialog)
	Gtk::FontSelectionDialog	font_selection_dialog
	ALIAS:
		Gtk::FontSelectionDialog::fontsel = 0
		Gtk::FontSelectionDialog::main_vbox = 1
		Gtk::FontSelectionDialog::action_area = 2
		Gtk::FontSelectionDialog::ok_button = 3
		Gtk::FontSelectionDialog::apply_button = 4
		Gtk::FontSelectionDialog::cancel_button = 5
	CODE:
	switch (ix) {
	case 0: RETVAL = font_selection_dialog->fontsel; break;
	case 1: RETVAL = font_selection_dialog->main_vbox; break;
	case 2: RETVAL = font_selection_dialog->action_area; break;
	case 3: RETVAL = font_selection_dialog->ok_button; break;
	case 4: RETVAL = font_selection_dialog->apply_button; break;
	case 5: RETVAL = font_selection_dialog->cancel_button; break;
	}
	OUTPUT:
	RETVAL

#endif

