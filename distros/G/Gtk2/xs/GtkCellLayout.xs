/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

/*
typedef void (* GtkCellLayoutDataFunc) (GtkCellLayout   *cell_layout,
                                        GtkCellRenderer *cell,
                                        GtkTreeModel    *tree_model,
                                        GtkTreeIter     *iter,
                                        gpointer         data);
*/

static void
gtk2perl_cell_layout_data_func (GtkCellLayout   *cell_layout,
                                GtkCellRenderer *cell,
                                GtkTreeModel    *tree_model,
                                GtkTreeIter     *iter,
                                gpointer         data)
{
	GPerlCallback * callback = (GPerlCallback *) data;

	gperl_callback_invoke (callback, NULL, cell_layout, cell,
	                       tree_model, iter);
}


/*
   GInterface support
 */

#define GET_METHOD(obj, name) \
	HV * stash = gperl_object_stash_from_type (G_OBJECT_TYPE (obj)); \
	GV * slot = gv_fetchmethod (stash, name);

#define METHOD_EXISTS (slot && GvCV (slot))

#define GET_METHOD_OR_DIE(obj, name) \
	GET_METHOD (obj, name); \
	if (!METHOD_EXISTS) \
		die ("No implementation for %s::%s", \
		     gperl_package_from_type (G_OBJECT_TYPE (obj)), name);

#define PREP(obj) \
	dSP; \
	ENTER; \
	SAVETMPS; \
	PUSHMARK (SP) ; \
	PUSHs (sv_2mortal (newSVGObject (G_OBJECT (obj))));

#define CALL \
	PUTBACK; \
	call_sv ((SV *) GvCV (slot), G_VOID | G_DISCARD);

#define FINISH \
	FREETMPS; \
	LEAVE;


static void
gtk2perl_cell_layout_pack_start (GtkCellLayout         *cell_layout,
                                 GtkCellRenderer       *cell,
                                 gboolean               expand)
{
	GET_METHOD_OR_DIE (cell_layout, "PACK_START");

	{
		PREP (cell_layout);
		XPUSHs (sv_2mortal (newSVGtkCellRenderer (cell)));
		XPUSHs (sv_2mortal (boolSV (expand)));
		CALL;
		FINISH;
	}
}

static void
gtk2perl_cell_layout_pack_end (GtkCellLayout         *cell_layout,
                               GtkCellRenderer       *cell,
                               gboolean               expand)
{
	GET_METHOD_OR_DIE (cell_layout, "PACK_END");

	{
		PREP (cell_layout);
		XPUSHs (sv_2mortal (newSVGtkCellRenderer (cell)));
		XPUSHs (sv_2mortal (boolSV (expand)));
		CALL;
		FINISH;
	}
}

static void
gtk2perl_cell_layout_clear (GtkCellLayout *cell_layout)
{
	GET_METHOD_OR_DIE (cell_layout, "CLEAR");

	{
		PREP (cell_layout);
		CALL;
		FINISH;
	}
}

static void
gtk2perl_cell_layout_add_attribute (GtkCellLayout         *cell_layout,
                                    GtkCellRenderer       *cell,
                                    const gchar           *attribute,
                                    gint                   column)
{
	GET_METHOD_OR_DIE (cell_layout, "ADD_ATTRIBUTE");

	{
		PREP (cell_layout);
		XPUSHs (sv_2mortal (newSVGtkCellRenderer (cell)));
		XPUSHs (sv_2mortal (newSVGChar (attribute)));
		XPUSHs (sv_2mortal (newSViv (column)));
		CALL;
		FINISH;
	}
}

/* The strategy for passing the function pointer to Perl land is the same as
 * the one used in GtkTreeSortable.xs. */

typedef struct {
	GtkCellLayoutDataFunc func;
	gpointer data;
	GtkDestroyNotify destroy;
} Gtk2PerlCellLayoutDataFunc;

static void
create_callback (GtkCellLayoutDataFunc func,
                 gpointer              data,
                 GtkDestroyNotify      destroy,
		 SV                  **code_return,
                 SV                  **data_return)
{
	HV *stash;
	SV *code_sv, *data_sv;
	Gtk2PerlCellLayoutDataFunc *wrapper;

	wrapper = g_new0 (Gtk2PerlCellLayoutDataFunc, 1);
	wrapper->func = func;
	wrapper->data = data;
	wrapper->destroy = destroy;
	data_sv = newSViv (PTR2IV (wrapper));

	stash = gv_stashpv ("Gtk2::CellLayout::DataFunc", TRUE);
	code_sv = sv_bless (newRV (data_sv), stash);

	*code_return = code_sv;
	*data_return = data_sv;
}

