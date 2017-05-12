
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"

MODULE = Gtk::SpinButton		PACKAGE = Gtk::SpinButton		PREFIX = gtk_spin_button_

#ifdef GTK_SPIN_BUTTON

Gtk::SpinButton_Sink
new(Class, adjustment, climb_rate, digits)
	SV * Class
	Gtk::Adjustment adjustment
	double climb_rate
	int digits
	CODE:
	RETVAL = (GtkSpinButton*)(gtk_spin_button_new(adjustment, climb_rate, digits));
	OUTPUT:
	RETVAL

void
gtk_spin_button_set_adjustment(spinbutton, adjustment)
	Gtk::SpinButton spinbutton
	Gtk::Adjustment adjustment

Gtk::Adjustment
gtk_spin_button_get_adjustment(spinbutton)
	Gtk::SpinButton spinbutton

void
gtk_spin_button_set_digits(spinbutton, digits)
	Gtk::SpinButton spinbutton
	int digits

int
gtk_spin_button_digits(spinbutton)
	Gtk::SpinButton spinbutton
	CODE:
	RETVAL = spinbutton->digits;
	OUTPUT:
	RETVAL

double
gtk_spin_button_get_value_as_float(spinbutton)
	Gtk::SpinButton spinbutton

int
gtk_spin_button_get_value_as_int(spinbutton)
	Gtk::SpinButton spinbutton

void
gtk_spin_button_set_value(spinbutton, value)
	Gtk::SpinButton spinbutton
	gfloat value

void
gtk_spin_button_set_update_policy(spinbutton, policy)
	Gtk::SpinButton	spinbutton
	Gtk::SpinButtonUpdatePolicy policy


void
gtk_spin_button_set_numeric(spinbutton, numeric)
	Gtk::SpinButton spinbutton
	int numeric

void
gtk_spin_button_spin(spinbutton, direction, step)
	Gtk::SpinButton spinbutton
	Gtk::ArrowType	direction
	gfloat	step

void
gtk_spin_button_set_wrap(spinbutton, wrap)
	Gtk::SpinButton spinbutton
	int	wrap

void
gtk_spin_button_set_snap_to_ticks(spinbutton, snap_to_ticks)
	Gtk::SpinButton spinbutton
	int snap_to_ticks
	CODE:
#if GTK_HVER >= 0x010100
	gtk_spin_button_set_snap_to_ticks(spinbutton, snap_to_ticks);
#else
	/* FIXME: Is this even vaguely right? */
	if (snap_to_ticks)
		gtk_spin_button_set_update_policy(spinbutton, GTK_UPDATE_SNAP_TO_TICKS);
	else
		gtk_spin_button_set_update_policy(spinbutton, GTK_UPDATE_ALWAYS);
#endif

#if GTK_HVER >= 0x010200

void
gtk_spin_button_update (spin_button)
	Gtk::SpinButton	spin_button

void
gtk_spin_button_set_shadow_type (spin_button, type)
	Gtk::SpinButton	spin_button
	Gtk::ShadowType	type

void
gtk_spin_button_configure (spin_button, adj, climb_rate, digits)
	Gtk::SpinButton	spin_button
	Gtk::Adjustment	adj
	double	climb_rate
	guint	digits

#endif

#endif

