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

/*
#define GTK_TYPE_TABLE			(gtk_table_get_type ())
#define GTK_TABLE(obj)			(GTK_CHECK_CAST ((obj), GTK_TYPE_TABLE, GtkTable))
#define GTK_TABLE_CLASS(klass)		(GTK_CHECK_CLASS_CAST ((klass), GTK_TYPE_TABLE, GtkTableClass))
#define GTK_IS_TABLE(obj)		(GTK_CHECK_TYPE ((obj), GTK_TYPE_TABLE))
#define GTK_IS_TABLE_CLASS(klass)	(GTK_CHECK_CLASS_TYPE ((klass), GTK_TYPE_TABLE))
#define GTK_TABLE_GET_CLASS(obj)        (GTK_CHECK_GET_CLASS ((obj), GTK_TYPE_TABLE, GtkTableClass))


typedef struct _GtkTable	GtkTable;
typedef struct _GtkTableClass	GtkTableClass;
typedef struct _GtkTableChild	GtkTableChild;
typedef struct _GtkTableRowCol	GtkTableRowCol;

struct _GtkTable
{
  GtkContainer container;

  GList *children;
  GtkTableRowCol *rows;
  GtkTableRowCol *cols;
  guint16 nrows;
  guint16 ncols;
  guint16 column_spacing;
  guint16 row_spacing;
  guint homogeneous : 1;
};

struct _GtkTableClass
{
  GtkContainerClass parent_class;
};

struct _GtkTableChild
{
  GtkWidget *widget;
  guint16 left_attach;
  guint16 right_attach;
  guint16 top_attach;
  guint16 bottom_attach;
  guint16 xpadding;
  guint16 ypadding;
  guint xexpand : 1;
  guint yexpand : 1;
  guint xshrink : 1;
  guint yshrink : 1;
  guint xfill : 1;
  guint yfill : 1;
};

struct _GtkTableRowCol
{
  guint16 requisition;
  guint16 allocation;
  guint16 spacing;
  guint need_expand : 1;
  guint need_shrink : 1;
  guint expand : 1;
  guint shrink : 1;
  guint empty : 1;
};

*/

MODULE = Gtk2::Table	PACKAGE = Gtk2::Table	PREFIX = gtk_table_


GtkWidget *
gtk_table_new (class, rows, columns, homogeneous=FALSE)
	guint    rows
	guint    columns
	gboolean homogeneous
    C_ARGS:
	rows, columns, homogeneous

void
gtk_table_resize (table, rows, columns)
	GtkTable * table
	guint rows
	guint columns

void
gtk_table_attach (table, child, left_attach, right_attach, top_attach, bottom_attach, xoptions, yoptions, xpadding, ypadding)
	GtkTable        *table
	GtkWidget       *child
	guint		left_attach
	guint		right_attach
	guint		top_attach
	guint		bottom_attach
	GtkAttachOptions xoptions
	GtkAttachOptions yoptions
	guint		xpadding
	guint		ypadding

void
gtk_table_attach_defaults (table, widget, left_attach, right_attach, top_attach, bottom_attach)
	GtkTable        *table
	GtkWidget       *widget
	guint		left_attach
	guint		right_attach
	guint		top_attach
	guint		bottom_attach

void
gtk_table_set_row_spacing  (table, row, spacing)
	GtkTable * table
	guint row
	guint spacing

guint
gtk_table_get_row_spacing  (table, row)
	GtkTable        * table
	guint             row

void
gtk_table_set_col_spacing  (table, column, spacing)
	GtkTable	*table
	guint		column
	guint		spacing

guint
gtk_table_get_col_spacing  (table, column)
	GtkTable        *table
	guint            column

void
gtk_table_set_row_spacings (table, spacing)
	GtkTable	*table
	guint		spacing

guint
gtk_table_get_default_row_spacing (table)
	GtkTable        *table

void
gtk_table_set_col_spacings (table, spacing)
	GtkTable * table
	guint      spacing

guint
gtk_table_get_default_col_spacing (table)
	GtkTable * table

void
gtk_table_set_homogeneous (table, homogeneous)
	GtkTable * table
	gboolean homogeneous

gboolean
gtk_table_get_homogeneous (table)
	GtkTable * table

#if GTK_CHECK_VERSION (2, 22, 0)

void gtk_table_get_size (GtkTable *table, OUTLIST guint rows, OUTLIST guint columns);

#endif /* 2.22 */
