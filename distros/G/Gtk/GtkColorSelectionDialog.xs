
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

MODULE = Gtk::ColorSelectionDialog		PACKAGE = Gtk::ColorSelectionDialog

#ifdef GTK_COLOR_SELECTION_DIALOG

Gtk::ColorSelectionDialog
new(Class, title)
	SV *	Class
	char *	title
	CODE:
	RETVAL = GTK_COLOR_SELECTION_DIALOG(gtk_color_selection_dialog_new(title));
	OUTPUT:
	RETVAL

Gtk::ColorSelection
colorsel(csdialog)
	Gtk::ColorSelectionDialog	csdialog
	CODE:
	RETVAL = GTK_COLOR_SELECTION(csdialog->colorsel);
	OUTPUT:
	RETVAL

Gtk::Widget
ok_button(csdialog)
	Gtk::ColorSelectionDialog	csdialog
	CODE:
	RETVAL = csdialog->ok_button;
	OUTPUT:
	RETVAL

Gtk::Widget
cancel_button(csdialog)
	Gtk::ColorSelectionDialog	csdialog
	CODE:
	RETVAL = csdialog->cancel_button;
	OUTPUT:
	RETVAL

Gtk::Widget
help_button(csdialog)
	Gtk::ColorSelectionDialog	csdialog
	CODE:
	RETVAL = csdialog->help_button;
	OUTPUT:
	RETVAL

#endif
