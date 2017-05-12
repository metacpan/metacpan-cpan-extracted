/*
 * Copyright (c) 2003-2006, 2009 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::TreeStore	PACKAGE = Gtk2::TreeStore	PREFIX = gtk_tree_store_

BOOT:
	/* must prepend TreeModel in the hierarchy so that
	 * Gtk2::TreeModel::get isn't masked by Glib::Object::get.
	 * should we change the api to something unique, instead? */
	gperl_prepend_isa ("Gtk2::TreeStore", "Gtk2::TreeModel");

## GtkTreeStore* gtk_tree_store_new (gint n_columns, ...);
=for apidoc
=for arg ... of strings, package names 
=cut
GtkTreeStore_noinc*
gtk_tree_store_new (class, ...)
    PREINIT:
	GArray * typearray;
    CODE:
	GTK2PERL_STACK_ITEMS_TO_GTYPE_ARRAY (typearray, 1, items-1);
	RETVAL = gtk_tree_store_newv (typearray->len, (GType*)(typearray->data));
	g_array_free (typearray, TRUE);
    OUTPUT:
	RETVAL


# for initializing GtkTreeStores derived in perl.
## void gtk_tree_store_set_column_types (GtkTreeStore *tree_store, gint n_columns, GType *types)
=for apidoc
=for arg ... of strings, package names
=cut
void
gtk_tree_store_set_column_types (tree_store, ...)
	GtkTreeStore *tree_store
    PREINIT:
	GArray * types;
    CODE:
	GTK2PERL_STACK_ITEMS_TO_GTYPE_ARRAY (types, 1, items-1);
	gtk_tree_store_set_column_types (tree_store, types->len,
	                                 (GType*)(types->data));

## void gtk_tree_store_set (GtkTreeStore *tree_store, GtkTreeIter *iter, ...)
=for apidoc Gtk2::TreeStore::set_value
=for arg col1 (integer) the first column number
=for arg val1 (scalar) the first value
=for arg ... pairs of columns and values
Alias for Gtk2::TreeStore::set().
=cut

=for apidoc
=for arg col1 (integer) the first column number
=for arg val1 (scalar) the first value
=for arg ... pairs of columns and values
=cut
void
gtk_tree_store_set (tree_store, iter, col1, val1, ...)
	GtkTreeStore *tree_store
	GtkTreeIter *iter
    ALIAS:
	Gtk2::TreeStore::set_value = 1
    PREINIT:
	int i, ncols;
    CODE:
	PERL_UNUSED_VAR (ix);
	/* require at least one pair --- that means there needs to be
	 * four items on the stack.  also require that the stack has an
	 * even number of items on it. */
	if (items < 4 || 0 != (items % 2)) {
		/* caller didn't specify an even number of parameters... */
		croak ("Usage: $treestore->set ($iter, column1, value1, column2, value2, ...)\n"
		       "   there must be a value for every column number");
	}
	ncols = gtk_tree_model_get_n_columns (GTK_TREE_MODEL (tree_store));
	for (i = 2 ; i < items ; i+= 2) {
		gint column;
		GValue gvalue = {0, };
		if (!looks_like_number (ST (i)))
			croak ("Usage: $treestore->set ($iter, column1, value1, column2, value2, ...)\n"
			       "   the first value in each pair must be a column number");
		column = SvIV (ST (i));

		if (column >= 0 && column < ncols) {

			g_value_init (&gvalue,
			              gtk_tree_model_get_column_type
			                          (GTK_TREE_MODEL (tree_store),
			                           column));
			/* gperl_value_from_sv either succeeds or croaks. */
			gperl_value_from_sv (&gvalue, ST (i+1));
			gtk_tree_store_set_value (GTK_TREE_STORE (tree_store),
			                          iter, column, &gvalue);
			g_value_unset (&gvalue);

		} else {
			warn ("can't set value for column %d, model only has %d columns",
			      column, ncols);
		}
	}

### we're trying to hide things like GValue from the perl level!
## void gtk_tree_store_set_value (GtkTreeStore *tree_store, GtkTreeIter *iter, gint column, GValue *value)
## see Gtk2::TreeStore::set instead
## void gtk_tree_store_set_valist (GtkTreeStore *tree_store, GtkTreeIter *iter, va_list var_args)