static void
gtk2perl_cell_layout_set_cell_data_func (GtkCellLayout         *cell_layout,
                                         GtkCellRenderer       *cell,
                                         GtkCellLayoutDataFunc  func,
                                         gpointer               func_data,
                                         GDestroyNotify         destroy)
{
	GET_METHOD_OR_DIE (cell_layout, "SET_CELL_DATA_FUNC");

	{
		SV *code_sv, *data_sv;
		PREP (cell_layout);

		XPUSHs (sv_2mortal (newSVGtkCellRenderer (cell)));

		if (func) {
			create_callback (func, func_data, destroy,
					 &code_sv, &data_sv);

			XPUSHs (sv_2mortal (code_sv));
			XPUSHs (sv_2mortal (data_sv));
		}

		CALL;
		FINISH;
	}
}

static void
gtk2perl_cell_layout_clear_attributes (GtkCellLayout         *cell_layout,
                                       GtkCellRenderer       *cell)
{
	GET_METHOD_OR_DIE (cell_layout, "CLEAR_ATTRIBUTES");

	{
		PREP (cell_layout);
		XPUSHs (sv_2mortal (newSVGtkCellRenderer (cell)));
		CALL;
		FINISH;
	}
}

static void
gtk2perl_cell_layout_reorder (GtkCellLayout         *cell_layout,
                              GtkCellRenderer       *cell,
                              gint                   position)
{
	GET_METHOD_OR_DIE (cell_layout, "REORDER");

	{
		PREP (cell_layout);
		XPUSHs (sv_2mortal (newSVGtkCellRenderer (cell)));
		XPUSHs (sv_2mortal (newSViv (position)));
		CALL;
		FINISH;
	}
}

#if GTK_CHECK_VERSION (2, 12, 0)

static GList*
gtk2perl_cell_layout_get_cells (GtkCellLayout *cell_layout)
{
	GList * cells = NULL;

	GET_METHOD (cell_layout, "GET_CELLS");

	if (METHOD_EXISTS) {
		int count;
		PREP (cell_layout);
		PUTBACK;
		count = call_sv ((SV *) GvCV (slot), G_ARRAY);
		SPAGAIN;
		while (count > 0) {
			SV * sv = POPs;
			cells = g_list_prepend (cells, SvGtkCellRenderer (sv));
			count--;
		}
		PUTBACK;
		FINISH;
	}

	return cells;
}

#endif

static void
gtk2perl_cell_layout_init (GtkCellLayoutIface * iface)
{
	iface->pack_start = gtk2perl_cell_layout_pack_start;
	iface->pack_end = gtk2perl_cell_layout_pack_end;
	iface->clear = gtk2perl_cell_layout_clear;
	iface->add_attribute = gtk2perl_cell_layout_add_attribute;
	iface->set_cell_data_func = gtk2perl_cell_layout_set_cell_data_func;
	iface->clear_attributes = gtk2perl_cell_layout_clear_attributes;
	iface->reorder = gtk2perl_cell_layout_reorder;
#if GTK_CHECK_VERSION (2, 12, 0)
	iface->get_cells = gtk2perl_cell_layout_get_cells;
#endif
}

MODULE = Gtk2::CellLayout	PACKAGE = Gtk2::CellLayout	PREFIX = gtk_cell_layout_

=for position SYNOPSIS

=head1 SYNOPSIS

 # This is an abstract interface; the CellLayout interface is
 # implemented by concrete classes like ComboBox and TreeViewColumn.
 # See the discussion for details on creating your own CellLayout.
 # This synopsis assumes you already have an instance in $cell_layout.

 # Add a cell renderer that shows the pixbuf in column 2 of the
 # associated TreeModel.  It will take up only the necessary space
 # ("expand" => FALSE).
 my $cell = Gtk2::CellRendererPixbuf->new ();
 $cell_layout->pack_start ($cell, FALSE);
 $cell_layout->add_attribute ($cell, pixbuf => 2);

 # Add another cell renderer that gets the "text" property from
 # column 3 of the associated TreeModel, and takes up all remaining
 # horizontal space ("expand" => TRUE).
 my $cell = Gtk2::CellRendererText->new (); 
 $cell_layout->pack_start ($cell, TRUE);
 $cell_layout->add_attribute ($cell, text => 3);

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

