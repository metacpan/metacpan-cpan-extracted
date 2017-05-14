
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

MODULE = Gtk::CheckButton		PACKAGE = Gtk::CheckButton

#ifdef GTK_CHECK_BUTTON

Gtk::CheckButton
new(Class, label=0)
	SV *	Class
	char *	label
	CODE:
	if (!label)
		RETVAL = GTK_CHECK_BUTTON(gtk_check_button_new());
	else
		RETVAL = GTK_CHECK_BUTTON(gtk_check_button_new_with_label(label));
	OUTPUT:
	RETVAL

Gtk::CheckButton
new_with_label(Class, label)
	SV *	Class
	char *	label
	CODE:
	RETVAL = GTK_CHECK_BUTTON(gtk_check_button_new_with_label(label));
	OUTPUT:
	RETVAL

#endif
