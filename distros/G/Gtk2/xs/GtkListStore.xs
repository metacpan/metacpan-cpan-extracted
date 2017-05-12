/*
 * Copyright (c) 2003, 2009 by the gtk2-perl team (see the file AUTHORS)
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



MODULE = Gtk2::ListStore	PACKAGE = Gtk2::ListStore	PREFIX = gtk_list_store_

BOOT:
	/* must prepend TreeModel in the hierarchy so that
	 * Gtk2::TreeModel::get isn't masked by Glib::Object::get.
	 * should we change the api to something unique, instead? */
	gperl_prepend_isa ("Gtk2::ListStore", "Gtk2::TreeModel");

## GtkListStore* gtk_list_store_new (gint n_columns, ...);
=for apidoc
=for arg ... of strings
=cut
GtkListStore_noinc*
gtk_list_store_new (class, ...)
    PREINIT:
	GArray * typearray;
    CODE:
	GTK2PERL_STACK_ITEMS_TO_GTYPE_ARRAY (typearray, 1, items-1);
	RETVAL = gtk_list_store_newv (typearray->len, (GType*)typearray->data);
	g_array_free (typearray, TRUE);
    OUTPUT:
	RETVAL


# for initializing GListStores derived in perl
## void gtk_list_store_set_column_types (GtkListStore *list_store, gint n_columns, GType *types)
=for apidoc
=for arg ... of strings
=cut
void
gtk_list_store_set_column_types (list_store, ...)
	GtkListStore *list_store
    PREINIT:
	GArray * typearray;
    CODE:
	GTK2PERL_STACK_ITEMS_TO_GTYPE_ARRAY (typearray, 1, items-1);
	gtk_list_store_set_column_types (list_store, typearray->len,
	                                 (GType*)(typearray->data));
	g_array_free (typearray, TRUE);


## void gtk_list_store_set (GtkListStore *list_store, GtkTreeIter *iter, ...)
=for apidoc Gtk2::ListStore::set_value
=for signature $list_store->set_value ($iter, $col, $val)
=for arg col (integer)
=for arg val (scalar)
=for arg col1 (__hide__)
=for arg val1 (__hide__)
=for arg ... (__hide__)
=cut

=for apidoc
=for arg col1 (integer) the first column number
=for arg val1 (scalar) the first value
=for arg ... pairs of column numbers and values
=cut
void
gtk_list_store_set (list_store, iter, col1, val1, ...)
	GtkListStore *list_store
	GtkTreeIter *iter
    ALIAS:
	Gtk2::ListStore::set_value = 1
    PREINIT:
	int i, ncols;
    CODE:
	PERL_UNUSED_VAR (ix);
	/* require at least one pair --- that means there needs to be
	 * four items on the stack.  also require that the stack has an
	 * even number of items on it. */
	if (items < 4 || 0 != (items % 2)) {
		/* caller didn't specify an even number of parameters... */
		croak ("Usage: $liststore->set ($iter, column1, value1, column2, value2, ...)\n"
		       "   there must be a value for every column number");
	}
	ncols = gtk_tree_model_get_n_columns (GTK_TREE_MODEL (list_store));
	for (i = 2 ; i < items ; i+= 2) {
		gint column;
		GValue gvalue = {0, };
		if (!looks_like_number (ST (i)))
			croak ("Usage: $liststore->set ($iter, column1, value1, column2, value2, ...)\n"
			       "   the first value in each pair must be a column number");
		column = SvIV (ST (i));

		/* warn ("  %d   %d   %s\n", i, column, SvPV_nolen (ST (i+1))); */

		if (column >= 0 && column < ncols) {

			g_value_init (&gvalue,
			              gtk_tree_model_get_column_type
			                        (GTK_TREE_MODEL (list_store),
			                         column));
			/* gperl_value_from_sv either succeeds or croaks. */
			gperl_value_from_sv (&gvalue, ST (i+1));
			gtk_list_store_set_value (GTK_LIST_STORE (list_store),
			                          iter, column, &gvalue);
			g_value_unset (&gvalue);

		} else {
			warn ("can't set value for column %d, model only has %d columns",
			      column, ncols);
		}
	}


