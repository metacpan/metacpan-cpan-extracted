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

MODULE = Gtk2::TreeModelSort	PACKAGE = Gtk2::TreeModelSort	PREFIX = gtk_tree_model_sort_

# gperl_prepend_isa ("Gtk2::TreeModelSort", "Gtk2::TreeModel") should be here
# but isn't and can't be added now since that'd break compatibility.  Instead,
# we handle get() at runtime in Gtk2.pm.

GtkTreeModelSort_noinc *
gtk_tree_model_sort_new_with_model (class, child_model)
	GtkTreeModel * child_model
    CODE:
	RETVAL = (GtkTreeModelSort *)
	  gtk_tree_model_sort_new_with_model (child_model);
    OUTPUT:
	RETVAL

=for apidoc
=for signature treemodel = Gtk2::TreeModelSort->new ($child_model)
=for signature treemodel = Gtk2::TreeModelSort->new (model => $child_model)
=for arg ... (__hide__)
=for arg child_model (GtkTreeModel*) The tree model to proxy.
Aliases for C<new_with_model>.  Before Gtk2 1.120, C<new> resolved to
C<Glib::Object::new>, which would allow creation of an invalid object if the
required property C<model> was not supplied.
=cut
GtkTreeModelSort_noinc *
gtk_tree_model_sort_new (class, ...)
    PREINIT:
	GtkTreeModel * child_model = NULL;
    CODE:
	if (items == 2)
		/* called as Gtk2::TreeModelSort->new ($model) */
		child_model = SvGtkTreeModel (ST (1));
	else if (items == 3)
		/* called as Gtk2::TreeModelSort->new (model => $model) */
		child_model = SvGtkTreeModel (ST (2));
	else
		croak ("Usage: $sort = Gtk2::TreeModelSort->new ($child_model)\n"
		       "   or  $sort = Gtk2::TreeModelSort->new (model => $child_model)\n"
		       "   ");
	RETVAL = (GtkTreeModelSort *)
	  gtk_tree_model_sort_new_with_model (child_model);
    OUTPUT:
	RETVAL

GtkTreeModel *
gtk_tree_model_sort_get_model (tree_model)
	GtkTreeModelSort * tree_model


GtkTreePath_own_ornull*
gtk_tree_model_sort_convert_child_path_to_path (tree_model_sort, child_path)
	GtkTreeModelSort * tree_model_sort
	GtkTreePath      * child_path

GtkTreePath_own_ornull*
gtk_tree_model_sort_convert_path_to_child_path (tree_model_sort, sorted_path)
	GtkTreeModelSort * tree_model_sort
	GtkTreePath      * sorted_path


## void gtk_tree_model_sort_convert_child_iter_to_iter (GtkTreeModelSort *tree_model_sort, GtkTreeIter *sort_iter, GtkTreeIter *child_iter)
## C version initializes an existing iter for you;
## perl version returns a new iter.

GtkTreeIter_copy *
gtk_tree_model_sort_convert_child_iter_to_iter (tree_model_sort, child_iter)
	GtkTreeModelSort *tree_model_sort
	GtkTreeIter *child_iter
    PREINIT:
	GtkTreeIter sort_iter;
    CODE:
	gtk_tree_model_sort_convert_child_iter_to_iter (tree_model_sort,
	                                                &sort_iter,
	                                                child_iter);
	RETVAL = &sort_iter;
    OUTPUT:
	RETVAL

## void gtk_tree_model_sort_convert_iter_to_child_iter (GtkTreeModelSort *tree_model_sort, GtkTreeIter *child_iter, GtkTreeIter *sorted_iter)
## C version initializes an existing iter for you;
## perl version returns a new iter.

GtkTreeIter_copy *
gtk_tree_model_sort_convert_iter_to_child_iter (tree_model_sort, sorted_iter)
	GtkTreeModelSort *tree_model_sort
	GtkTreeIter *sorted_iter
    PREINIT:
	GtkTreeIter child_iter;
    CODE:
	gtk_tree_model_sort_convert_iter_to_child_iter (tree_model_sort,
	                                                &child_iter,
	                                                sorted_iter);
	RETVAL = &child_iter;
    OUTPUT:
	RETVAL


void
gtk_tree_model_sort_reset_default_sort_func (tree_model_sort)
	GtkTreeModelSort *tree_model_sort


void
gtk_tree_model_sort_clear_cache (tree_model_sort)
	GtkTreeModelSort *tree_model_sort

#if GTK_CHECK_VERSION(2,2,0)

## API docs say to use this only for testing/debugging purposes
gboolean
gtk_tree_model_sort_iter_is_valid (tree_model_sort, iter)
	GtkTreeModelSort *tree_model_sort
	GtkTreeIter *iter

#endif
