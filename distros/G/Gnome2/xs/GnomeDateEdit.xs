/*
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"

static SV *
date_edit_flags_to_sv (gint flags)
{
	return gperl_convert_back_flags (GNOME_TYPE_DATE_EDIT_FLAGS,
	                                 flags);
}

MODULE = Gnome2::DateEdit	PACKAGE = Gnome2::DateEdit	PREFIX = gnome_date_edit_

GtkWidget *
gnome_date_edit_new (class, the_time, show_time, use_24_format)
	time_t the_time
	gboolean show_time
	gboolean use_24_format
    C_ARGS:
	the_time, show_time, use_24_format

GtkWidget *
gnome_date_edit_new_flags (class, the_time, flags)
	time_t the_time
	GnomeDateEditFlags flags
    C_ARGS:
	the_time, flags

## void gnome_date_edit_set_time (GnomeDateEdit *gde, time_t the_time) 
void
gnome_date_edit_set_time (gde, the_time)
	GnomeDateEdit *gde
	time_t the_time

## time_t gnome_date_edit_get_time (GnomeDateEdit *gde) 
time_t
gnome_date_edit_get_time (gde)
	GnomeDateEdit *gde

## void gnome_date_edit_set_popup_range (GnomeDateEdit *gde, int low_hour, int up_hour) 
void
gnome_date_edit_set_popup_range (gde, low_hour, up_hour)
	GnomeDateEdit *gde
	int low_hour
	int up_hour

## void gnome_date_edit_set_flags (GnomeDateEdit *gde, GnomeDateEditFlags flags) 
void
gnome_date_edit_set_flags (gde, flags)
	GnomeDateEdit *gde
	GnomeDateEditFlags flags

## int gnome_date_edit_get_flags (GnomeDateEdit *gde) 
SV *
gnome_date_edit_get_flags (gde)
	GnomeDateEdit *gde
    CODE:
	RETVAL = date_edit_flags_to_sv (gnome_date_edit_get_flags (gde));
    OUTPUT:
	RETVAL

## time_t gnome_date_edit_get_initial_time(GnomeDateEdit *gde) 
time_t
gnome_date_edit_get_initial_time (gde)
	GnomeDateEdit *gde

