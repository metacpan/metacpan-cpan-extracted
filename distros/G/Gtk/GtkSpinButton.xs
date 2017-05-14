
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

MODULE = Gtk::SpinButton		PACKAGE = Gtk::SpinButton		PREFIX = gtk_spin_button_

#ifdef GTK_SPIN_BUTTON

Gtk::SpinButton
new(Class, adjustment, climb_rate, digits)
	SV * Class
	Gtk::Adjustment adjustment
	double climb_rate
	int digits
	CODE:
	RETVAL = GTK_SPIN_BUTTON(gtk_spin_button_new(adjustment, climb_rate, digits));
	OUTPUT:
	RETVAL

void
gtk_spin_button_set_adjustment(self, adjustment)
	Gtk::SpinButton self
	Gtk::Adjustment adjustment

Gtk::Adjustment
gtk_spin_button_get_adjustment(self)
	Gtk::SpinButton self

void
gtk_spin_button_set_digits(self, digits)
	Gtk::SpinButton self
	int digits

double
gtk_spin_button_get_value_as_float(self)
	Gtk::SpinButton self

int
gtk_spin_button_get_value_as_int(self)
	Gtk::SpinButton self

void
gtk_spin_button_set_value(self, value)
	Gtk::SpinButton self
	double value

void
gtk_spin_button_set_update_policy(self, policy)
	Gtk::SpinButton self
	Gtk::SpinButtonUpdatePolicy policy

#if 0

void
gtk_spin_button_set_numeric(self, numeric)
	Gtk::SpinButton self
	int numeric

#endif

#endif

