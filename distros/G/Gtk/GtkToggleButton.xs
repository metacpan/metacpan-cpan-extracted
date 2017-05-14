
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


MODULE = Gtk::ToggleButton		PACKAGE = Gtk::ToggleButton		PREFIX = gtk_toggle_button_

#ifdef GTK_TOGGLE_BUTTON

Gtk::ToggleButton
new(Class, label=0)
	SV *	Class
	char *	label
	CODE:
	if (label)
		RETVAL = GTK_TOGGLE_BUTTON(gtk_toggle_button_new_with_label(label));
	else
		RETVAL = GTK_TOGGLE_BUTTON(gtk_toggle_button_new());
	OUTPUT:
	RETVAL

Gtk::ToggleButton
new_with_label(Class, label)
	SV *	Class
	char *	label
	CODE:
	RETVAL = GTK_TOGGLE_BUTTON(gtk_toggle_button_new_with_label(label));
	OUTPUT:
	RETVAL

void
gtk_toggle_button_set_state(self, state)
	Gtk::ToggleButton	self
	int	state

void
gtk_toggle_button_set_mode(self, draw_indicator)
	Gtk::ToggleButton	self
	int	draw_indicator

void
gtk_toggle_button_toggled(self)
	Gtk::ToggleButton	self

int
active(self)
	Gtk::ToggleButton	self
	CODE:
		RETVAL = self->active;
	OUTPUT:
	RETVAL

int
draw_indicator(self)
	Gtk::ToggleButton	self
	CODE:
		RETVAL = self->draw_indicator;
	OUTPUT:
	RETVAL

#endif
