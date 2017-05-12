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

/* ------------------------------------------------------------------------- */

#define PREP		\
	dSP;		\
	ENTER;		\
	SAVETMPS;	\
	PUSHMARK (SP);	\
	PUSHs (sv_2mortal (newSVGObject (G_OBJECT (sortable))));

#define CALL		\
	PUTBACK;	\
	call_sv ((SV *)GvCV (slot), G_VOID|G_DISCARD);

#define FINISH		\
	FREETMPS;	\
	LEAVE;

#define GET_METHOD(method)	\
	HV * stash = gperl_object_stash_from_type (G_OBJECT_TYPE (sortable)); \
	GV * slot = gv_fetchmethod (stash, method);

#define METHOD_EXISTS (slot && GvCV (slot))

/* ------------------------------------------------------------------------- */

static gboolean
gtk2perl_tree_sortable_get_sort_column_id (GtkTreeSortable *sortable,
                                           gint            *sort_column_id,
                                           GtkSortType     *order)
{
	gboolean retval = FALSE;
	gint real_sort_column_id;
	GtkSortType real_order;
	GET_METHOD ("GET_SORT_COLUMN_ID");

	if (METHOD_EXISTS) {
		PREP;
		PUTBACK;

		if (3 != call_sv ((SV *) GvCV (slot), G_ARRAY))
			croak ("GET_SORT_COLUMN_ID must return a boolean "
			       "indicating whether the column is not special, "
			       "the sort column id and the sort order");

		SPAGAIN;

		real_order = SvGtkSortType (POPs);
		real_sort_column_id = POPi;
		retval = POPu;

		PUTBACK;
		FINISH;

		if (sort_column_id)
			*sort_column_id = real_sort_column_id;
		if (order)
			*order = real_order;
	}

	return retval;
}

/* ------------------------------------------------------------------------- */

static void
gtk2perl_tree_sortable_set_sort_column_id (GtkTreeSortable *sortable,
                                           gint             sort_column_id,
                                           GtkSortType      order)
{
	GET_METHOD ("SET_SORT_COLUMN_ID");

	if (METHOD_EXISTS) {
		PREP;
		XPUSHs (sv_2mortal (newSViv (sort_column_id)));
		XPUSHs (sv_2mortal (newSVGtkSortType (order)));
		CALL;
		FINISH;
	}
}

/* ------------------------------------------------------------------------- */

/* The strategy: Put the given function pointer, user data and destruction
 * notification pointer into a struct.  Make an IV SV pointing to that struct.
 * Create a blessed reference around this SV which has &{} overloading.  When
 * the Perl programmer then invokes this SV, we recreate every necessary bit in
 * the invoke handler and call the C function. */

typedef struct {
	GtkTreeIterCompareFunc func;
	gpointer data;
	GtkDestroyNotify destroy;
} Gtk2PerlTreeIterCompareFunc;

static void
create_callback (GtkTreeIterCompareFunc func,
                 gpointer               data,
                 GtkDestroyNotify       destroy,
		 SV                   **code_return,
                 SV                   **data_return)
{
	HV *stash;
	SV *code_sv, *data_sv;
	Gtk2PerlTreeIterCompareFunc *stuff;

	stuff = g_new0 (Gtk2PerlTreeIterCompareFunc, 1);
	stuff->func = func;
	stuff->data = data;
	stuff->destroy = destroy;
	data_sv = newSViv (PTR2IV (stuff));

	stash = gv_stashpv ("Gtk2::TreeSortable::IterCompareFunc", TRUE);
	code_sv = sv_bless (newRV (data_sv), stash);

	*code_return = code_sv;
	*data_return = data_sv;
}

static void
gtk2perl_tree_sortable_set_sort_func (GtkTreeSortable       *sortable,
                                      gint                   sort_column_id,
                                      GtkTreeIterCompareFunc func,
                                      gpointer               data,
                                      GtkDestroyNotify       destroy)
{
	GET_METHOD ("SET_SORT_FUNC");

	if (METHOD_EXISTS) {
		SV *code, *my_data;
		PREP;

		create_callback (func, data, destroy, &code, &my_data);

		XPUSHs (sv_2mortal (newSViv (sort_column_id)));
		XPUSHs (sv_2mortal (code));
		XPUSHs (sv_2mortal (my_data));

		CALL;

		FINISH;
	}
}

static void
gtk2perl_tree_sortable_set_default_sort_func (GtkTreeSortable       *sortable,
                                              GtkTreeIterCompareFunc func,
                                              gpointer               data,
                                              GtkDestroyNotify       destroy)
{
	GET_METHOD ("SET_DEFAULT_SORT_FUNC");

	if (METHOD_EXISTS) {
		SV *code, *my_data;
		PREP;

		create_callback (func, data, destroy, &code, &my_data);

		XPUSHs (sv_2mortal (newSVsv (code)));
		XPUSHs (sv_2mortal (newSVsv (my_data)));

		CALL;

		FINISH;
	}
}

