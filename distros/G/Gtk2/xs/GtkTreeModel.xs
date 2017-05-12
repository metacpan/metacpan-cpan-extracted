/*
 * Copyright (c) 2003-2005, 2010, 2012 by the gtk2-perl team (see the file
 * AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"
#include <gperl_marshal.h>

/* this is just an interface */

static gboolean
gtk2perl_tree_model_foreach_func (GtkTreeModel *model,
                                  GtkTreePath *path,
                                  GtkTreeIter *iter,
                                  gpointer data)
{
	GPerlCallback * callback = (GPerlCallback*)data;
	GValue value = {0,};
	gboolean retval;
	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, model, path, iter);
	retval = g_value_get_boolean (&value);
	g_value_unset (&value);
	return retval;
}

static void
gtk2perl_tree_model_rows_reordered_marshal (GClosure * closure,
                                  	    GValue * return_value,
                                  	    guint n_param_values,
                                  	    const GValue * param_values,
                                  	    gpointer invocation_hint,
                                  	    gpointer marshal_data)
{
	AV * av;
	gint * new_order;
	GtkTreeModel * model;
	GtkTreeIter * iter;
	int n_children, i;
	dGPERL_CLOSURE_MARSHAL_ARGS;

	/* If model is a Perl object then gtk_tree_model_iter_n_children()
	   will call out to ITER_N_CHILDREN in the class, so do that before
	   trying to build the stack here. */
	model = g_value_get_object (param_values);
	iter = g_value_get_boxed (param_values+2);
	n_children = gtk_tree_model_iter_n_children (model, iter);

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	PERL_UNUSED_VAR (return_value);
	PERL_UNUSED_VAR (n_param_values);
	PERL_UNUSED_VAR (invocation_hint);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	/* instance */
	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);

	/* treepath */
	XPUSHs (sv_2mortal (gperl_sv_from_value (param_values+1)));

	/* treeiter */
	XPUSHs (sv_2mortal (gperl_sv_from_value (param_values+2)));

	/* gint * new_order */
	new_order = g_value_get_pointer (param_values+3);
	av = newAV ();
	av_extend (av, n_children-1);
	for (i = 0; i < n_children; i++)
		av_store (av, i, newSViv (new_order[i]));
	XPUSHs (sv_2mortal (newRV_noinc ((SV*)av)));

	GPERL_CLOSURE_MARSHAL_PUSH_DATA;

	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_DISCARD);

	/*
	 * clean up
	 */

	FREETMPS;
	LEAVE;
}

/*
 * GtkTreeModelIface
 */

/*
 * Signals - these have class closures, so we can override them "normally"
 *           (for gtk2-perl, that is)
 *
 *	row_changed
 *	row_inserted
 *	row_has_child_toggled
 *	row_deleted
 *	rows_reordered
 */

/*
 * Virtual Table - things for which we must provide overrides
 */

static SV *
find_func (GtkTreeModel * tree_model,
           const char * method_name)
{
	HV * stash = gperl_object_stash_from_type (G_OBJECT_TYPE (tree_model));
	return (SV*) gv_fetchmethod (stash, method_name);
}

#define PREP(model)	\
	dSP;			\
	ENTER;			\
	SAVETMPS;		\
	PUSHMARK (SP);		\
	PUSHs (sv_2mortal (newSVGObject (G_OBJECT (model))));

#define CALL(name, flags)	\
	PUTBACK;			\
	call_method (name, flags);	\
	SPAGAIN;

#define FINISH	\
	PUTBACK;	\
	FREETMPS;	\
	LEAVE;

static GtkTreeModelFlags
gtk2perl_tree_model_get_flags (GtkTreeModel *tree_model)
{
	GtkTreeModelFlags ret;
	PREP (tree_model);
	CALL ("GET_FLAGS", G_SCALAR);
	ret = SvGtkTreeModelFlags (POPs);
	FINISH;
	return ret;
}

static gint
gtk2perl_tree_model_get_n_columns (GtkTreeModel *tree_model)
{
	int ret;
	PREP (tree_model);
	CALL ("GET_N_COLUMNS", G_SCALAR);
	ret = POPi;
	FINISH;
	return ret;
}

static GType
gtk2perl_tree_model_get_column_type (GtkTreeModel *tree_model,
                                     gint          index_)
{
	GType ret;
	SV * svret;
	PREP (tree_model);
	XPUSHs (sv_2mortal (newSViv (index_)));
	CALL ("GET_COLUMN_TYPE", G_SCALAR);
	svret = POPs;
	PUTBACK;
	ret = gperl_type_from_package (SvPV_nolen (svret));
	if (!ret)
		croak ("package %s is not registered with GPerl\n",
		       SvPV_nolen (svret));
	FREETMPS;
	LEAVE;
	return ret;
}

static SV *
sv_from_iter (GtkTreeIter * iter)
{
	AV * av;
	if (!iter)
		return &PL_sv_undef;
	av = newAV ();
	av_push (av, newSVuv (iter->stamp));
	av_push (av, newSViv (PTR2IV (iter->user_data)));
	av_push (av, iter->user_data2 ? newRV (iter->user_data2) : &PL_sv_undef);
	av_push (av, iter->user_data3 ? newRV (iter->user_data3) : &PL_sv_undef);
	return newRV_noinc ((SV*)av);
}

