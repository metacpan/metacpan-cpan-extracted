
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gtk/gtk.h>

#include "GtkTypes.h"
#include "GdkTypes.h"
#include "MiscTypes.h"

#include "GtkDefs.h"

#ifndef boolSV
# define boolSV(b) ((b) ? &sv_yes : &sv_no)
#endif



MODULE = Gtk::FileSelection		PACKAGE = Gtk::FileSelection	PREFIX = gtk_file_selection_

#ifdef GTK_FILE_SELECTION

Gtk::FileSelection
new(Class, title)
	SV *	Class
	char *	title
	CODE:
	RETVAL = GTK_FILE_SELECTION(gtk_file_selection_new(title));
	OUTPUT:
	RETVAL

void
gtk_file_selection_set_filename(self, filename)
	Gtk::FileSelection	self
	char *	filename

char *
gtk_file_selection_get_filename(self)
	Gtk::FileSelection	self

void
gtk_file_selection_show_fileop_buttons (self)
	Gtk::FileSelection	self

void
gtk_file_selection_hide_fileop_buttons (self)
	Gtk::FileSelection	self

upGtk::Widget
ok_button(fs)
	Gtk::FileSelection	fs
	CODE:
	RETVAL = fs->ok_button;
	OUTPUT:
	RETVAL

upGtk::Widget
cancel_button(fs)
	Gtk::FileSelection	fs
	CODE:
	RETVAL = fs->cancel_button;
	OUTPUT:
	RETVAL

upGtk::Widget
dir_list(fs)
	Gtk::FileSelection	fs
	CODE:
	RETVAL = fs->dir_list;
	OUTPUT:
	RETVAL

upGtk::Widget
file_list(fs)
	Gtk::FileSelection	fs
	CODE:
	RETVAL = fs->file_list;
	OUTPUT:
	RETVAL

upGtk::Widget
selection_entry(fs)
	Gtk::FileSelection	fs
	CODE:
	RETVAL = fs->selection_entry;
	OUTPUT:
	RETVAL

upGtk::Widget
selection_text(fs)
	Gtk::FileSelection	fs
	CODE:
	RETVAL = fs->selection_text;
	OUTPUT:
	RETVAL

upGtk::Widget
main_vbox(fs)
	Gtk::FileSelection	fs
	CODE:
	RETVAL = fs->main_vbox;
	OUTPUT:
	RETVAL

upGtk::Widget
help_button(fs)
	Gtk::FileSelection	fs
	CODE:
	RETVAL = fs->help_button;
	OUTPUT:
	RETVAL

#endif
