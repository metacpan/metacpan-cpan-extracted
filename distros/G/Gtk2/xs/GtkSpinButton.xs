/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::SpinButton	PACKAGE = Gtk2::SpinButton	PREFIX = gtk_spin_button_

##GtkWidget * gtk_spin_button_new (GtkAdjustment *adjustment, gdouble climb_rate, guint digits)
GtkWidget *
gtk_spin_button_new (class, adjustment, climb_rate, digits)
	GtkAdjustment * adjustment
	gdouble         climb_rate
	guint           digits
    C_ARGS:
	adjustment, climb_rate, digits

##GtkWidget * gtk_spin_button_new_with_range (gdouble min, gdouble max, gdouble step)
GtkWidget *
gtk_spin_button_new_with_range (class, min, max, step)
	gdouble   min
	gdouble   max
	gdouble   step
    C_ARGS:
	min, max, step

 ## void gtk_spin_button_configure (GtkSpinButton *spin_button, GtkAdjustment *adjustment, gdouble climb_rate, guint digits)
void
gtk_spin_button_configure (spin_button, adjustment, climb_rate, digits)
	GtkSpinButton *spin_button
	GtkAdjustment *adjustment
	gdouble climb_rate
	guint digits

void
gtk_spin_button_set_adjustment (spin_button, adjustment)
	GtkSpinButton *spin_button
	GtkAdjustment *adjustment

void
gtk_spin_button_set_digits (spin_button, digits)
	GtkSpinButton *spin_button
	guint digits

guint
gtk_spin_button_get_digits (spin_button)
	GtkSpinButton *spin_button

void
gtk_spin_button_set_increments (spin_button, step, page)
	GtkSpinButton *spin_button
	gdouble step
	gdouble page

void
gtk_spin_button_get_increments (GtkSpinButton * spin_button, OUTLIST gdouble step, OUTLIST gdouble page)

void
gtk_spin_button_set_range (spin_button, min, max)
	GtkSpinButton *spin_button
	gdouble min
	gdouble max

void
gtk_spin_button_get_range (GtkSpinButton * spin_button, OUTLIST gdouble min, OUTLIST gdouble max)

gdouble
gtk_spin_button_get_value (spin_button)
	GtkSpinButton *spin_button

 ## something tells me no one will ever use this one...
gint
gtk_spin_button_get_value_as_int (spin_button)
	GtkSpinButton *spin_button

### this is deprecated
##gfloat
##gtk_spin_button_get_value_as_float (spin_button)
##	GtkSpinButton * spin_button

void
gtk_spin_button_set_value (spin_button, value)
	GtkSpinButton *spin_button
	gdouble value

void
gtk_spin_button_set_update_policy (spin_button, policy)
	GtkSpinButton *spin_button
	GtkSpinButtonUpdatePolicy policy

GtkSpinButtonUpdatePolicy
gtk_spin_button_get_update_policy (spin_button)
	GtkSpinButton *spin_button

void
gtk_spin_button_set_numeric (spin_button, numeric)
	GtkSpinButton *spin_button
	gboolean numeric

gboolean
gtk_spin_button_get_numeric (spin_button)
	GtkSpinButton *spin_button

void
gtk_spin_button_spin (spin_button, direction, increment)
	GtkSpinButton *spin_button
	GtkSpinType direction
	gdouble increment

void
gtk_spin_button_set_wrap (spin_button, wrap)
	GtkSpinButton *spin_button
	gboolean wrap

gboolean
gtk_spin_button_get_wrap (spin_button)
	GtkSpinButton *spin_button

void
gtk_spin_button_set_snap_to_ticks (spin_button, snap_to_ticks)
	GtkSpinButton *spin_button
	gboolean snap_to_ticks

gboolean
gtk_spin_button_get_snap_to_ticks (spin_button)
	GtkSpinButton *spin_button

void
gtk_spin_button_update (spin_button)
	GtkSpinButton *spin_button

GtkAdjustment *
gtk_spin_button_get_adjustment (spin_button)
	GtkSpinButton *spin_button