static gboolean
iter_from_sv (GtkTreeIter * iter,
              SV * sv)
{
	/* we allow undef as the sentinel from the perl vfuncs to tell us
	 * to return FALSE from the C vfuncs.  for anything else, it *must*
	 * be an array reference or we croak with an informative message
	 * (since that would be caused by a programming bug). */
	if (gperl_sv_is_defined (sv)) {
		SV ** svp;
		AV * av;
		if (!gperl_sv_is_array_ref (sv))
			croak ("expecting a reference to an ARRAY to describe "
			       "a tree iter, not a %s",
			       sv_reftype (SvRV (sv), 0));
		av = (AV*) SvRV (sv);
		if ((svp = av_fetch (av, 0, FALSE)))
			iter->stamp = SvUV (*svp);

		if ((svp = av_fetch (av, 1, FALSE)) && gperl_sv_is_defined (*svp))
			iter->user_data = INT2PTR (gpointer, SvIV (*svp));
		else
			iter->user_data = NULL;

		if ((svp = av_fetch (av, 2, FALSE)) && gperl_sv_is_ref (*svp))
			iter->user_data2 =  SvRV (*svp);
		else
			iter->user_data2 = NULL;

		if ((svp = av_fetch (av, 3, FALSE)) && gperl_sv_is_ref (*svp))
			iter->user_data3 =  SvRV (*svp);
		else
			iter->user_data3 = NULL;
		return TRUE;
	} else {
		iter->stamp = 0;
		iter->user_data = 0;
		iter->user_data2 = 0;
		iter->user_data3 = 0;
		return FALSE;
	}
}

static gboolean
gtk2perl_tree_model_get_iter (GtkTreeModel *tree_model,
      			      GtkTreeIter  *iter,
      			      GtkTreePath  *path)
{
	gboolean ret;
	PREP (tree_model);
	XPUSHs (sv_2mortal (path ? newSVGtkTreePath (path) : &PL_sv_undef));
	CALL ("GET_ITER", G_SCALAR);
	ret = iter_from_sv (iter, POPs);
	FINISH;
	return ret;
}

static GtkTreePath *
gtk2perl_tree_model_get_path (GtkTreeModel *tree_model,
      			      GtkTreeIter  *iter)
{
	GtkTreePath * ret = NULL;
	SV * sv;
	PREP (tree_model);
	XPUSHs (sv_2mortal (sv_from_iter (iter)));
	CALL ("GET_PATH", G_SCALAR);
	sv = POPs;
	/* restore the stack before parsing the output, since SvGtkTreePath
	 * might croak.  FREETMPS will destroy the path, though, so we need
	 * to copy it, first. */
	PUTBACK;
	if (gperl_sv_is_defined (sv))
		ret = gtk_tree_path_copy (SvGtkTreePath (sv));
	FREETMPS;
	LEAVE;
	return ret;
}

static void
gtk2perl_tree_model_get_value (GtkTreeModel *tree_model,
      			       GtkTreeIter  *iter,
      			       gint          column,
      			       GValue       *value)
{
	g_value_init (value,
	              gtk2perl_tree_model_get_column_type (tree_model, column));
	{
		PREP (tree_model);
		XPUSHs (sv_2mortal (sv_from_iter (iter)));
		XPUSHs (sv_2mortal (newSViv (column)));
		CALL ("GET_VALUE", G_SCALAR);
		gperl_value_from_sv (value, POPs);
		FINISH;
	}
}

static gboolean
gtk2perl_tree_model_iter_next (GtkTreeModel *tree_model,
      			       GtkTreeIter  *iter)
{
	gboolean ret;
	PREP (tree_model);
	XPUSHs (sv_2mortal (sv_from_iter (iter)));
	CALL ("ITER_NEXT", G_SCALAR);
	ret = iter_from_sv (iter, POPs);
	FINISH;
	return ret;
}

static gboolean
gtk2perl_tree_model_iter_children (GtkTreeModel *tree_model,
                                   GtkTreeIter  *iter,
                                   GtkTreeIter  *parent)
{
	gboolean ret;
	PREP (tree_model);
	XPUSHs (sv_2mortal (sv_from_iter (parent)));
	CALL ("ITER_CHILDREN", G_SCALAR);
	ret = iter_from_sv (iter, POPs);
	FINISH;
	return ret;
}

static gboolean
gtk2perl_tree_model_iter_has_child (GtkTreeModel *tree_model,
                                    GtkTreeIter  *iter)
{
	SV *sv;
	gboolean ret;
	PREP (tree_model);
	XPUSHs (sv_2mortal (sv_from_iter (iter)));
	CALL ("ITER_HAS_CHILD", G_SCALAR);
	sv = POPs;
	ret = sv_2bool (sv);
	FINISH;
	return ret;
}

static gint
gtk2perl_tree_model_iter_n_children (GtkTreeModel *tree_model,
      			    GtkTreeIter  *iter)
{
	gint ret;
	PREP (tree_model);
	XPUSHs (sv_2mortal (sv_from_iter (iter)));
	CALL ("ITER_N_CHILDREN", G_SCALAR);
	ret = POPi;
	FINISH;
	return ret;
}

static gboolean
gtk2perl_tree_model_iter_nth_child (GtkTreeModel *tree_model,
                                    GtkTreeIter  *iter,
                                    GtkTreeIter  *parent,
                                    gint          n)
{
	gboolean ret;
	PREP (tree_model);
	XPUSHs (sv_2mortal (sv_from_iter (parent)));
	XPUSHs (sv_2mortal (newSViv (n)));
	CALL ("ITER_NTH_CHILD", G_SCALAR);
	ret = iter_from_sv (iter, POPs);
	FINISH;
	return ret;
}

static gboolean
gtk2perl_tree_model_iter_parent (GtkTreeModel *tree_model,
      			         GtkTreeIter  *iter,
      			         GtkTreeIter  *child)
{
	gboolean ret;
	PREP (tree_model);
	XPUSHs (sv_2mortal (sv_from_iter (child)));
	CALL ("ITER_PARENT", G_SCALAR);
	ret = iter_from_sv (iter, POPs);
	FINISH;
	return ret;
}

static void
gtk2perl_tree_model_ref_node (GtkTreeModel *tree_model,
                              GtkTreeIter  *iter)
{
	SV * func = find_func (tree_model, "REF_NODE");
	if (func) {
		PREP (tree_model);
		XPUSHs (sv_2mortal (sv_from_iter (iter)));
		PUTBACK;
		call_sv (func, G_VOID|G_DISCARD);
		FINISH;
	}
}

static void
gtk2perl_tree_model_unref_node (GtkTreeModel *tree_model,
                                GtkTreeIter  *iter)
{
	SV * func = find_func (tree_model, "UNREF_NODE");
	if (func) {
		PREP (tree_model);
		XPUSHs (sv_2mortal (sv_from_iter (iter)));
		PUTBACK;
		call_sv (func, G_VOID|G_DISCARD);
		FINISH;
	}
}