Gtk2::CellLayout is an interface to be implemented by all objects which
want to provide a Gtk2::TreeViewColumn-like API for packing cells,
setting attributes and data funcs.

=cut


=for position post_methods

=head1 CREATING A CUSTOM CELL LAYOUT

GTK+ provides several CellLayout implementations, such as Gtk2::TreeViewColumn
and Gtk2::ComboBox.  To create your own object that implements the CellLayout
interface and therefore can be used to display CellRenderers, you need to
add Gtk2::CellLayout to your class's "interfaces" list, like this:

  package MyLayout;
  use Gtk2;
  use Glib::Object::Subclass
      Gtk2::Widget::,
      interfaces => [ Gtk2::CellLayout:: ],
      ;

This will cause perl to call several virtual methods with ALL_CAPS_NAMES
when GTK+ attempts to perform certain actions.  You simply provide (or
override) those methods with perl code.  The methods map rather directly
to the object interface, so it should be easy to figure out what they
should do.  Those methods are:

=over

=item PACK_START ($cell_layout, $cell, $expand)

=item PACK_END ($cell_layout, $cell, $expand)

=item CLEAR ($cell_layout)

=item ADD_ATTRIBUTE ($cell_layout, $cell, $attribute, $column)

=item SET_CELL_DATA_FUNC ($cell_layout, $cell, $func, $data)

=item CLEAR_ATTRIBUTES ($cell_layout, $cell)

=item REORDER ($cell_layout, $cell, $position)

=item list = GET_CELLS ($cell_layout)

=back

=cut


=for apidoc __hide__
=cut
void
_ADD_INTERFACE (class, const char * target_class)
    CODE:
    {
	static const GInterfaceInfo iface_info = {
		(GInterfaceInitFunc) gtk2perl_cell_layout_init,
		(GInterfaceFinalizeFunc) NULL,
		(gpointer) NULL
	};
	GType gtype = gperl_object_type_from_package (target_class);
	g_type_add_interface_static (gtype, GTK_TYPE_CELL_LAYOUT, &iface_info);
    }


=for apidoc
Packs I<$cell> into the beginning of I<$cell_layout>.  If I<$expand> is false,
then I<$cell> is allocated no more space than it needs.  Any unused space is
divided evenly between cells for which I<$expand> is true.
=cut
void gtk_cell_layout_pack_start (GtkCellLayout *cell_layout, GtkCellRenderer *cell, gboolean expand);

=for apidoc
Like C<pack_start>, but adds from the end of the layout instead of the
beginning.
=cut
void gtk_cell_layout_pack_end (GtkCellLayout *cell_layout, GtkCellRenderer *cell, gboolean expand);

=for apidoc
Unsets all the mappings on all renderers on I<$cell_layout> and removes all
renderers attached to it.
=cut
void gtk_cell_layout_clear (GtkCellLayout *cell_layout);

=for apidoc
=for arg ... list of property name and column number pairs.
Sets the pairs in the I<...> list as the attributes of I<$cell_layout>, as
with repeated calls to C<add_attribute>.  All existing attributes are removed,
and replaced with the new attributes.
=cut
void gtk_cell_layout_set_attributes (GtkCellLayout *cell_layout, GtkCellRenderer *cell, ...);
    PREINIT:
	gint i;
    CODE:
	if (items < 2 || 0 != (items - 2) % 2)
		croak ("usage: $cell_layout->set_attributes ($cell, name => column, ...)\n"
		       "   expecting a list of name => column pairs"); 
	gtk_cell_layout_clear_attributes (cell_layout, cell);
	for (i = 2 ; i < items ; i+=2) {
		gtk_cell_layout_add_attribute (cell_layout, cell,
		                               SvPV_nolen (ST (i)),
		                               SvIV (ST (i+1)));
	}

