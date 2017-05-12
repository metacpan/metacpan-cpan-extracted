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

MODULE = Gtk2::ProgressBar	PACKAGE = Gtk2::ProgressBar	PREFIX = gtk_progress_bar_

## GtkWidget* gtk_progress_bar_new (void)
GtkWidget *
gtk_progress_bar_new (class)
    C_ARGS:
	/* void */

## void gtk_progress_bar_set_text (GtkProgressBar *pbar, const gchar *text)
void
gtk_progress_bar_set_text (pbar, text)
	GtkProgressBar     * pbar
	const gchar_ornull * text

## void gtk_progress_bar_set_fraction (GtkProgressBar *pbar, gdouble fraction)
void
gtk_progress_bar_set_fraction (pbar, fraction)
	GtkProgressBar * pbar
	gdouble          fraction

## void gtk_progress_bar_set_pulse_step (GtkProgressBar *pbar, gdouble fraction)
void
gtk_progress_bar_set_pulse_step (pbar, fraction)
	GtkProgressBar * pbar
	gdouble          fraction

## void gtk_progress_bar_set_orientation (GtkProgressBar *pbar, GtkProgressBarOrientation orientation)
void
gtk_progress_bar_set_orientation (pbar, orientation)
	GtkProgressBar            * pbar
	GtkProgressBarOrientation   orientation

## gdouble gtk_progress_bar_get_fraction (GtkProgressBar *pbar)
gdouble
gtk_progress_bar_get_fraction (pbar)
	GtkProgressBar * pbar

## gdouble gtk_progress_bar_get_pulse_step (GtkProgressBar *pbar)
gdouble
gtk_progress_bar_get_pulse_step (pbar)
	GtkProgressBar * pbar

## GtkProgressBarOrientation gtk_progress_bar_get_orientation (GtkProgressBar *pbar)
GtkProgressBarOrientation
gtk_progress_bar_get_orientation (pbar)
	GtkProgressBar * pbar

##void gtk_progress_bar_pulse (GtkProgressBar *pbar)
void
gtk_progress_bar_pulse (pbar)
	GtkProgressBar * pbar

##G_CONST_RETURN gchar * gtk_progress_bar_get_text (GtkProgressBar *pbar)
const gchar_ornull *
gtk_progress_bar_get_text (pbar)
	GtkProgressBar * pbar

#if GTK_CHECK_VERSION (2, 6, 0)

void gtk_progress_bar_set_ellipsize (GtkProgressBar *pbar, PangoEllipsizeMode mode);

PangoEllipsizeMode gtk_progress_bar_get_ellipsize (GtkProgressBar *pbar);

#endif