/* ------------------------------------------------------------------------- */

static gboolean
gtk2perl_tree_sortable_has_default_sort_func (GtkTreeSortable *sortable)
{
	gboolean retval = FALSE;
	GET_METHOD ("HAS_DEFAULT_SORT_FUNC");

	if (METHOD_EXISTS) {
		PREP;
		PUTBACK;

		if (1 != call_sv ((SV *) GvCV (slot), G_SCALAR))
			croak ("HAS_DEFAULT_SORT_FUNC must return a boolean");

		SPAGAIN;

		retval = POPu;

		PUTBACK;
		FINISH;
	}

	return retval;
}

/* ------------------------------------------------------------------------- */

static void
gtk2perl_tree_sortable_init (GtkTreeSortableIface * iface)
{
	iface->get_sort_column_id = gtk2perl_tree_sortable_get_sort_column_id;
	iface->set_sort_column_id = gtk2perl_tree_sortable_set_sort_column_id;
	iface->set_sort_func = gtk2perl_tree_sortable_set_sort_func;
	iface->set_default_sort_func = gtk2perl_tree_sortable_set_default_sort_func;
	iface->has_default_sort_func = gtk2perl_tree_sortable_has_default_sort_func;
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
new_sort_func (SV * sort_func, SV * user_data)
{
	GType param_types[3];
	param_types[0] = GTK_TYPE_TREE_MODEL;
	param_types[1] = GTK_TYPE_TREE_ITER;
	param_types[2] = GTK_TYPE_TREE_ITER;
	return gperl_callback_new (sort_func, user_data,
	                           3, param_types, G_TYPE_INT);
}

static gint
gtk2perl_tree_iter_compare_func (GtkTreeModel *model,
                                 GtkTreeIter *a,
                                 GtkTreeIter *b,
                                 gpointer user_data)
{
	gint ret;
	GValue retval = {0,};
	GPerlCallback * callback = (GPerlCallback*) user_data;

	g_value_init (&retval, callback->return_type);
	gperl_callback_invoke (callback, &retval, model, a, b);
	ret = g_value_get_int (&retval);
	g_value_unset (&retval);

	return ret;
}

/* ------------------------------------------------------------------------- */

MODULE = Gtk2::TreeSortable	PACKAGE = Gtk2::TreeSortable	PREFIX = gtk_tree_sortable_

=for position post_methods

=head1 IMPLEMENTING THE I<GtkTreeSortable> INTERACE

If you want your custom tree model to be sortable, you need to implement the
I<GtkTreeSortable> interface.  Just like with other interfaces, this boils down
to announcing that your subclass implements the interface and providing a few
virtual methods.  The former is achieved by adding C<Gtk2::TreeSortable> to the
C<interfaces> key.  For example:

  package MyModel;
  use Gtk2;
  use Glib::Object::Subclass
      Glib::Object::,
      interfaces => [ Gtk2::TreeModel::, Gtk2::TreeSortable:: ],
      ;

The virtual methods you need to implement are listed below.

=head2 VIRTUAL METHODS

These virtual methods are called by perl when gtk+ attempts to modify the
sorting behavior of your model.  Implement them in your model's package.  Note
that we don't provide a wrapper for I<sort_column_changed> because there is a
signal for it, which means you can use the normal signal overriding mechanism
documented in L<Glib::Object::Subclass>.

=over

=item (is_not_special, id, order) = GET_SORT_COLUMN_ID ($model)

Returns a boolean indicating whether the column is a special or normal one, its
id and its sorting order.

=item SET_SORT_COLUMN_ID ($list, $id, $order)

Sets the sort column to the one specified by I<$id> and the sorting order to
I<$order>.

=item SET_SORT_FUNC ($list, $id, $func, $data)

Sets the function that is to be used for sorting the column I<$id>.

=item SET_DEFAULT_SORT_FUNC ($list, $func, $data)

Sets the function that is to be used for sorting columns that don't have a
sorting function attached to them.

The I<$func> and I<$data> arguments passed to these two methods should be
treated as blackboxes.  They are generic containers for some callback that is
to be invoked whenever you want to compare two tree iters.  When you call them,
make sure to always pass I<$data>.  For example:

  $retval = $func->($list, $a, $b, $data);

=item bool = HAS_DEFAULT_SORT_FUNC ($list)

Returns a bool indicating whether I<$list> has a default sorting function.

=back

=cut

=for apidoc __hide__
=cut
void
_ADD_INTERFACE (class, const char * target_class)
    CODE:
    {
	static const GInterfaceInfo iface_info = {
		(GInterfaceInitFunc) gtk2perl_tree_sortable_init,
		(GInterfaceFinalizeFunc) NULL,
		(gpointer) NULL
	};
	GType gtype = gperl_object_type_from_package (target_class);
	g_type_add_interface_static (gtype, GTK_TYPE_TREE_SORTABLE,
	                &iface_info);
    }

## void gtk_tree_sortable_sort_column_changed (GtkTreeSortable *sortable)
void
gtk_tree_sortable_sort_column_changed (sortable)
	GtkTreeSortable *sortable

# FIXME: This is incorrectly bound.  The boolean return value is meant to
# indicate whether sort_column_id is a regular column or the default or an
# invalid one.  It says nothing about whether sort_column_id and order were
# set.  I don't see how we could fix this without breaking API compatibility.
#### gboolean gtk_tree_sortable_get_sort_column_id (GtkTreeSortable *sortable, gint *sort_column_id, GtkSortType *order)
=for apidoc
=for signature (sort_column_id, order) = $sortable->get_sort_column_id
Returns sort_column_id, an integer and order, a Gtk2::SortType.
=cut
void
gtk_tree_sortable_get_sort_column_id (sortable)
	GtkTreeSortable *sortable
    PREINIT:
	gint sort_column_id;
	GtkSortType order;
    PPCODE:
	PUTBACK;
	if (!gtk_tree_sortable_get_sort_column_id (sortable, &sort_column_id,
	                                           &order))
		XSRETURN_EMPTY;
	SPAGAIN;
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSViv (sort_column_id)));
	PUSHs (sv_2mortal (newSVGtkSortType (order)));