static void
gtk2perl_tree_model_init (GtkTreeModelIface * iface)
{
	iface->get_flags       = gtk2perl_tree_model_get_flags;
	iface->get_n_columns   = gtk2perl_tree_model_get_n_columns;
	iface->get_column_type = gtk2perl_tree_model_get_column_type;
	iface->get_iter        = gtk2perl_tree_model_get_iter;
	iface->get_path        = gtk2perl_tree_model_get_path;
	iface->get_value       = gtk2perl_tree_model_get_value;
	iface->iter_next       = gtk2perl_tree_model_iter_next;
	iface->iter_children   = gtk2perl_tree_model_iter_children;
	iface->iter_has_child  = gtk2perl_tree_model_iter_has_child;
	iface->iter_n_children = gtk2perl_tree_model_iter_n_children;
	iface->iter_nth_child  = gtk2perl_tree_model_iter_nth_child;
	iface->iter_parent     = gtk2perl_tree_model_iter_parent;
	iface->ref_node        = gtk2perl_tree_model_ref_node;
	iface->unref_node      = gtk2perl_tree_model_unref_node;
}

MODULE = Gtk2::TreeModel	PACKAGE = Gtk2::TreeModel

=for flags GtkTreeModelFlags
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

 # Three ways of getting the iter pointing to the location 3:2:5

 # get the iterator from a string
 $iter = $model->get_iter_from_string ("3:2:5");

 # get the iterator from a path
 $path = Gtk2::TreePath->new_from_string ("3:2:5");
 $iter = $model->get_iter ($path);

 # walk the tree to find the iterator
 $iter = $model->iter_nth_child (undef, 3);
 $iter = $model->iter_nth_child ($iter, 2);
 $iter = $model->iter_nth_child ($iter, 5);

 
 # getting and setting values

 # assuming a model with these columns
 use constant STRING_COLUMN => 0;
 use constant INT_COLUMN => 1;

 # set values
 $model->set ($iter,
	      STRING_COLUMN, $new_string_value,
	      INT_COLUMN, $new_int_value);

 # and get values
 ($int, $str) = $model->get ($iter, INT_COLUMN, STRING_COLUMN);

 # if you don't specify a list of column numbers,
 # you get all of them.
 @values = $model->get ($iter);

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

The Gtk2::TreeModel provides a generic tree interface for use by the 
Gtk2::TreeView widget.  It is an abstract interface, designed to be usable
with any appropriate data structure.

The model is represented as a hierarchical tree of strongly-typed, columned
data.  In other words, the model can be seen as a tree where every node has
different values depending on which column is being queried.  The type of
data found in a column is determined by using the GType system (i.e. package
names like Glib::Int, Gtk2::Button, Glib::Scalar, etc).  The types are
homogeneous per column across all nodes.  It is important to note that this
interface only provides a way of examining a model and observing changes.
The implementation of each individual model decides how and if changes are
made.

In order to make life simpler for programmers who do not need to write their
own specialized model, two generic models are provided - the Gtk2::TreeStore
and the Gtk2::ListStore.  To use these, the developer simply pushes data into
these models as necessary.  These models provide the data structure as well
as all appropriate tree interfaces.  As a result, implementing drag and drop,
sorting, and storing data is trivial.  For the vast majority of trees and
lists, these two models are sufficient.  For information on how to implement
your own model in Perl, see L</CREATING A CUSTOM TREE MODEL>.

Models are accessed on a node/column level of granularity.  One can query for
the value of a model at a certain node and a certain column on that node.
There are two structures used to reference a particular node in a model:
the Gtk2::TreePath and the Gtk2::TreeIter (short for "iterator").  Most of
the interface consists of operations on a Gtk2::TreeIter.

A path is essentially a potential node.  It is a location on a model that
may or may not actually correspond to a node on a specific model.  The
Gtk2::TreePath object can be converted into either an array of unsigned
integers or a string.  The string form is a list of numbers separated by a
colon.  Each number refers to the offset at that level.  Thus, the path '0'
refers to the root node and the path '2:4' refers to the fifth child of the
third node.

By contrast, a Gtk2::TreeIter is a reference to a specific node on a specific
model.  To the user of a model, the iter is merely an opaque object.
One can convert a path to an iterator by calling C<Gtk2::TreeModel::get_iter>.
These iterators are the primary way of accessing a model and are
similar to the iterators used by Gtk2::TextBuffer. The model interface
defines a set of operations using them for navigating the model.

The iterators are generally used only for a short time, and their
behaviour is different to that suggested by the Gtk+ documentation. They
are not valid when the model is changed, even though get_flags returns
'iters-persist'. Iterators obtained within a GtkTreeModelForeachFunc are
also invalid after the foreach terminates. There may be other such
cases. In the foreach case, and perhaps others, a persistent iterator
may be obtained by copying it (see Glib::Boxed->copy).

(The preceding description and most of the method descriptions have been
adapted directly from the Gtk+ C API reference.)

=cut

##
## 
##

=for position post_methods

=head1 CREATING A CUSTOM TREE MODEL

GTK+ provides two model implementations, Gtk2::TreeStore and Gtk2::ListStore,
which should be sufficient in most cases.  For some cases, however, it is
advantageous to provide a custom tree model implementation.  It is possible
to create custom tree models in Perl, because we're cool like that.

To do this, you create a Glib::Object derivative which implements the 
Gtk2::TreeModel interface; this is gtk2-perl-speak for "you have to add
a special key when you register your object type."  For example:

  package MyModel;
  use Gtk2;
  use Glib::Object::Subclass
      Glib::Object::,
      interfaces => [ Gtk2::TreeModel:: ],
      ;

This will cause perl to call several virtual methods with ALL_CAPS_NAMES
when Gtk+ attempts to perform certain actions on the model.  You simply
provide (or override) those methods.

=head2 TREE ITERS