## gboolean gtk_tree_store_remove (GtkTreeStore *tree_store, GtkTreeIter *iter)
=for apidoc
The return is always a boolean in the style of Gtk 2.2.x and up, even
when running on Gtk 2.0.x.
=cut
gboolean
gtk_tree_store_remove (tree_store, iter)
	GtkTreeStore *tree_store
	GtkTreeIter *iter
    CODE:
#if GTK_CHECK_VERSION(2,2,0)
	RETVAL = gtk_tree_store_remove (tree_store, iter);
#else
	/* void return in 2.0.x; look for stamp zapped to 0 if no more
	 * rows, to emulate the return value of 2.2 and up
	 */
	gtk_tree_store_remove (tree_store, iter);
	RETVAL = (iter->stamp != 0);
#endif
    OUTPUT:
	RETVAL

## void gtk_tree_store_insert (GtkTreeStore *tree_store, GtkTreeIter *iter, GtkTreeIter *parent, gint position)
GtkTreeIter_copy *
gtk_tree_store_insert (tree_store, parent, position)
	GtkTreeStore       * tree_store
	GtkTreeIter_ornull * parent
	gint                 position
    PREINIT:
	GtkTreeIter iter = {0, };
    CODE:
	gtk_tree_store_insert (tree_store, &iter, parent, position);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

## void gtk_tree_store_insert_before (GtkTreeStore *tree_store, GtkTreeIter *iter, GtkTreeIter *parent, GtkTreeIter *sibling)
## void gtk_tree_store_insert_after (GtkTreeStore *tree_store, GtkTreeIter *iter, GtkTreeIter *parent, GtkTreeIter *sibling)
GtkTreeIter_copy *
gtk_tree_store_insert_before (tree_store, parent, sibling)
	GtkTreeStore       * tree_store
	GtkTreeIter_ornull * parent
	GtkTreeIter_ornull * sibling
    ALIAS:
	Gtk2::TreeStore::insert_after = 1
    PREINIT:
	GtkTreeIter iter;
    CODE:
	if (ix == 0)
		gtk_tree_store_insert_before (tree_store, &iter,
		                              parent, sibling);
	else
		gtk_tree_store_insert_after (tree_store, &iter,
		                             parent, sibling);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

## void gtk_tree_store_prepend (GtkTreeStore *tree_store, GtkTreeIter *iter, GtkTreeIter *parent)
## void gtk_tree_store_append (GtkTreeStore *tree_store, GtkTreeIter *iter, GtkTreeIter *parent)
GtkTreeIter_copy *
gtk_tree_store_prepend (tree_store, parent)
	GtkTreeStore *tree_store
	GtkTreeIter_ornull *parent
    ALIAS:
	Gtk2::TreeStore::append = 1
    PREINIT:
	GtkTreeIter iter;
    CODE:
	if (ix == 0)
		gtk_tree_store_prepend (tree_store, &iter, parent);
	else
		gtk_tree_store_append (tree_store, &iter, parent);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

## gboolean gtk_tree_store_is_ancestor (GtkTreeStore *tree_store, GtkTreeIter *iter, GtkTreeIter *descendant)
gboolean
gtk_tree_store_is_ancestor (tree_store, iter, descendant)
	GtkTreeStore *tree_store
	GtkTreeIter *iter
	GtkTreeIter *descendant

## gint gtk_tree_store_iter_depth (GtkTreeStore *tree_store, GtkTreeIter *iter)
gint
gtk_tree_store_iter_depth (tree_store, iter)
	GtkTreeStore *tree_store
	GtkTreeIter *iter

## void gtk_tree_store_clear (GtkTreeStore *tree_store)
void
gtk_tree_store_clear (tree_store)
	GtkTreeStore *tree_store

#if GTK_CHECK_VERSION(2,2,0)

## warning, slow, use only for debugging
## gboolean gtk_tree_store_iter_is_valid (GtkTreeStore *tree_store, GtkTreeIter *iter)
gboolean
gtk_tree_store_iter_is_valid (tree_store, iter)
	GtkTreeStore *tree_store
	GtkTreeIter *iter

