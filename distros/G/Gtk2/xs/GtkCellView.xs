/*
 * Copyright (c) 2004 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::CellView PACKAGE = Gtk2::CellView PREFIX = gtk_cell_view_

GtkWidget * gtk_cell_view_new (class)
    C_ARGS:
	/* void */

GtkWidget * gtk_cell_view_new_with_text (class, text)
	const gchar * text
    C_ARGS:
	text

GtkWidget * gtk_cell_view_new_with_markup (class, markup)
	const gchar * markup
    C_ARGS:
	markup

GtkWidget * gtk_cell_view_new_with_pixbuf (class, pixbuf)
	GdkPixbuf * pixbuf
    C_ARGS:
	pixbuf

void gtk_cell_view_set_model (GtkCellView * cell_view, GtkTreeModel_ornull * model);

void gtk_cell_view_set_displayed_row (GtkCellView * cell_view, GtkTreePath * path);

GtkTreePath_own * gtk_cell_view_get_displayed_row (GtkCellView * cell_view);

## gboolean gtk_cell_view_get_size_of_row (GtkCellView * cell_view, GtkTreePath * path, GtkRequisition * requisition);
GtkRequisition_copy *
gtk_cell_view_get_size_of_row (GtkCellView * cell_view, GtkTreePath * path)
    PREINIT:
	GtkRequisition requisition;
    CODE:
	gtk_cell_view_get_size_of_row (cell_view, path, &requisition);
	RETVAL = &requisition;
    OUTPUT:
	RETVAL

void gtk_cell_view_set_background_color (GtkCellView * cell_view, const GdkColor * color);

## GList * gtk_cell_view_get_cell_renderers (GtkCellView * cellview);
void
gtk_cell_view_get_cell_renderers (GtkCellView * cellview);
    PREINIT:
	GList * list;
    PPCODE:
	list = gtk_cell_view_get_cell_renderers (cellview);
	if (list)
	{
		GList * curr;

		for (curr = list; curr; curr = g_list_next (curr))
			XPUSHs (sv_2mortal (newSVGtkCellRenderer (curr->data)));

		g_list_free (list);
	}
	else
		XSRETURN_EMPTY;

#if GTK_CHECK_VERSION (2, 16, 0)

GtkTreeModel_ornull * gtk_cell_view_get_model (GtkCellView * cellview);

#endif /* 2.16 */