## see Gtk2::ListStore::set
## void gtk_list_store_set_valist (GtkListStore *list_store, GtkTreeIter *iter, va_list var_args)
### we're trying to hide things like GValue from the perl level!
### void gtk_list_store_set_value (GtkListStore *list_store, GtkTreeIter *iter, gint column, GValue *value)

## gboolean gtk_list_store_remove (GtkListStore *list_store, GtkTreeIter *iter)
=for apidoc
The return is always a boolean in the style of Gtk 2.2.x and up, even
when running on Gtk 2.0.x.
=cut
gboolean
gtk_list_store_remove (list_store, iter)
	GtkListStore *list_store
	GtkTreeIter *iter
    CODE:
#if GTK_CHECK_VERSION(2,2,0)
	RETVAL = gtk_list_store_remove (list_store, iter);
#else
	/* void return in 2.0.x; look for stamp is zapped to 0 if no more
	 * rows, to emulate the return value of 2.2 and up
	 */
	gtk_list_store_remove (list_store, iter);
	RETVAL = (iter->stamp != 0);
#endif
    OUTPUT:
	RETVAL

## void gtk_list_store_insert (GtkListStore *list_store, GtkTreeIter *iter, gint position)
GtkTreeIter_copy *
gtk_list_store_insert (list_store, position)
	GtkListStore *list_store
	gint position
    PREINIT:
	GtkTreeIter iter = {0,};
    CODE:
	gtk_list_store_insert (list_store, &iter, position);
	RETVAL = &iter; /* the _copy on the return type means we'll copy
			 * this before the function returns. */
    OUTPUT:
	RETVAL

## void gtk_list_store_insert_before (GtkListStore *list_store, GtkTreeIter *iter, GtkTreeIter *sibling)
## void gtk_list_store_insert_after (GtkListStore *list_store, GtkTreeIter *iter, GtkTreeIter *sibling)
GtkTreeIter_copy *
gtk_list_store_insert_before (list_store, sibling)
	GtkListStore       * list_store
	GtkTreeIter_ornull * sibling
    ALIAS:
	Gtk2::ListStore::insert_after = 1
    PREINIT:
	GtkTreeIter iter;
    CODE:
	if (ix == 0)
		gtk_list_store_insert_before (list_store, &iter, sibling);
	else
		gtk_list_store_insert_after (list_store, &iter, sibling);
	RETVAL = &iter;
    OUTPUT:
	RETVAL


#if GTK_CHECK_VERSION (2, 6, 0)

## void gtk_list_store_insert_with_values (GtkListStore *list_store, GtkTreeIter *iter, gint position, ...);
=for apidoc
=for arg position position to insert the new row
=for arg ... pairs of column numbers and values
Like doing insert followed by set, except that insert_with_values emits only
the row-inserted signal, rather than row-inserted, row-changed, and, if the
store is sorted, rows-reordered as in the multiple-operation case.
Since emitting the rows-reordered signal repeatedly can affect the performance
of the program, insert_with_values should generally be preferred when
inserting rows in a sorted list store.
=cut
GtkTreeIter_copy *
gtk_list_store_insert_with_values (GtkListStore *list_store, gint position, ...);
    PREINIT:
	gint n_cols, i;
	GtkTreeIter iter;
	gint * columns = NULL;
	GValue * values = NULL;
	gint n_values;
	const char * errfmt = "Usage: $iter = $liststore->insert_with_values ($position, column1, value1, ...)\n     %s";
    CODE:
	if (items < 2 || 0 != (items % 2))
		croak (errfmt, "There must be a value for every column number");
	/*
	 * we could jump through hoops to prevent leaking arrays and
	 * initialized GValues here on column validation croaks, but
	 * since gperl_value_from_sv() croaks (and we can't catch it
	 * without major work), and since column index validatio errors
	 * mean there's a programming error anyway, we won't worry about
	 * any of that.
	 */
	n_cols = gtk_tree_model_get_n_columns (GTK_TREE_MODEL (list_store));
	n_values = (items - 2) / 2;
	if (n_values > 0) {
		columns = gperl_alloc_temp (sizeof (gint) * n_values);
		/* gperl_alloc_temp() calls memset(), so we don't need to do
		 * anything else special to prepare these GValues. */
		values = gperl_alloc_temp (sizeof (GValue) * n_values);
		for (i = 0 ; i < n_values ; i ++) {
			if (! looks_like_number (ST (2 + i*2)))
				croak (errfmt, "The first value in each pair must be a column index number");
			columns[i] = SvIV (ST (2 + i*2));
			if (! (columns[i] >= 0 && columns[i] < n_cols))
				croak (errfmt, form ("Bad column index %d, model only has %d columns",
						     columns[i], n_cols));
			g_value_init (values + i,
			              gtk_tree_model_get_column_type
			                        (GTK_TREE_MODEL (list_store),
			                         columns[i]));
			gperl_value_from_sv (values + i, ST (2 + i*2 + 1));
		}
	}
	gtk_list_store_insert_with_valuesv (list_store, &iter, position,
					    columns, values, n_values);
	for (i = 0 ; i < n_values ; i++)
		g_value_unset (values + i);
	RETVAL = &iter;
    OUTPUT:
	RETVAL