Gtk2::TreeIter is normally an opaque object, but on the implementation side
of a Gtk2::TreeModel, you have to define what's inside.  The virtual methods
described below deal with iters as a reference to an array containing four
values:

=over

=item o stamp (integer)

A number unique to this model.

=item o user_data (integer)

An arbitrary integer value.

=item o user_data2 (scalar)

An arbitrary reference.  Will not persist.  May be undef.

=item o user_data3 (scalar)

An arbitrary reference.  Will not persist.  May be undef.

=back

The two references, if used, will generally be to data within the model,
like a row array, or a node object in a tree or linked list.  Keeping the
things referred to alive is the model's responsibility.  An iter doesn't
make them persist, and if the things are destroyed then any iters still
containing them will become invalid (and result in memory corruption if
used).  An iter only has to remain valid until the model contents change, so
generally anything internal to the model is fine.

=head2 VIRTUAL METHODS

An implementation of

=over

=item treemodelflags = GET_FLAGS ($model)

=item integer = GET_N_COLUMNS ($model)

=item string = GET_COLUMN_TYPE ($model, $index)

=item ARRAYREF = GET_ITER ($model, $path)

See above for a description of what goes in the returned array reference.

=item treepath = GET_PATH ($model, ARRAYREF)

=item scalar = GET_VALUE ($model, ARRAYREF, $column)

Implements $treemodel->get().

=item ARRAYREF = ITER_NEXT ($model, ARRAYREF)

=item ARRAYREF = ITER_CHILDREN ($model, ARRAYREF)

=item boolean = ITER_HAS_CHILD ($model, ARRAYREF)

=item integer = ITER_N_CHILDREN ($model, ARRAYREF)

=item ARRAYREF = ITER_NTH_CHILD ($model, ARRAYREF, $n)

=item ARRAYREF = ITER_PARENT ($model, ARRAYREF)

=item REF_NODE ($model, ARRAYREF)

Optional.

=item UNREF_NODE ($model, ARRAYREF)

Optional.

=back

=cut

=for position post_signals

Note that currently in a Perl subclass of an object implementing
C<Gtk2::TreeModel>, the class closure, ie. class default signal
handler, for the C<rows-reordered> signal is called only with an
integer address for the reorder array parameter, not a Perl arrayref
like a handler installed with C<signal_connect> receives.  It works to
C<signal_chain_from_overridden> with the address, but it's otherwise
fairly useless and will likely change in the future.

=cut

=for apidoc __hide__
=cut
void
_ADD_INTERFACE (class, const char * target_class)
    CODE:
    {
	static const GInterfaceInfo iface_info = {
		(GInterfaceInitFunc) gtk2perl_tree_model_init,
		(GInterfaceFinalizeFunc) NULL,
		(gpointer) NULL
	};
	GType gtype = gperl_object_type_from_package (target_class);
	g_type_add_interface_static (gtype, GTK_TYPE_TREE_MODEL, &iface_info);
    }
	

MODULE = Gtk2::TreeModel	PACKAGE = Gtk2::TreePath	PREFIX = gtk_tree_path_

=for apidoc
Create a new path.  For convenience, if you pass a value for I<$path>,
this is just an alias for C<new_from_string>.
=cut
GtkTreePath_own_ornull *
gtk_tree_path_new (class, path=NULL)
	const gchar * path
    ALIAS:
	new_from_string = 1
    CODE:
	PERL_UNUSED_VAR (ix);
	if (path)
		RETVAL = gtk_tree_path_new_from_string (path);
	else
		RETVAL = gtk_tree_path_new ();
    OUTPUT:
	RETVAL


## GtkTreePath * gtk_tree_path_new_from_indices (gint first_index, ...)
=for apidoc
=for arg first_index (integer) a non-negative index value
=for arg ... of zero or more index values

The C API reference docs for this function say to mark the end of the list
with a -1, but Perl doesn't need list terminators, so don't do that.

This is specially implemented to be available for all gtk+ versions.

=cut
GtkTreePath_own_ornull *
gtk_tree_path_new_from_indices (class, first_index, ...)
    PREINIT:
	gint i;
	GtkTreePath *path;
    CODE:
	path = gtk_tree_path_new ();

	for (i = 1 ; i < items ; i++) {
		gint index = SvIV (ST (i));
		if (index < 0)
			croak ("Gtk2::TreePath->new_from_indices takes index"
			       " values from the argument stack and therefore"
			       " does not use a -1 terminator value like its"
			       " C counterpart; negative index values are"
			       " not allowed");
		gtk_tree_path_append_index (path, index);
	}

	RETVAL = path;
    OUTPUT:
	RETVAL

gchar_own *
gtk_tree_path_to_string (path)
	GtkTreePath * path

GtkTreePath_own *
gtk_tree_path_new_first (class)
    C_ARGS:
	/* void */

## gtk_tree_path_new_root is deprecated in 2.2.0

void
gtk_tree_path_append_index (path, index_)
	GtkTreePath *path
	gint index_

void
gtk_tree_path_prepend_index (path, index_)
	GtkTreePath *path
	gint index_

gint
gtk_tree_path_get_depth (path)
	GtkTreePath *path

# gint * gtk_tree_path_get_indices_with_depth (GtkTreePath *path, gint *depth);
=for apidoc
Returns a list of integers describing the current indices of I<$path>.
=cut
void
gtk_tree_path_get_indices (path)
	GtkTreePath * path
    PREINIT:
	gint * indices;
	gint depth;
	gint i;
    PPCODE:
	depth = gtk_tree_path_get_depth (path);
	indices = gtk_tree_path_get_indices (path);
	EXTEND (SP, depth);
	for (i = 0 ; i < depth ; i++)
		PUSHs (sv_2mortal (newSViv (indices[i])));

## boxed wrapper stuff handled by Glib::Boxed
## GtkTreePath * gtk_tree_path_copy (GtkTreePath *path)
## void gtk_tree_path_free (GtkTreePath *path)

=for apidoc
Compares two paths.  If I<$a> appears before I<$b> in the three, returns -1.
If I<$b> appears before I<$a>, returns 1.  If the nodes are equal, returns 0.
=cut
gint
gtk_tree_path_compare (a, b)
	GtkTreePath *a
	GtkTreePath *b

