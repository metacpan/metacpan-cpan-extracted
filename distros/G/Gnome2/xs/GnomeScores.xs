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

MODULE = Gnome2::Scores	PACKAGE = Gnome2::Scores	PREFIX = gnome_scores_

##  GtkWidget * gnome_scores_display (const gchar *title, const gchar *app_name, const gchar *level, int pos) 
GtkWidget *
gnome_scores_display (class, title, app_name, level, pos)
	const gchar *title
	const gchar *app_name
	const gchar *level
	int pos
    C_ARGS:
	title, app_name, level, pos

##  GtkWidget * gnome_scores_display_with_pixmap (const gchar *pixmap_logo, const gchar *app_name, const gchar *level, int pos) 
GtkWidget *
gnome_scores_display_with_pixmap (class, pixmap_logo, app_name, level, pos)
	const gchar *pixmap_logo
	const gchar *app_name
	const gchar *level
	int pos
    C_ARGS:
	pixmap_logo, app_name, level, pos

=for apidoc

=for arg names - reference to an array

=for arg scores - reference to an array

=for arg times - reference to an array

=cut
##  GtkWidget* gnome_scores_new (guint n_scores, gchar **names, gfloat *scores, time_t *times, gboolean clear) 
GtkWidget*
gnome_scores_new (class, names, scores, times, clear)
	SV * names
	SV * scores
	SV * times
	gboolean clear
    PREINIT:
	SV **s;
	int i;
	guint length;
	gchar **real_names = NULL;
	gfloat *real_scores = NULL;
	time_t *real_times = NULL;
    CODE:
	if (names && SvOK (names) && SvRV (names) && SvTYPE (SvRV (names)) == SVt_PVAV &&
	    scores && SvOK (scores) && SvRV (scores) && SvTYPE (SvRV (scores)) == SVt_PVAV &&
	    times && SvOK (times) && SvRV (times) && SvTYPE (SvRV (times)) == SVt_PVAV) {
		AV *a = (AV*) SvRV (names);
		AV *b = (AV*) SvRV (scores);
		AV *c = (AV*) SvRV (times);

		length = av_len (a);
		real_names = g_new0 (gchar *, length + 1);

		for (i = 0; i <= length; i++)
			if ((s = av_fetch (a, i, 0)) && SvOK (*s))
				real_names[i] = SvGChar (*s);

		/* --------------------------------------------------------- */

		if (av_len (b) != length)
			croak ("All three array references must have the same number of elements");

		real_scores = g_new0 (gfloat, length + 1);

		for (i = 0; i <= length; i++)
			if ((s = av_fetch (b, i, 0)) && SvOK (*s))
				real_scores[i] = SvNV (*s);

		/* --------------------------------------------------------- */

		if (av_len (c) != length)
			croak ("All three array references must have the same number of elements");

		real_times = g_new0 (time_t, length + 1);

		for (i = 0; i <= length; i++)
			if ((s = av_fetch (c, i, 0)) && SvOK (*s))
				real_times[i] = SvIV (*s);
	}
	else
		croak ("Usage: Gnome2::Scores -> new([name, name, ...], [score, score, ...], [time, time, ...], clear)");

	RETVAL = gnome_scores_new (length + 1, real_names, real_scores, real_times, clear);
    OUTPUT:
	RETVAL

##  void gnome_scores_set_logo_label (GnomeScores *gs, const gchar *txt, const gchar *font, GdkColor *col) 
void
gnome_scores_set_logo_label (gs, txt, font, col)
	GnomeScores *gs
	const gchar *txt
	const gchar *font
	GdkColor *col

##  void gnome_scores_set_logo_pixmap (GnomeScores *gs, const gchar *pix_name) 
void
gnome_scores_set_logo_pixmap (gs, pix_name)
	GnomeScores *gs
	const gchar *pix_name

##  void gnome_scores_set_logo_widget (GnomeScores *gs, GtkWidget *w) 
void
gnome_scores_set_logo_widget (gs, w)
	GnomeScores *gs
	GtkWidget *w

##  void gnome_scores_set_color (GnomeScores *gs, guint n, GdkColor *col) 
void
gnome_scores_set_color (gs, n, col)
	GnomeScores *gs
	guint n
	GdkColor *col

##  void gnome_scores_set_def_color (GnomeScores *gs, GdkColor *col) 
void
gnome_scores_set_def_color (gs, col)
	GnomeScores *gs
	GdkColor *col

##  void gnome_scores_set_colors (GnomeScores *gs, GdkColor *col) 
void
gnome_scores_set_colors (gs, col)
	GnomeScores *gs
	GdkColor *col

##  void gnome_scores_set_logo_label_title (GnomeScores *gs, const gchar *txt) 
void
gnome_scores_set_logo_label_title (gs, txt)
	GnomeScores *gs
	const gchar *txt

##  void gnome_scores_set_current_player (GnomeScores *gs, gint i) 
void
gnome_scores_set_current_player (gs, i)
	GnomeScores *gs
	gint i

