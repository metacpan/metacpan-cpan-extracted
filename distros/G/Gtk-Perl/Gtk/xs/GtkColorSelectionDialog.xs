
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::ColorSelectionDialog		PACKAGE = Gtk::ColorSelectionDialog

#ifdef GTK_COLOR_SELECTION_DIALOG

Gtk::ColorSelectionDialog_Sink
new(Class, title)
	SV *	Class
	char *	title
	CODE:
	RETVAL = (GtkColorSelectionDialog*)(gtk_color_selection_dialog_new(title));
	OUTPUT:
	RETVAL

Gtk::ColorSelection
colorsel(csdialog)
	Gtk::ColorSelectionDialog	csdialog
	CODE:
	RETVAL = GTK_COLOR_SELECTION(csdialog->colorsel);
	OUTPUT:
	RETVAL

Gtk::Widget_Up
ok_button(csdialog)
	Gtk::ColorSelectionDialog	csdialog
	CODE:
	RETVAL = csdialog->ok_button;
	OUTPUT:
	RETVAL

Gtk::Widget_Up
cancel_button(csdialog)
	Gtk::ColorSelectionDialog	csdialog
	CODE:
	RETVAL = csdialog->cancel_button;
	OUTPUT:
	RETVAL

Gtk::Widget_Up
help_button(csdialog)
	Gtk::ColorSelectionDialog	csdialog
	CODE:
	RETVAL = csdialog->help_button;
	OUTPUT:
	RETVAL

#endif