=for apidoc
Moves I<$path> to point to the next node at the current depth.
=cut
void
gtk_tree_path_next (path)
	GtkTreePath *path

=for apidoc
Moves I<$path> to point to the previous node at the current depth, if it
exists.  Returns true if there is a previous node and I<$path> was modified.
=cut
gboolean
gtk_tree_path_prev (path)
	GtkTreePath *path

=for apidoc
Moves I<$path> to point to its parent node; returns false if there is no
parent.
=cut
gboolean
gtk_tree_path_up (path)
	GtkTreePath *path

=for apidoc
Moves I<$path> to point to the first child of the current path.
=cut
void
gtk_tree_path_down (path)
	GtkTreePath *path

gboolean
gtk_tree_path_is_ancestor (path, descendant)
	GtkTreePath *path
	GtkTreePath *descendant

gboolean
gtk_tree_path_is_descendant (path, ancestor)
	GtkTreePath *path
	GtkTreePath *ancestor



MODULE = Gtk2::TreeModel	PACKAGE = Gtk2::TreeRowReference	PREFIX = gtk_tree_row_reference_

 ##
 ## there doesn't seem to be a GType for GtkTreeRowReference in 2.0.x...
 ##

#ifdef GTK_TYPE_TREE_ROW_REFERENCE

##GtkTreeRowReference* gtk_tree_row_reference_new (GtkTreeModel *model, GtkTreePath *path);
#  $row_ref_or_undef = Gtk2::TreeRowReference->new ($model, $path)
GtkTreeRowReference_own_ornull*
gtk_tree_row_reference_new (class, GtkTreeModel *model, GtkTreePath *path)
    C_ARGS:
	model, path

  ## mmmm, the docs say "you do not need to use this function"
##GtkTreeRowReference* gtk_tree_row_reference_new_proxy (GObject *proxy, GtkTreeModel *model, GtkTreePath *path);

GtkTreePath_own_ornull * gtk_tree_row_reference_get_path (GtkTreeRowReference *reference);

## gboolean gtk_tree_row_reference_valid (GtkTreeRowReference *reference)
gboolean
gtk_tree_row_reference_valid (reference)
	GtkTreeRowReference *reference

#### boxed wrapper stuff handled by Glib::Boxed
#### GtkTreeRowReference* gtk_tree_row_reference_copy (GtkTreeRowReference *reference);
#### void gtk_tree_row_reference_free (GtkTreeRowReference *reference)

 ## i gather that you only need these if you created the row reference with
 ## gtk_tree_row_reference_new_proxy...  but they recommend you don't use
 ## the proxy stuff.  i'll hold off until somebody asks for it.
#### void gtk_tree_row_reference_inserted (GObject *proxy, GtkTreePath *path)
##void
##gtk_tree_row_reference_inserted (proxy, path)
##	GObject *proxy
##	GtkTreePath *path
##
#### void gtk_tree_row_reference_deleted (GObject *proxy, GtkTreePath *path)
##void
##gtk_tree_row_reference_deleted (proxy, path)
##	GObject *proxy
##	GtkTreePath *path
##
#### void gtk_tree_row_reference_reordered (GObject *proxy, GtkTreePath *path, GtkTreeIter *iter, gint *new_order)
##void
##gtk_tree_row_reference_reordered (proxy, path, iter, new_order)
##	GObject *proxy
##	GtkTreePath *path
##	GtkTreeIter *iter
##	gint *new_order
##

#if GTK_CHECK_VERSION (2, 8, 0)

GtkTreeModel_ornull * gtk_tree_row_reference_get_model (GtkTreeRowReference *reference);

#endif

#endif /* defined GTK_TYPE_TREE_ROW_REFERENCE */

MODULE = Gtk2::TreeModel	PACKAGE = Gtk2::TreeIter	PREFIX = gtk_tree_iter_

=for see_also Gtk2::TreeModel
=cut

=head1 SYNOPSIS

  package MyCustomListStore;

  use Glib::Object::Subclass
      Glib::Object::,
      interfaces => [ Gtk2::TreeModel:: ],
      ;

  ...

  sub set {
      my $list = shift;
      my $iter = shift; # a Gtk2::TreeIter

      # this method needs access to the internal representation
      # of the iter, as the model implementation sees it:
      my $arrayref = $iter->to_arrayref ($list->{stamp});
      ...
  }


=head1 DESCRIPTION

The methods described here are only of use in custom Gtk2::TreeModel
implementations; they are not safe to be used on generic iters or in
application code.  See L<Gtk2::TreeModel/CREATING A CUSTOM TREE MODEL> for
more information.

=cut

=for apidoc
Convert a boxed Gtk2::TreeIter reference into the "internal" array reference
representation used by custom Gtk2::TreeModel implementations.  This is
necessary when you need to get to the data inside your iters in methods
which are not the vfuncs of the Gtk2::TreeModelIface interface.  The stamp
must match; this protects the binding code from potential memory faults
when attempting to convert an iter that doesn't actually belong to your
model.  See L<Gtk2::TreeModel/CREATING A CUSTOM TREE MODEL> for
more information.
=cut
SV*
to_arrayref (GtkTreeIter * iter, IV stamp)
    CODE:
	if (iter->stamp != stamp)
		croak ("invalid iter -- stamp %d does not match "
		       "requested %" IVdf,
		       iter->stamp, stamp);
        RETVAL = sv_from_iter (iter);
    OUTPUT:
        RETVAL

=for apidoc
Create a new Gtk2::TreeIter from the "internal" array reference representation
used by custom Gtk2::TreeModel implementations.  This is the complement to
Gtk2::TreeIter::to_arrayref(), and is used when you need to create and return
a new iter from a method that is not one of the Gtk2::TreeModelIface
interface vfuncs.  See L<Gtk2::TreeModel/CREATING A CUSTOM TREE MODEL> for
more information.
=cut
GtkTreeIter_copy *
new_from_arrayref (class, SV * sv_iter)
    PREINIT:
	GtkTreeIter iter = {0, };
    CODE:
	if (!iter_from_sv (&iter, sv_iter))
		XSRETURN_UNDEF;
	RETVAL = &iter;
    OUTPUT:
	RETVAL

