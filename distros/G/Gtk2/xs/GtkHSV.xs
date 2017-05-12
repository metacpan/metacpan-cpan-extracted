/*
 * Copyright (c) 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::HSV	PACKAGE = Gtk2::HSV	PREFIX = gtk_hsv_

GtkWidget *
gtk_hsv_new (class)
    C_ARGS:
	/* void */

void gtk_hsv_set_color (GtkHSV *hsv, double h, double s, double v);

void gtk_hsv_get_color (GtkHSV *hsv, OUTLIST gdouble h, OUTLIST gdouble s, OUTLIST gdouble v);

void gtk_hsv_set_metrics (GtkHSV *hsv, gint size, gint ring_width);

void gtk_hsv_get_metrics (GtkHSV *hsv, OUTLIST gint size, OUTLIST gint ring_width);

gboolean gtk_hsv_is_adjusting (GtkHSV *hsv);

MODULE = Gtk2::HSV	PACKAGE = Gtk2	PREFIX = gtk_

=for object Gtk2::HSV
=cut

=for apidoc __function__
=cut
void gtk_hsv_to_rgb (gdouble h, gdouble s, gdouble v, OUTLIST gdouble r, OUTLIST gdouble g, OUTLIST gdouble b);

=for apidoc __function__
=cut
void gtk_rgb_to_hsv (gdouble r, gdouble g, gdouble b, OUTLIST gdouble h, OUTLIST gdouble s, OUTLIST gdouble v);
