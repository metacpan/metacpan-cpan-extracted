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


MODULE = Gtk::Button		PACKAGE = Gtk::Button		PREFIX = gtk_button_

#ifdef GTK_BUTTON

Gtk::Button
new(Class, label=0)
	SV *	Class
	char *	label
	CODE:
	if (!label)
		RETVAL = GTK_BUTTON(gtk_button_new());
	else
		RETVAL = GTK_BUTTON(gtk_button_new_with_label(label));
	OUTPUT:
	RETVAL

Gtk::Button
new_with_label(Class, label)
	SV *	Class
	char *	label
	CODE:
	RETVAL = GTK_BUTTON(gtk_button_new_with_label(label));
	OUTPUT:
	RETVAL

void
gtk_button_pressed(button)
	Gtk::Button	button

void
gtk_button_released(button)
	Gtk::Button	button

void
gtk_button_clicked(button)
	Gtk::Button	button

void
gtk_button_enter(button)
	Gtk::Button	button

void
gtk_button_leave(button)
	Gtk::Button	button

#endif