## we get this from Glib::Boxed::copy
## GtkTreeIter * gtk_tree_iter_copy (GtkTreeIter * iter)

## we get this from Glib::Boxed::DESTROY
## void gtk_tree_iter_free (GtkTreeIter *iter)

=for apidoc
Set the contents of $iter.  $from can be either another Gtk2::TreeIter
or an "internal" arrayref form as above.

Often you create a new iter instead of modifying an existing one, but
C<set> lets you to implement things in the style of the C<remove>
method of Gtk2::ListStore and Gtk2::TreeStore.

A set can also explicitly invalidate an iter by zapping its stamp, so
nobody can accidentally use it again.

    $iter->set ([0,0,undef,undef]);

=cut
void
set (GtkTreeIter *iter, SV *from)
    CODE:
	if (gperl_sv_is_array_ref (from)) {
		iter_from_sv (iter, from);
	} else {
		GtkTreeIter *from_iter = SvGtkTreeIter (from);
		memcpy (iter, from_iter, sizeof(*iter));
	}


MODULE = Gtk2::TreeModel	PACKAGE = Gtk2::TreeModel	PREFIX = gtk_tree_model_

BOOT:
	gperl_signal_set_marshaller_for (GTK_TYPE_TREE_MODEL, "rows_reordered",
	                                 gtk2perl_tree_model_rows_reordered_marshal);

=for flags GtkTreeModelFlags
=cut

## GtkTreeModelFlags gtk_tree_model_get_flags (GtkTreeModel *tree_model)
GtkTreeModelFlags
gtk_tree_model_get_flags (tree_model)
	GtkTreeModel *tree_model

## gint gtk_tree_model_get_n_columns (GtkTreeModel *tree_model)
gint
gtk_tree_model_get_n_columns (tree_model)
	GtkTreeModel *tree_model

## GType gtk_tree_model_get_column_type (GtkTreeModel *tree_model, gint index_)
### we hide GType from the perl level.  return the corresponding
### package instead.
=for apidoc
Returns the type of column I<$index_> as a package name.
=cut
const gchar *
gtk_tree_model_get_column_type (tree_model, index_)
	GtkTreeModel *tree_model
	gint index_
    PREINIT:
	GType t;
    CODE:
	t = gtk_tree_model_get_column_type (tree_model, index_);
	RETVAL = gperl_package_from_type (t);
	if (!RETVAL)
		croak ("internal -- type of column %d, %s (%d), is not registered with GPerl",
			index_, g_type_name (t), t);
    OUTPUT:
	RETVAL

## gboolean gtk_tree_model_get_iter (GtkTreeModel *tree_model, GtkTreeIter *iter, GtkTreePath *path)
=for
Returns a new Gtk2::TreeIter corresponding to I<$path>.
=cut
GtkTreeIter_copy *
gtk_tree_model_get_iter (tree_model, path)
	GtkTreeModel *tree_model
	GtkTreePath *path
    PREINIT:
	GtkTreeIter iter = {0, };
    CODE:
	if (!gtk_tree_model_get_iter (tree_model, &iter, path))
		XSRETURN_UNDEF;
	RETVAL = &iter;
    OUTPUT:
	RETVAL

##### FIXME couldn't we combine get_iter and get_iter_from_string, since we'll
#####       be able to tell at runtime whether the arg is a GtkTreePath or a
#####       plain old string?

## gboolean gtk_tree_model_get_iter_from_string (GtkTreeModel *tree_model, GtkTreeIter *iter, const gchar *path_string)
=for apidoc
Returns a new iter pointing to the node described by I<$path_string>, or
undef if the path does not exist.
=cut
GtkTreeIter_copy *
gtk_tree_model_get_iter_from_string (tree_model, path_string)
	GtkTreeModel *tree_model
	const gchar *path_string
    PREINIT:
	GtkTreeIter iter = {0, };
    CODE:
	if (!gtk_tree_model_get_iter_from_string (tree_model, &iter, path_string))
		XSRETURN_UNDEF;
	RETVAL = &iter;
    OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION(2,2,0)

## gchar * gtk_tree_model_get_string_from_iter (GtkTreeModel *tree_model, GtkTreeIter *iter)
=for apidoc
Generates a string representation of the iter.  This string is a ':' separated
list of numbers.  For example, "4:10:0:3" would be an acceptable return value
for this string.
=cut
gchar_own *
gtk_tree_model_get_string_from_iter (tree_model, iter)
	GtkTreeModel *tree_model
	GtkTreeIter *iter

#endif /* 2.2.0 */

## gboolean gtk_tree_model_get_iter_first (GtkTreeModel *tree_model, GtkTreeIter *iter)
=for apidoc
Return a new iter pointing to the first node in the tree (the one at path
"0"), or undef if the tree is empty.
=cut
GtkTreeIter_copy *
gtk_tree_model_get_iter_first (tree_model)
	GtkTreeModel *tree_model
    PREINIT:
	GtkTreeIter iter = {0, };
    CODE:
	if (!gtk_tree_model_get_iter_first (tree_model, &iter))
		XSRETURN_UNDEF;
	RETVAL = &iter;
    OUTPUT:
	RETVAL

### gtk_tree_model_get_iter_root is deprecated

## GtkTreePath * gtk_tree_model_get_path (GtkTreeModel *tree_model, GtkTreeIter *iter)
=for apidoc
Return a new Gtk2::TreePath corresponding to I<$iter>.
=cut
GtkTreePath_own *
gtk_tree_model_get_path (tree_model, iter)
	GtkTreeModel *tree_model
	GtkTreeIter *iter


## void gtk_tree_model_get (GtkTreeModel *tree_model, GtkTreeIter *iter, ...)
## void gtk_tree_model_get_value (GtkTreeModel *tree_model, GtkTreeIter *iter, gint column, GValue *value)

