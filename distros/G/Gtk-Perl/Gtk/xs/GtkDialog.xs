
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::Dialog		PACKAGE = Gtk::Dialog

#ifdef GTK_DIALOG

Gtk::Dialog_Sink
new(Class)
	SV *	Class
	CODE:
	RETVAL = (GtkDialog*)(gtk_dialog_new());
	OUTPUT:
	RETVAL

Gtk::Widget_Up
vbox(dialog)
	Gtk::Dialog	dialog
	CODE:
	RETVAL = dialog->vbox;
	OUTPUT:
	RETVAL

Gtk::Widget_Up
action_area(dialog)
	Gtk::Dialog	dialog
	CODE:
	RETVAL = dialog->action_area;
	OUTPUT:
	RETVAL

#endif
