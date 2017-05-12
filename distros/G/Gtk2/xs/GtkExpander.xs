/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::Expander	PACKAGE = Gtk2::Expander	PREFIX = gtk_expander_

GtkWidget *gtk_expander_new (class, const gchar_ornull *label=NULL);
    C_ARGS:
	label

GtkWidget *gtk_expander_new_with_mnemonic (class, const gchar *label);
    C_ARGS:
	label


void gtk_expander_set_expanded (GtkExpander *expander, gboolean expanded);

gboolean gtk_expander_get_expanded (GtkExpander *expander);

###/* Spacing between the expander/label and the child */
void gtk_expander_set_spacing (GtkExpander *expander, gint spacing);

gint gtk_expander_get_spacing (GtkExpander *expander);


void gtk_expander_set_label (GtkExpander *expander, const gchar *label);

## G_CONST_RETURN
const gchar *gtk_expander_get_label (GtkExpander *expander);


void gtk_expander_set_use_underline (GtkExpander *expander, gboolean use_underline);

gboolean gtk_expander_get_use_underline (GtkExpander *expander);

void gtk_expander_set_use_markup (GtkExpander *expander, gboolean use_markup)

gboolean gtk_expander_get_use_markup (GtkExpander *expander)

void gtk_expander_set_label_widget (GtkExpander *expander, GtkWidget *label_widget);

GtkWidget *gtk_expander_get_label_widget (GtkExpander *expander);

#if GTK_CHECK_VERSION (2, 22, 0)

void gtk_expander_set_label_fill (GtkExpander *expander, gboolean label_fill);

gboolean gtk_expander_get_label_fill (GtkExpander *expander);

#endif /* 2.22 */
