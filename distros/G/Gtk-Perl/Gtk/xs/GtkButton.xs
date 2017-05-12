#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"


MODULE = Gtk::Button		PACKAGE = Gtk::Button		PREFIX = gtk_button_

#ifdef GTK_BUTTON

Gtk::Button_Sink
new(Class, label=0)
	SV *	Class
	char *	label
	ALIAS:
		Gtk::Button::new = 0
		Gtk::Button::new_with_label = 1
	CODE:
	if (!label)
		RETVAL = (GtkButton*)(gtk_button_new());
	else
		RETVAL = (GtkButton*)(gtk_button_new_with_label(label));
	OUTPUT:
	RETVAL

void
gtk_button_pressed(button)
	Gtk::Button	button
	ALIAS:
		Gtk::Button::pressed = 0
		Gtk::Button::released = 1
		Gtk::Button::clicked = 2
		Gtk::Button::enter = 3
		Gtk::Button::leave = 4
	CODE:
	switch(ix) {
	case 0: gtk_button_pressed(button); break;
	case 1: gtk_button_released(button); break;
	case 2: gtk_button_clicked(button); break;
	case 3: gtk_button_enter(button); break;
	case 4: gtk_button_leave(button); break;
	}

# void FIXME
# gtk_button_set_relief(button, newstyle)
# 	Gtk::Button 	button
# 	Gtk::ReliefStyle newstyle
#
# Gtk::ReliefStyle
# gtk_button_get_relief(button)
# 	Gtk::Button 	button

#endif
