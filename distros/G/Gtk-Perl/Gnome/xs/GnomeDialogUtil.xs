
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


MODULE = Gnome::DialogUtil		PACKAGE = Gnome::DialogUtil

Gtk::Widget_Up
ok(Class, message, parent=0)
	SV *	Class
	char *	message
	Gtk::Window_OrNULL	parent
	ALIAS:
		Gnome::DialogUtil::ok = 0
		Gnome::DialogUtil::error = 1
		Gnome::DialogUtil::warning = 2
	CODE:
	switch (ix) {
	case 0: RETVAL = GTK_WIDGET(parent ? gnome_ok_dialog_parented(message, parent) : gnome_ok_dialog(message));
		break;
	case 1: RETVAL = GTK_WIDGET(parent ? gnome_error_dialog_parented(message, parent) : gnome_error_dialog(message));
		break;
	case 2: RETVAL = GTK_WIDGET(parent ? gnome_warning_dialog_parented(message, parent) : gnome_warning_dialog(message));
		break;
	}
	OUTPUT:
	RETVAL


