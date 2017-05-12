/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
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
this is a GtkObject subclass.  no variants are necessary.
*/

/*
this is also used from gtk_tree_view_insert_column_with_cell_data_func.
*/

GPerlCallback *
gtk2perl_tree_cell_data_func_create (SV * func, SV * data)
{
	GType param_types [4];
	param_types[0] = GTK_TYPE_TREE_VIEW_COLUMN;
	param_types[1] = GTK_TYPE_CELL_RENDERER;
	param_types[2] = GTK_TYPE_TREE_MODEL;
	param_types[3] = GTK_TYPE_TREE_ITER;
	return gperl_callback_new (func, data, 
	                           G_N_ELEMENTS (param_types), param_types,
	                           0);
}

/*
 * GPerlCallback handler for GtkTreeCellDataFunc.
 */
void
gtk2perl_tree_cell_data_func (GtkTreeViewColumn * tree_column,
                              GtkCellRenderer * cell,
                              GtkTreeModel * tree_model,
                              GtkTreeIter * iter,
                              gpointer data)
{
	gperl_callback_invoke ((GPerlCallback*)data, NULL,
	                       tree_column, cell, tree_model, iter);
}






#define check_stack_for_attributes(first) (0 == ((items - (first)) % 2))

#define set_attributes_from_arg_stack(column, cell_renderer, first)	\
{									\
	int i;								\
	for (i = first ; i < items ; i+=2) {				\
		gtk_tree_view_column_add_attribute (column, cell_renderer,	\
		                                    SvGChar (ST (i)),	\
		                                    SvIV (ST (i+1)));	\
	}								\
}


MODULE = Gtk2::TreeViewColumn	PACKAGE = Gtk2::TreeViewColumn	PREFIX = gtk_tree_view_column_

GtkTreeViewColumn *
gtk_tree_view_column_new (class)
    C_ARGS:
	/*void*/

=for apidoc
=for signature treeviewcolumn = Gtk2::TreeViewColumn->new_with_attributes ($title, $cell, $attr1, $col1, ...)
=for arg attr1 (string) the first attribute
=for arg col1 (integer) the first column
=for arg ... pairs of attributes and columns
=cut
GtkTreeViewColumn *
gtk_tree_view_column_new_with_attributes (class, title, cell, ...)
	const gchar * title
	GtkCellRenderer * cell
    CODE:
	if (!check_stack_for_attributes (3))
		croak ("Usage: Gtk2::TreeViewColumn->new_with_attributes (title, cellrenderer, attr1, col1, ...)");
	RETVAL = gtk_tree_view_column_new ();
	gtk_tree_view_column_set_title (RETVAL, title);
	gtk_tree_view_column_pack_start (RETVAL, cell, TRUE);
	set_attributes_from_arg_stack (RETVAL, cell, 3);
    OUTPUT:
	RETVAL


void
gtk_tree_view_column_pack_start (tree_column, cell, expand)
	GtkTreeViewColumn *tree_column
	GtkCellRenderer *cell
	gboolean expand

void
gtk_tree_view_column_pack_end (tree_column, cell, expand)
	GtkTreeViewColumn *tree_column
	GtkCellRenderer *cell
	gboolean expand

void
gtk_tree_view_column_clear (tree_column)
	GtkTreeViewColumn *tree_column


## GList* gtk_tree_view_column_get_cell_renderers (GtkTreeViewColumn *tree_column);
=for apidoc
Returns a list of Gtk2::CellRenderer's.
=cut
void
gtk_tree_view_column_get_cell_renderers (tree_column)
	GtkTreeViewColumn * tree_column
    PREINIT:
	GList * renderers, * i;
    PPCODE:
	renderers = gtk_tree_view_column_get_cell_renderers (tree_column);
	EXTEND (SP, (int)g_list_length (renderers));
	for (i = renderers ; i ; i = i->next)
		PUSHs (sv_2mortal (newSVGtkCellRenderer (GTK_CELL_RENDERER (i->data))));
	g_list_free (renderers);

void
gtk_tree_view_column_add_attribute (tree_column, cell_renderer, attribute, column)
	GtkTreeViewColumn *tree_column
	GtkCellRenderer *cell_renderer
	const gchar *attribute
	gint column

#### void gtk_tree_view_column_set_attributes (GtkTreeViewColumn *tree_column, GtkCellRenderer *cell_renderer, ...)
=for apidoc
=for arg attr1 (string) the first attribute
=for arg col1 (integer) the first column
=for arg ... pairs of attributes and columns
=cut
void
gtk_tree_view_column_set_attributes (tree_column, cell_renderer, ...)
	GtkTreeViewColumn *tree_column
	GtkCellRenderer *cell_renderer
    CODE:
	if (!check_stack_for_attributes (2))
		croak ("Usage: $treeviewcolumn->set_attributes (cellrenderer, attr1, col1, ...)");
	set_attributes_from_arg_stack (tree_column, cell_renderer, 2);