#### void gtk_tree_store_reorder (GtkTreeStore *tree_store, GtkTreeIter *parent, gint *new_order)
=for apidoc
=for arg ... of integer's, the new_order
=cut
void
gtk_tree_store_reorder (tree_store, parent, ...)
	GtkTreeStore       * tree_store
	GtkTreeIter_ornull * parent
   PREINIT:
	gint  * new_order;
	GNode * level;
	GNode * node;
	int     length = 0;
	int     i;
   CODE:
	if( !parent )
		level = ((GNode*)(tree_store->root))->children;
	else
		level = ((GNode*)(parent->user_data))->children;
	/* count nodes */
	node = level;
	while (node)
	{
		length++;
		node = node->next;
	}
	if( (items-2) != length )
		croak("xs: gtk_tree_store_reorder: wrong number of "
		      "positions passed");
	new_order = (gint*)g_new(gint, length);
	for (i = 0 ; i < length ; i++)
		new_order[i] = SvIV (ST (i+2));
	gtk_tree_store_reorder(tree_store, parent, new_order);
	g_free(new_order);

## void gtk_tree_store_swap (GtkTreeStore *tree_store, GtkTreeIter *a, GtkTreeIter *b)
void
gtk_tree_store_swap (tree_store, a, b)
	GtkTreeStore *tree_store
	GtkTreeIter *a
	GtkTreeIter *b

## void gtk_tree_store_move_before (GtkTreeStore *tree_store, GtkTreeIter *iter, GtkTreeIter *position)
void
gtk_tree_store_move_before (tree_store, iter, position)
	GtkTreeStore *tree_store
	GtkTreeIter *iter
	GtkTreeIter_ornull *position

## void gtk_tree_store_move_after (GtkTreeStore *tree_store, GtkTreeIter *iter, GtkTreeIter *position)
void
gtk_tree_store_move_after (tree_store, iter, position)
	GtkTreeStore *tree_store
	GtkTreeIter *iter
	GtkTreeIter_ornull *position

#endif /* >= 2.2.0 */

#if GTK_CHECK_VERSION (2, 10, 0)

=for apidoc
=for arg position position to insert the new row
=for arg ... pairs of column numbers and values
Like doing insert followed by set, except that insert_with_values emits only
the row-inserted signal, rather than row-inserted, row-changed, and, if the
store is sorted, rows-reordered as in the multiple-operation case.
Since emitting the rows-reordered signal repeatedly can affect the performance
of the program, insert_with_values should generally be preferred when
inserting rows in a sorted tree store.
=cut
GtkTreeIter_copy *
gtk_tree_store_insert_with_values (GtkTreeStore *tree_store, GtkTreeIter_ornull *parent, gint position, ...);
    PREINIT:
	gint n_cols, i;
	GtkTreeIter iter;
	gint * columns = NULL;
	GValue * values = NULL;
	gint n_values;
	const char * errfmt = "Usage: $iter = $treestore->insert_with_values ($parent, $position, column1, value1, ...)\n     %s";
    CODE:
	if (items < 3 || 0 != ((items - 3) % 2))
		croak (errfmt, "There must be a value for every column number");
	/*
	 * we could jump through hoops to prevent leaking arrays and
	 * initialized GValues here on column validation croaks, but
	 * since gperl_value_from_sv() croaks (and we can't catch it
	 * without major work), and since column index validation errors
	 * mean there's a programming error anyway, we won't worry about
	 * any of that.
	 */
	n_cols = gtk_tree_model_get_n_columns (GTK_TREE_MODEL (tree_store));
	n_values = (items - 3) / 2;
	if (n_values > 0) {
		columns = gperl_alloc_temp (sizeof (gint) * n_values);
		/* gperl_alloc_temp() calls memset(), so we don't need to do
		 * anything else special to prepare these GValues. */
		values = gperl_alloc_temp (sizeof (GValue) * n_values);
		for (i = 0 ; i < n_values ; i ++) {
			if (! looks_like_number (ST (3 + i*2)))
				croak (errfmt, "The first value in each pair must be a column index number");
			columns[i] = SvIV (ST (3 + i*2));
			if (! (columns[i] >= 0 && columns[i] < n_cols))
				croak (errfmt, form ("Bad column index %d, model only has %d columns",
						     columns[i], n_cols));
			g_value_init (values + i,
			              gtk_tree_model_get_column_type
			                        (GTK_TREE_MODEL (tree_store),
			                         columns[i]));
			gperl_value_from_sv (values + i, ST (3 + i*2 + 1));
		}
	}
	gtk_tree_store_insert_with_valuesv (tree_store, &iter, parent, position,
					    columns, values, n_values);
	for (i = 0 ; i < n_values ; i++)
		g_value_unset (values + i);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

#endif /* 2.10 */