## void gtk_tree_sortable_set_sort_column_id (GtkTreeSortable *sortable, gint sort_column_id, GtkSortType order)
void
gtk_tree_sortable_set_sort_column_id (sortable, sort_column_id, order)
	GtkTreeSortable *sortable
	gint sort_column_id
	GtkSortType order

#### void gtk_tree_sortable_set_sort_func (GtkTreeSortable *sortable, gint sort_column_id, GtkTreeIterCompareFunc sort_func, gpointer user_data, GtkDestroyNotify destroy)
void
gtk_tree_sortable_set_sort_func (sortable, sort_column_id, sort_func, user_data=NULL)
	GtkTreeSortable *sortable
	gint sort_column_id
	SV * sort_func
	SV * user_data
    CODE:
	gtk_tree_sortable_set_sort_func (sortable, sort_column_id,
	                                 gtk2perl_tree_iter_compare_func,
	                                 new_sort_func (sort_func, user_data),
	                                 (GtkDestroyNotify)
	                                       gperl_callback_destroy);

#### void gtk_tree_sortable_set_default_sort_func (GtkTreeSortable *sortable, GtkTreeIterCompareFunc sort_func, gpointer user_data, GtkDestroyNotify destroy)
void
gtk_tree_sortable_set_default_sort_func (sortable, sort_func, user_data=NULL)
	GtkTreeSortable *sortable
	SV * sort_func
	SV * user_data
    CODE:
	if (!gperl_sv_is_defined (sort_func)) {
		gtk_tree_sortable_set_default_sort_func
					(sortable, NULL, NULL, NULL);
	} else {
		gtk_tree_sortable_set_default_sort_func
				(sortable, 
				 gtk2perl_tree_iter_compare_func,
		                 new_sort_func (sort_func, user_data),
				 (GtkDestroyNotify) gperl_callback_destroy);
	}

## gboolean gtk_tree_sortable_has_default_sort_func (GtkTreeSortable *sortable)
gboolean
gtk_tree_sortable_has_default_sort_func (sortable)
	GtkTreeSortable *sortable

MODULE = Gtk2::TreeSortable	PACKAGE = Gtk2::TreeSortable::IterCompareFunc

=for apidoc __hide__
=cut
gint
invoke (code, model, a, b, data)
	SV *code
	GtkTreeModel *model
	GtkTreeIter *a
	GtkTreeIter *b
    PREINIT:
	Gtk2PerlTreeIterCompareFunc *stuff;
    CODE:
	stuff = INT2PTR (Gtk2PerlTreeIterCompareFunc*, SvIV (SvRV (code)));
	if (!stuff || !stuff->func)
		croak ("Invalid reference encountered in iter compare func");
	RETVAL = stuff->func (model, a, b, stuff->data);
    OUTPUT:
	RETVAL

void
DESTROY (code)
	SV *code
    PREINIT:
	Gtk2PerlTreeIterCompareFunc *stuff;
    CODE:
	if (!gperl_sv_is_defined (code) || !SvROK (code))
		return;
	stuff = INT2PTR (Gtk2PerlTreeIterCompareFunc*, SvIV (SvRV (code)));
	if (stuff && stuff->destroy)
		stuff->destroy (stuff->data);
	if (stuff)
		g_free (stuff);