#### void gtk_tree_view_column_set_cell_data_func (GtkTreeViewColumn *tree_column, GtkCellRenderer *cell_renderer, GtkTreeCellDataFunc func, gpointer func_data, GtkDestroyNotify destroy)
=for apidoc
=for arg func (subroutine)
Install I<$func> as the callback to be used whenever I<$column> needs to set up
I<$cell> to render a cell.  I<$func> should look like this:

  sub cell_data_func {
    my ($column, $cell, $model, $iter, $func_data) = @_;
  }

and should set whatever properties of I<$cell> are required for it to draw
the data properly.  No return value is expected.
=cut
void
gtk_tree_view_column_set_cell_data_func (tree_column, cell_renderer, func, data=NULL)
	GtkTreeViewColumn *tree_column
	GtkCellRenderer *cell_renderer
	SV * func
	SV * data
    PREINIT:
	GPerlCallback * callback;
    CODE:
	callback = gtk2perl_tree_cell_data_func_create (func, data);
	gtk_tree_view_column_set_cell_data_func (tree_column, cell_renderer,
	                                         gtk2perl_tree_cell_data_func,
	                                         callback,
	                                         (GDestroyNotify)
						    gperl_callback_destroy);

void
gtk_tree_view_column_clear_attributes (tree_column, cell_renderer)
	GtkTreeViewColumn *tree_column
	GtkCellRenderer *cell_renderer

void
gtk_tree_view_column_set_spacing (tree_column, spacing)
	GtkTreeViewColumn *tree_column
	gint spacing

