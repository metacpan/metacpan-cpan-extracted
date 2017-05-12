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

MODULE = Gtk2::Ruler	PACKAGE = Gtk2::Ruler	PREFIX = gtk_ruler_

## void gtk_ruler_set_metric (GtkRuler *ruler, GtkMetricType metric)
void
gtk_ruler_set_metric (ruler, metric)
	GtkRuler      * ruler
	GtkMetricType   metric

## void gtk_ruler_set_range (GtkRuler *ruler, gdouble lower, gdouble upper, gdouble position, gdouble max_size)
void
gtk_ruler_set_range (ruler, lower, upper, position, max_size)
	GtkRuler * ruler
	gdouble    lower
	gdouble    upper
	gdouble    position
	gdouble    max_size

## void gtk_ruler_draw_ticks (GtkRuler *ruler)
void
gtk_ruler_draw_ticks (ruler)
	GtkRuler * ruler

## void gtk_ruler_draw_pos (GtkRuler *ruler)
void
gtk_ruler_draw_pos (ruler)
	GtkRuler * ruler

## GtkMetricType gtk_ruler_get_metric (GtkRuler *ruler)
GtkMetricType
gtk_ruler_get_metric (ruler)
	GtkRuler * ruler

## void gtk_ruler_get_range (GtkRuler *ruler, gdouble *lower, gdouble *upper, gdouble *position, gdouble *max_size)
void
gtk_ruler_get_range (GtkRuler * ruler, OUTLIST gdouble lower, OUTLIST gdouble upper, OUTLIST gdouble position, OUTLIST gdouble max_size)