=for apidoc get_value
=for arg ... of column indices
Alias for L<get|/"$tree_model-E<gt>B<get> ($iter, ...)">.
=cut

=for apidoc
=for arg ... of column indices

Fetch and return the model's values in the row pointed to by I<$iter>.
If you specify no column indices, it returns the values for all of the
columns, otherwise, returns just those columns' values (in order).

This overrides overrides Glib::Object's C<get>, so you'll want to use
C<< $object->get_property >> to get object properties.

=cut
void
gtk_tree_model_get (tree_model, iter, ...)
	GtkTreeModel *tree_model
	GtkTreeIter *iter
    ALIAS:
	get_value = 1
    PREINIT:
	int i;
    CODE:
	/* we use CODE: instead of PPCODE: so we can handle the stack
	 * ourselves. */
	PERL_UNUSED_VAR (ix);
#define OFFSET 2
	if (items > OFFSET) {
		/* if column id's were passed, just return those columns */

		/* the stack is big enough already due to the input arguments,
		 * so we don't need to extend it.  nor do we need to care about
		 * xsubs called by gtk_tree_model_get_value overwriting the
		 * stuff we put on the stack. */
		for (i = OFFSET ; i < items ; i++) {
			GValue gvalue = {0, };
			gtk_tree_model_get_value (tree_model, iter,
			                          SvIV (ST (i)), &gvalue);
			ST (i - OFFSET) = sv_2mortal (gperl_sv_from_value (&gvalue));
			g_value_unset (&gvalue);
		}
		XSRETURN (items - OFFSET);
	}
#undef OFFSET

	else {
		/* otherwise return all of the columns */

		int n_columns = gtk_tree_model_get_n_columns (tree_model);
		/* extend the stack so it can handle 'n_columns' items in
		 * total.  the stack already contains 'items' elements so if
		 * 'items' < 'n_columns', make room for 'n_columns - items'
		 * more.  then move our local stack pointer forward to the new
		 * end, and update the global stack pointer.  leave 'ax'
		 * unchanged though, so that ST still refers to the start of
		 * the stack allocated to us.  this way, xsubs called by
		 * gtk_tree_model_get_value don't overwrite what we put on the
		 * stack. */
		SPAGAIN;
		if (n_columns > items)
			EXTEND (SP, n_columns - items);
		SP += n_columns - items;
		PUTBACK;
		for (i = 0; i < n_columns; i++) {
			GValue gvalue = {0, };
			gtk_tree_model_get_value (tree_model, iter,
			                          i, &gvalue);
			ST (i) = sv_2mortal (gperl_sv_from_value (&gvalue));
			g_value_unset (&gvalue);
		}
		XSRETURN (n_columns);
	}

 ## va_list means nothing to a perl developer, it's a c-specific thing.
#### void gtk_tree_model_get_valist (GtkTreeModel *tree_model, GtkTreeIter *iter, va_list var_args)


