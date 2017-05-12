
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::InputDialog		PACKAGE = Gtk::InputDialog	PREFIX = gtk_input_dialog_

#ifdef GTK_INPUT_DIALOG

Gtk::InputDialog_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkInputDialog*)(gtk_input_dialog_new());
	OUTPUT:
	RETVAL

Gtk::Widget_Up
axis_list(dialog)
	Gtk::InputDialog	dialog
	CODE:
	RETVAL = dialog->axis_list;
	OUTPUT:
	RETVAL

Gtk::Widget_Up
axis_listbox(dialog)
	Gtk::InputDialog	dialog
	CODE:
	RETVAL = dialog->axis_listbox;
	OUTPUT:
	RETVAL

Gtk::Widget_Up
mode_optionmenu(dialog)
	Gtk::InputDialog	dialog
	CODE:
	RETVAL = dialog->mode_optionmenu;
	OUTPUT:
	RETVAL

Gtk::Widget_Up
close_button(dialog)
	Gtk::InputDialog	dialog
	CODE:
	RETVAL = dialog->close_button;
	OUTPUT:
	RETVAL

Gtk::Widget_Up
save_button(dialog)
	Gtk::InputDialog	dialog
	CODE:
	RETVAL = dialog->save_button;
	OUTPUT:
	RETVAL

int
current_device(dialog)
	Gtk::InputDialog	dialog
	CODE:
	RETVAL = dialog->current_device;
	OUTPUT:
	RETVAL

#endif