#endif


## void gtk_list_store_prepend (GtkListStore *list_store, GtkTreeIter *iter)
## void gtk_list_store_append (GtkListStore *list_store, GtkTreeIter *iter)
GtkTreeIter_copy *
gtk_list_store_prepend (list_store)
	GtkListStore *list_store
    ALIAS:
	Gtk2::ListStore::append = 1
    PREINIT:
	GtkTreeIter iter;
    CODE:
	if (ix == 0)
		gtk_list_store_prepend (list_store, &iter);
	else
		gtk_list_store_append (list_store, &iter);
	RETVAL = &iter;
    OUTPUT:
	RETVAL

## void gtk_list_store_clear (GtkListStore *list_store)
void
gtk_list_store_clear (list_store)
	GtkListStore *list_store

#if GTK_CHECK_VERSION(2,2,0)

## warning, slow, use only for debugging
## gboolean gtk_list_store_iter_is_valid (GtkListStore *list_store, GtkTreeIter *iter)
gboolean
gtk_list_store_iter_is_valid (list_store, iter)
	GtkListStore *list_store
	GtkTreeIter *iter

## void gtk_list_store_reorder (GtkListStore *store, gint *new_order)
=for apidoc
=for arg ... of integers the reordered posistions
Reorders store to follow the order indicated by new_order. Note that this
function only works with unsorted stores.

A list of position should be passed, one for each item in the list.
=cut
void
gtk_list_store_reorder (store, ...)
	GtkListStore * store
    PREINIT:
	gint * new_order;
    CODE:
	if( (items-1) != store->length )
		croak("xs: gtk_list_store_reorder: wrong number of "
		      "positions passed");
	items--;
	new_order = (gint*)g_new(gint, items);
	for( ; items > 0; items-- )
		new_order[items-1] = SvIV(ST(items));
	gtk_list_store_reorder(store, new_order);
	g_free(new_order);

## void gtk_list_store_swap (GtkListStore *store, GtkTreeIter *a, GtkTreeIter *b)
void
gtk_list_store_swap (store, a, b)
	GtkListStore * store
	GtkTreeIter  * a
	GtkTreeIter  * b

## void gtk_list_store_move_after (GtkListStore *store, GtkTreeIter *iter, GtkTreeIter *position)
void
gtk_list_store_move_after (store, iter, position)
	GtkListStore       * store
	GtkTreeIter        * iter
	GtkTreeIter_ornull * position

## void gtk_list_store_move_before (GtkListStore *store, GtkTreeIter *iter, GtkTreeIter *position)
void
gtk_list_store_move_before (store, iter, position)
	GtkListStore       * store
	GtkTreeIter        * iter
	GtkTreeIter_ornull * position

#endif /* >= 2.2.0 */
