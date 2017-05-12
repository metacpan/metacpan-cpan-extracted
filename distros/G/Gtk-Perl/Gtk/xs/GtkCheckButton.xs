
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::CheckButton		PACKAGE = Gtk::CheckButton

#ifdef GTK_CHECK_BUTTON

Gtk::CheckButton_Sink
new(Class, label=0)
	SV *	Class
	char *	label
	ALIAS:
		Gtk::CheckButton::new = 0
		Gtk::CheckButton::new_with_label = 1
	CODE:
	if (!label)
		RETVAL = (GtkCheckButton*)(gtk_check_button_new());
	else
		RETVAL = (GtkCheckButton*)(gtk_check_button_new_with_label(label));
	OUTPUT:
	RETVAL

#endif