=for apidoc
Adds an attribute mapping to the list in I<$cell_layout>.  The I<$column> is
the column of the model from which to get a value, and the I<$attribute> is
the property of I<$cell> to be set from the value.  So, for example, if
column 2 of the model contains strings, you could have the "text" attribute
of a Gtk2::CellRendererText get its values from column 2.
=cut
void gtk_cell_layout_add_attribute (GtkCellLayout *cell_layout, GtkCellRenderer *cell, const gchar *attribute, gint column);

=for apidoc
Sets up I<$cell_layout> to call I<$func> to set up attributes of I<$cell>,
instead of the standard attribute mapping.  I<$func> may be undef to remove
an older callback.  I<$func> will receive these parameters:

=over

=item $cell_layout  The cell layout instance

=item $cell         The cell renderer to set up

=item $model        The tree model

=item $iter         TreeIter of the row for which to set the values

=item $data         The I<$func_data> passed to C<set_cell_data_func>

=back

=cut
void gtk_cell_layout_set_cell_data_func (GtkCellLayout *cell_layout, GtkCellRenderer *cell, SV * func, SV * func_data=NULL);
    CODE:
	if (gperl_sv_is_defined (func)) {
		GType param_types[4];
		GPerlCallback * callback;

		param_types[0] = GTK_TYPE_CELL_LAYOUT;
		param_types[1] = GTK_TYPE_CELL_RENDERER;
		param_types[2] = GTK_TYPE_TREE_MODEL;
		param_types[3] = GTK_TYPE_TREE_ITER;
		callback = gperl_callback_new (func, func_data, 4, param_types,
		                               G_TYPE_NONE);
		gtk_cell_layout_set_cell_data_func
		                    (cell_layout, cell,
		                     gtk2perl_cell_layout_data_func, callback,
			             (GDestroyNotify) gperl_callback_destroy);
	} else
		gtk_cell_layout_set_cell_data_func (cell_layout, cell,
						    NULL, NULL, NULL);

=for apidoc
Clears all existing attributes previously set with for I<$cell> with
C<add_attribute> or C<set_attributes>.
=cut
void gtk_cell_layout_clear_attributes (GtkCellLayout *cell_layout, GtkCellRenderer *cell);

=for apidoc
Re-insert I<$cell> at I<$position>.  I<$cell> must already be packed into
I<$cell_layout>.
=cut
void gtk_cell_layout_reorder (GtkCellLayout *cell_layout, GtkCellRenderer *cell, gint position)

#if GTK_CHECK_VERSION (2, 12, 0)

=for apidoc
Fetch all of the cell renderers which have been added to I<$cell_layout>.

Note that if there are no cells this functions returns 'undef' instead of an
empty list.
=cut
void
gtk_cell_layout_get_cells (GtkCellLayout *cell_layout)
    PREINIT:
	GList *result, *i;
    PPCODE:
	PUTBACK;
	result = gtk_cell_layout_get_cells (cell_layout);
	SPAGAIN;
	if (!result) /* can happen if the widget doesn't implement get_cells */
		XSRETURN_UNDEF;
	for (i = result; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkCellRenderer (i->data)));
	g_list_free (result);

#endif

MODULE = Gtk2::CellLayout	PACKAGE = Gtk2::CellLayout::DataFunc

=for apidoc __hide__
=cut
void
invoke (SV *code, GtkCellLayout *cell_layout, GtkCellRenderer *cell, GtkTreeModel *tree_model, GtkTreeIter *iter, data)
    PREINIT:
	Gtk2PerlCellLayoutDataFunc *wrapper;
    CODE:
	wrapper = INT2PTR (Gtk2PerlCellLayoutDataFunc*, SvIV (SvRV (code)));
	if (!wrapper || !wrapper->func)
		croak ("Invalid reference encountered in cell data func");
	wrapper->func (cell_layout, cell, tree_model, iter, wrapper->data);

void
DESTROY (SV *code)
    PREINIT:
	Gtk2PerlCellLayoutDataFunc *wrapper;
    CODE:
	if (!gperl_sv_is_defined (code) || !SvROK (code))
		return;
	wrapper = INT2PTR (Gtk2PerlCellLayoutDataFunc*, SvIV (SvRV (code)));
	if (wrapper && wrapper->destroy)
		wrapper->destroy (wrapper->data);
	if (wrapper)
		g_free (wrapper);
