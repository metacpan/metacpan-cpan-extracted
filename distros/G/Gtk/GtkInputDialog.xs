
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


MODULE = Gtk::InputDialog		PACKAGE = Gtk::InputDialog	PREFIX = gtk_input_dialog_

#ifdef GTK_INPUT_DIALOG

Gtk::InputDialog
new(Class)
	SV *	Class
	CODE:
	RETVAL = GTK_INPUT_DIALOG(gtk_input_dialog_new());
	OUTPUT:
	RETVAL

upGtk::Widget
axis_list(dialog)
	Gtk::InputDialog	dialog
	CODE:
	RETVAL = dialog->axis_list;
	OUTPUT:
	RETVAL

upGtk::Widget
axis_listbox(dialog)
	Gtk::InputDialog	dialog
	CODE:
	RETVAL = dialog->axis_listbox;
	OUTPUT:
	RETVAL

upGtk::Widget
mode_optionmenu(dialog)
	Gtk::InputDialog	dialog
	CODE:
	RETVAL = dialog->mode_optionmenu;
	OUTPUT:
	RETVAL

upGtk::Widget
close_button(dialog)
	Gtk::InputDialog	dialog
	CODE:
	RETVAL = dialog->close_button;
	OUTPUT:
	RETVAL

upGtk::Widget
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
