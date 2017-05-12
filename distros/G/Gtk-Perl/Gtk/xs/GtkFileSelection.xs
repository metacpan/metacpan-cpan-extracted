
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::FileSelection		PACKAGE = Gtk::FileSelection	PREFIX = gtk_file_selection_

#ifdef GTK_FILE_SELECTION

Gtk::FileSelection_Sink
new(Class, title)
	SV *	Class
	char *	title
	CODE:
	RETVAL = (GtkFileSelection*)(gtk_file_selection_new(title));
	OUTPUT:
	RETVAL

void
gtk_file_selection_set_filename(file_selection, filename)
	Gtk::FileSelection	file_selection
	char *	filename

char *
gtk_file_selection_get_filename(file_selection)
	Gtk::FileSelection	file_selection

void
gtk_file_selection_show_fileop_buttons (file_selection)
	Gtk::FileSelection	file_selection

void
gtk_file_selection_hide_fileop_buttons (file_selection)
	Gtk::FileSelection	file_selection

#if GTK_HVER >= 0x010200

void
gtk_file_selection_complete (file_selection, pattern)
	Gtk::FileSelection	file_selection
	char *	pattern

#endif

Gtk::Widget_Up
ok_button(fs)
	Gtk::FileSelection	fs
	ALIAS:
		Gtk::FileSelection::ok_button = 0
		Gtk::FileSelection::cancel_button = 1
		Gtk::FileSelection::dir_list = 2
		Gtk::FileSelection::file_list = 3
		Gtk::FileSelection::selection_entry = 4
		Gtk::FileSelection::selection_text = 5
		Gtk::FileSelection::main_vbox = 6
		Gtk::FileSelection::help_button = 7
	CODE:
	switch (ix) {
	case 0: RETVAL = fs->ok_button; break;
	case 1: RETVAL = fs->cancel_button; break;
	case 2: RETVAL = fs->dir_list; break;
	case 3: RETVAL = fs->file_list; break;
	case 4: RETVAL = fs->selection_entry; break;
	case 5: RETVAL = fs->selection_text; break;
	case 6: RETVAL = fs->main_vbox; break;
	case 7: RETVAL = fs->help_button; break;
	}
	OUTPUT:
	RETVAL

#endif
