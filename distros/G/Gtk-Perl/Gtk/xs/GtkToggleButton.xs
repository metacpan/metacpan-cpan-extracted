
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::ToggleButton		PACKAGE = Gtk::ToggleButton		PREFIX = gtk_toggle_button_

#ifdef GTK_TOGGLE_BUTTON

Gtk::ToggleButton_Sink
new(Class, label=0)
	SV *	Class
	char *	label
	ALIAS:
		Gtk::ToggleButton::new = 0
		Gtk::ToggleButton::new_with_label = 1
	CODE:
	if (label)
		RETVAL = (GtkToggleButton*)(gtk_toggle_button_new_with_label(label));
	else
		RETVAL = (GtkToggleButton*)(gtk_toggle_button_new());
	OUTPUT:
	RETVAL

void
gtk_toggle_button_set_active(toggle_button, state)
	Gtk::ToggleButton	toggle_button
	int	state
	ALIAS:
		Gtk::ToggleButton::set_state = 1
	CODE:
#if GTK_HVER < 0x010114
	/* DEPRECATED */
	gtk_toggle_button_set_state(toggle_button, state);
#else
	gtk_toggle_button_set_active(toggle_button, state);
#endif

void
gtk_toggle_button_set_mode(toggle_button, draw_indicator)
	Gtk::ToggleButton	toggle_button
	int	draw_indicator

void
gtk_toggle_button_toggled(toggle_button)
	Gtk::ToggleButton	toggle_button

#if GTK_HVER >= 0x010200

gboolean
gtk_toggle_button_get_active (toggle_button)
	Gtk::ToggleButton	toggle_button

#endif

int
active(toggle_button, new_value=0)
	Gtk::ToggleButton	toggle_button
	int	new_value
	CODE:
		RETVAL = toggle_button->active;
		if (items>1)
			toggle_button->active = new_value;
	OUTPUT:
	RETVAL

int
draw_indicator(toggle_button)
	Gtk::ToggleButton	toggle_button
	CODE:
		RETVAL = toggle_button->draw_indicator;
	OUTPUT:
	RETVAL

#endif