##
## gboolean gtk_tree_model_iter_next (GtkTreeModel *tree_model, GtkTreeIter *iter)
=for apidoc
Return a new iter pointing to node following I<$iter> at the current level,
or undef if there is no next node.  I<$iter> is unaltered.  (Note: this is
different from the C version, which modifies the iter.)
=cut
GtkTreeIter_own *
gtk_tree_model_iter_next (tree_model, iter)
	GtkTreeModel *tree_model
	GtkTreeIter *iter
    CODE:
	/* the C version modifies the iter we pass; to make this fit more
	 * with the rest of our Perl interface, we want *not* to modify
	 * the one passed and instead return the modified iter... which
	 * means we have to copy *first*. */
	RETVAL = gtk_tree_iter_copy (iter);
	if (!gtk_tree_model_iter_next (tree_model, RETVAL)) {
		gtk_tree_iter_free (RETVAL);
		XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

#### gboolean gtk_tree_model_iter_children (GtkTreeModel *tree_model, GtkTreeIter *iter, GtkTreeIter *parent)
=for apidoc
Returns undef if I<$parent> has no children, otherwise, returns a new iter
to the first child of I<$parent>.  I<$parent> is unaltered.  If I<$parent>
is undef, this is equivalent to C<Gtk2::TreeModel::get_iter_first>.
=cut
GtkTreeIter_copy *
gtk_tree_model_iter_children (tree_model, parent)
	GtkTreeModel *tree_model
	GtkTreeIter_ornull *parent
    PREINIT:
	GtkTreeIter iter;
    CODE:
	if (!gtk_tree_model_iter_children (tree_model, &iter, parent))
		XSRETURN_UNDEF;
	RETVAL = &iter;
    OUTPUT:
	RETVAL

## gboolean gtk_tree_model_iter_has_child (GtkTreeModel *tree_model, GtkTreeIter *iter)
=for apidoc
Returns true if I<$iter> has child nodes.
=cut
gboolean
gtk_tree_model_iter_has_child (tree_model, iter)
	GtkTreeModel *tree_model
	GtkTreeIter *iter

## gint gtk_tree_model_iter_n_children (GtkTreeModel *tree_model, GtkTreeIter *iter)
=for apidoc
Returns the number of children I<$iter> has.  If I<$iter> is undef (or omitted)
then returns the number of toplevel nodes.
=cut
gint
gtk_tree_model_iter_n_children (tree_model, iter=NULL)
	GtkTreeModel *tree_model
	GtkTreeIter_ornull *iter

## gboolean gtk_tree_model_iter_nth_child (GtkTreeModel *tree_model, GtkTreeIter *iter, GtkTreeIter *parent, gint n)
=for apidoc
Returns an iter to the child of I<$parent> at index I<$n>, or undef if there
is no such child.  I<$parent> is unaltered.
=cut
GtkTreeIter_copy *
gtk_tree_model_iter_nth_child (tree_model, parent, n)
	GtkTreeModel *tree_model
	GtkTreeIter_ornull *parent
	gint n
    PREINIT:
	GtkTreeIter iter;
    CODE:
	if (!gtk_tree_model_iter_nth_child (tree_model, &iter, parent, n))
		XSRETURN_UNDEF;
	RETVAL = &iter;
    OUTPUT:
	RETVAL

## gboolean gtk_tree_model_iter_parent (GtkTreeModel *tree_model, GtkTreeIter *iter, GtkTreeIter *child)
=for apidoc
Returns a new iter pointing to I<$child>'s parent node, or undef if I<$child>
doesn't have a parent.  I<$child> is unaltered.
=cut
GtkTreeIter_copy *
gtk_tree_model_iter_parent (tree_model, child)
	GtkTreeModel *tree_model
	GtkTreeIter *child
    PREINIT:
	GtkTreeIter iter;
    CODE:
	if (! gtk_tree_model_iter_parent (tree_model, &iter, child))
		XSRETURN_UNDEF;
	RETVAL = &iter;
    OUTPUT:
	RETVAL

## void gtk_tree_model_ref_node (GtkTreeModel *tree_model, GtkTreeIter *iter)
=for apidoc
Lets the tree ref the node. This is an optional method for models to implement.
To be more specific, models may ignore this call as it exists primarily for
performance reasons.

This function is primarily meant as a way for views to let caching model know
when nodes are being displayed (and hence, whether or not to cache that node.)
For example, a file-system based model would not want to keep the entire
file-hierarchy in memory, just the sections that are currently being
displayed by every current view.

A model should be expected to be able to get an iter independent of its reffed
state.
=cut
void
gtk_tree_model_ref_node (tree_model, iter)
	GtkTreeModel *tree_model
	GtkTreeIter *iter

## void gtk_tree_model_unref_node (GtkTreeModel *tree_model, GtkTreeIter *iter)
=for apidoc
Lets the tree unref the node. This is an optional method for models to
implement. To be more specific, models may ignore this call as it exists
primarily for performance reasons.

For more information on what this means, see C<Gtk2::TreeModel::ref_node>.
Please note that nodes that are deleted are not unreffed.
=cut
void
gtk_tree_model_unref_node (tree_model, iter)
	GtkTreeModel *tree_model
	GtkTreeIter *iter

## void gtk_tree_model_foreach (GtkTreeModel *model, GtkTreeModelForeachFunc func, gpointer user_data)
=for apidoc
=for arg func (subroutine)
Call I<$func> on each row in I<$model> as

    bool = &$func ($model, $path, $iter, $user_data)

If I<$func> returns true, the tree ceases to be walked,
and C<< $treemodel->foreach >> returns.
=cut
void
gtk_tree_model_foreach (model, func, user_data=NULL)
	GtkTreeModel *model
	SV * func
	SV * user_data
    PREINIT:
	GPerlCallback * callback;
	GType types[3];
    CODE:
	types[0] = GTK_TYPE_TREE_MODEL;
	types[1] = GTK_TYPE_TREE_PATH;
	types[2] = GTK_TYPE_TREE_ITER;
	callback = gperl_callback_new (func, user_data, G_N_ELEMENTS (types), types,
	                               G_TYPE_BOOLEAN);
	gtk_tree_model_foreach (model, gtk2perl_tree_model_foreach_func, callback);
	gperl_callback_destroy (callback);

## void gtk_tree_model_row_changed (GtkTreeModel *tree_model, GtkTreePath *path, GtkTreeIter *iter)
=for apidoc
Emits the "row_changed" signal on I<$tree_model>.
=cut
void
gtk_tree_model_row_changed (tree_model, path, iter)
	GtkTreeModel *tree_model
	GtkTreePath *path
	GtkTreeIter *iter

## void gtk_tree_model_row_inserted (GtkTreeModel *tree_model, GtkTreePath *path, GtkTreeIter *iter)
=for apidoc
Emits the "row_inserted" signal on I<$tree_model>.
=cut
void
gtk_tree_model_row_inserted (tree_model, path, iter)
	GtkTreeModel *tree_model
	GtkTreePath *path
	GtkTreeIter *iter

## void gtk_tree_model_row_has_child_toggled (GtkTreeModel *tree_model, GtkTreePath *path, GtkTreeIter *iter)
=for apidoc
Emits the "row_has_child_toggled" signal on I<$tree_model>.  This should be
called by models after the child state of a node changes.
=cut
void
gtk_tree_model_row_has_child_toggled (tree_model, path, iter)
	GtkTreeModel *tree_model
	GtkTreePath *path
	GtkTreeIter *iter

## void gtk_tree_model_row_deleted (GtkTreeModel *tree_model, GtkTreePath *path)
=for apidoc
Emits the "row_deleted" signal on I<$tree_model>.  This should be called by
models after a row has been removed.  The location pointed to by I<$path>
should be the removed row's old location.  It may not be a valid location
anymore.
=cut
void
gtk_tree_model_row_deleted (tree_model, path)
	GtkTreeModel *tree_model
	GtkTreePath *path

#### void gtk_tree_model_rows_reordered (GtkTreeModel *tree_model, GtkTreePath *path, GtkTreeIter *iter, gint *new_order)
=for apidoc
=for arg path the tree node whose children have been reordered
=for arg iter the tree node whose children have been reordered
=for arg ... (list) list of integers mapping the current position of each child to its old position before the re-ordering, i.e. $new_order[$newpos] = $oldpos.  There should be as many elements in this list as there are rows in I<$tree_model>.

Emits the "rows-reordered" signal on I<$tree_model>/  This should be called
by models with their rows have been reordered.
=cut
void
gtk_tree_model_rows_reordered (tree_model, path, iter, ...)
	GtkTreeModel *tree_model
	GtkTreePath *path
	GtkTreeIter_ornull *iter
    PREINIT:
	gint *new_order;
	int n, i;
    CODE:
	n = gtk_tree_model_iter_n_children (tree_model, iter);
	if (items - 3 != n)
		croak ("rows_reordered expects a list of as many indices"
		       " as the selected node of the model has children\n"
		       "   got %d, expected %d", (int) (items - 3), n);
	new_order = g_new (gint, n);
	for (i = 0 ; i < n ; i++)
		new_order[i] = SvIV (ST (3+i));
	gtk_tree_model_rows_reordered (tree_model, path, iter, new_order);
	g_free (new_order);