gint
gtk_tree_view_column_get_spacing (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_visible (tree_column, visible)
	GtkTreeViewColumn *tree_column
	gboolean visible

gboolean
gtk_tree_view_column_get_visible (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_resizable (tree_column, resizable)
	GtkTreeViewColumn *tree_column
	gboolean resizable

gboolean
gtk_tree_view_column_get_resizable (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_sizing (tree_column, type)
	GtkTreeViewColumn *tree_column
	GtkTreeViewColumnSizing type

GtkTreeViewColumnSizing
gtk_tree_view_column_get_sizing (tree_column)
	GtkTreeViewColumn *tree_column

gint
gtk_tree_view_column_get_width (tree_column)
	GtkTreeViewColumn *tree_column

gint
gtk_tree_view_column_get_fixed_width (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_fixed_width (tree_column, fixed_width)
	GtkTreeViewColumn *tree_column
	gint fixed_width

void
gtk_tree_view_column_set_min_width (tree_column, min_width)
	GtkTreeViewColumn *tree_column
	gint min_width

gint
gtk_tree_view_column_get_min_width (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_max_width (tree_column, max_width)
	GtkTreeViewColumn *tree_column
	gint max_width

gint
gtk_tree_view_column_get_max_width (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_clicked (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_title (tree_column, title)
	GtkTreeViewColumn *tree_column
	const gchar *title

const gchar *
gtk_tree_view_column_get_title (tree_column)
	GtkTreeViewColumn *tree_column

#if GTK_CHECK_VERSION(2,4,0)

void gtk_tree_view_column_set_expand (GtkTreeViewColumn *tree_column, gboolean expand);

gboolean gtk_tree_view_column_get_expand (GtkTreeViewColumn *tree_column);

#endif

void
gtk_tree_view_column_set_clickable (tree_column, clickable)
	GtkTreeViewColumn *tree_column
	gboolean clickable

gboolean
gtk_tree_view_column_get_clickable (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_widget (tree_column, widget)
	GtkTreeViewColumn *tree_column
	GtkWidget_ornull *widget

GtkWidget_ornull*
gtk_tree_view_column_get_widget (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_alignment (tree_column, xalign)
	GtkTreeViewColumn *tree_column
	gfloat xalign

gfloat
gtk_tree_view_column_get_alignment (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_reorderable (tree_column, reorderable)
	GtkTreeViewColumn *tree_column
	gboolean reorderable

gboolean
gtk_tree_view_column_get_reorderable (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_sort_column_id (tree_column, sort_column_id)
	GtkTreeViewColumn *tree_column
	gint sort_column_id

gint
gtk_tree_view_column_get_sort_column_id (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_sort_indicator (tree_column, setting)
	GtkTreeViewColumn *tree_column
	gboolean setting

gboolean
gtk_tree_view_column_get_sort_indicator (tree_column)
	GtkTreeViewColumn *tree_column

void
gtk_tree_view_column_set_sort_order (tree_column, order)
	GtkTreeViewColumn *tree_column
	GtkSortType order

GtkSortType
gtk_tree_view_column_get_sort_order (tree_column)
	GtkTreeViewColumn *tree_column

#### void gtk_tree_view_column_cell_set_cell_data (GtkTreeViewColumn *tree_column, GtkTreeModel *tree_model, GtkTreeIter *iter, gboolean is_expander, gboolean is_expanded)
void
gtk_tree_view_column_cell_set_cell_data (tree_column, tree_model, iter, is_expander, is_expanded)
	GtkTreeViewColumn *tree_column
	GtkTreeModel *tree_model
	GtkTreeIter *iter
	gboolean is_expander
	gboolean is_expanded

#### void gtk_tree_view_column_cell_get_size (GtkTreeViewColumn *tree_column, GdkRectangle *cell_area, gint *x_offset, gint *y_offset, gint *width, gint *height)
void
gtk_tree_view_column_cell_get_size (tree_column)
	GtkTreeViewColumn *tree_column
    PREINIT:
	GdkRectangle cell_area = {0};
	gint x_offset = 0, y_offset = 0, width = 0, height = 0;
    PPCODE:
	/* PUTBACK/SPAGAIN because gtk_tree_view_column_cell_get_size()
	   calls out to its renderers, which may be perl */
	PUTBACK;
	gtk_tree_view_column_cell_get_size (tree_column, &cell_area, &x_offset, &y_offset, &width, &height);
	SPAGAIN;
	EXTEND (sp, 5);
	PUSHs (sv_2mortal (newSViv (x_offset)));
	PUSHs (sv_2mortal (newSViv (y_offset)));
	PUSHs (sv_2mortal (newSViv (width)));
	PUSHs (sv_2mortal (newSViv (height)));
	PUSHs (sv_2mortal (newSVGdkRectangle (&cell_area)));

#### gboolean gtk_tree_view_column_cell_is_visible (GtkTreeViewColumn *tree_column)
gboolean
gtk_tree_view_column_cell_is_visible (tree_column)
	GtkTreeViewColumn *tree_column

### not documented as such, but this doesn't appear to exist in 2.0.6

#if GTK_CHECK_VERSION(2,2,0)

# FIXME: The boolean return value should not be ignored.
#### gboolean gtk_tree_view_column_cell_get_position (GtkTreeViewColumn *tree_column, GtkCellRenderer *cell_renderer, gint *start_pos, gint *width)
void
gtk_tree_view_column_cell_get_position (GtkTreeViewColumn *tree_column, GtkCellRenderer *cell_renderer, OUTLIST gint start_pos, OUTLIST gint width)

#endif

#if GTK_CHECK_VERSION(2,2,0)

void
gtk_tree_view_column_focus_cell (tree_column, cell)
	GtkTreeViewColumn *tree_column
	GtkCellRenderer *cell

#endif /* >= 2.2.0 */

#if GTK_CHECK_VERSION (2, 8, 0)

void gtk_tree_view_column_queue_resize (GtkTreeViewColumn *tree_column);

#endif

#if GTK_CHECK_VERSION (2, 12, 0)

GtkWidget_ornull * gtk_tree_view_column_get_tree_view (GtkTreeViewColumn *tree_column);

#endif

MODULE = Gtk2::TreeViewColumn	PACKAGE = Gtk2::TreeView	PREFIX = gtk_tree_view_

### this is implemented in here instead of GtkTreeView.xs so it can
### get access to a static helper function used to parse the stack
### for attributes.

## gint gtk_tree_view_insert_column_with_attributes (GtkTreeView *tree_view, gint position, const gchar *title, GtkCellRenderer *cell, ...)
=for apidoc
=for signature $tree_view->insert_column_with_attributes ($position, $title, $cellrenderer, $attr1, $col1, $attr2, $col2, ...)
=cut
gint
gtk_tree_view_insert_column_with_attributes (tree_view, position, title, cell, ...)
	GtkTreeView *tree_view
	gint position
	const gchar *title
	GtkCellRenderer *cell
    PREINIT:
	GtkTreeViewColumn * column;
    CODE:
	if (!check_stack_for_attributes (4))
		croak ("Usage: Gtk2::TreeView::insert_column_with_attributes(tree_view, position, title, cell_renderer, attr1, col1, attr2, col2, ...)");
	column = gtk_tree_view_column_new ();
	RETVAL = gtk_tree_view_insert_column (tree_view, column, position);
	gtk_tree_view_column_set_title (column, title);
	gtk_tree_view_column_pack_start (column, cell, TRUE);
	set_attributes_from_arg_stack (column, cell, 4);
    OUTPUT:
	RETVAL

