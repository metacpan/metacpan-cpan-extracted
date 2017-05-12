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

#define PREP_BOOL(object, path) \
	gboolean ret;	\
	dSP;		\
	ENTER;		\
	SAVETMPS;	\
	PUSHMARK (SP);	\
	PUSHs (sv_2mortal (newSVGObject (G_OBJECT (object))));	\
	XPUSHs (sv_2mortal (newSVGtkTreePath (path)));

#define CALL_AND_RETURN_BOOL(name) \
	PUTBACK;			\
	call_method (name, G_SCALAR);	\
	SPAGAIN;			\
	/* SvTRUE evaluates its arg more than once */	\
	{				\
		SV * sv_ret = POPs;	\
		ret = SvTRUE (sv_ret);	\
	}				\
	PUTBACK;			\
	FREETMPS;			\
	LEAVE;				\
	return ret;

static gboolean
gtk2perl_tree_drag_source_row_draggable (GtkTreeDragSource *drag_source,
                                         GtkTreePath       *path)
{
	PREP_BOOL (drag_source, path);
	CALL_AND_RETURN_BOOL ("ROW_DRAGGABLE");
}

static gboolean
gtk2perl_tree_drag_source_drag_data_get (GtkTreeDragSource *drag_source,
                                         GtkTreePath       *path,
                                         GtkSelectionData  *selection_data)
{
	PREP_BOOL (drag_source, path);
	XPUSHs (sv_2mortal (newSVGtkSelectionData (selection_data)));
	CALL_AND_RETURN_BOOL ("DRAG_DATA_GET");
}

static gboolean
gtk2perl_tree_drag_source_drag_data_delete (GtkTreeDragSource *drag_source,
					    GtkTreePath       *path)
{
	PREP_BOOL (drag_source, path);
	CALL_AND_RETURN_BOOL ("DRAG_DATA_DELETE");
}

static gboolean
gtk2perl_tree_drag_dest_drag_data_received (GtkTreeDragDest  *drag_dest,
					    GtkTreePath      *dest,
					    GtkSelectionData *selection_data)
{
	PREP_BOOL (drag_dest, dest);
	XPUSHs (sv_2mortal (newSVGtkSelectionData (selection_data)));
	CALL_AND_RETURN_BOOL ("DRAG_DATA_RECEIVED");
}

static gboolean
gtk2perl_tree_drag_dest_row_drop_possible (GtkTreeDragDest  *drag_dest,
					   GtkTreePath      *dest_path,
					   GtkSelectionData *selection_data)
{
	PREP_BOOL (drag_dest, dest_path);
	XPUSHs (sv_2mortal (newSVGtkSelectionData (selection_data)));
	CALL_AND_RETURN_BOOL ("ROW_DROP_POSSIBLE");
}

static void
gtk2perl_tree_drag_source_iface_init (GtkTreeDragSourceIface * iface)
{
	iface->row_draggable = gtk2perl_tree_drag_source_row_draggable;
	iface->drag_data_get = gtk2perl_tree_drag_source_drag_data_get;
	iface->drag_data_delete = gtk2perl_tree_drag_source_drag_data_delete;
}

static void
gtk2perl_tree_drag_dest_iface_init (GtkTreeDragDestIface * iface)
{
	iface->drag_data_received = gtk2perl_tree_drag_dest_drag_data_received;
	iface->row_drop_possible = gtk2perl_tree_drag_dest_row_drop_possible;
}



MODULE = Gtk2::TreeDnd	PACKAGE = Gtk2::TreeDragSource	PREFIX = gtk_tree_drag_source_

=for apidoc __hide__
=cut
void
_ADD_INTERFACE (class, const char * target_class)
    CODE:
    {
	static const GInterfaceInfo iface_info = {
		(GInterfaceInitFunc) gtk2perl_tree_drag_source_iface_init,
		(GInterfaceFinalizeFunc) NULL,
		(gpointer) NULL
	};
	GType gtype = gperl_object_type_from_package (target_class);
	g_type_add_interface_static (gtype, GTK_TYPE_TREE_DRAG_SOURCE, &iface_info);
    }

## gboolean gtk_tree_drag_source_row_draggable (GtkTreeDragSource *drag_source, GtkTreePath *path)
gboolean
gtk_tree_drag_source_row_draggable (drag_source, path)
	GtkTreeDragSource *drag_source
	GtkTreePath *path

## gboolean gtk_tree_drag_source_drag_data_delete (GtkTreeDragSource *drag_source, GtkTreePath *path)
gboolean
gtk_tree_drag_source_drag_data_delete (drag_source, path)
	GtkTreeDragSource *drag_source
	GtkTreePath *path

=for apidoc
=for signature selection_data = $drag_source->drag_data_get ($path, $selection_data)
Get selection data from a drag source.  The data is written to $selection_data,
or if $selection_data is not given then to a newly created Gtk2::SelectionData
object with target type C<GTK_TREE_MODEL_ROW>.  On success the return is the
given or new object, or on failure the return is undef.
=cut
### gboolean gtk_tree_drag_source_drag_data_get (GtkTreeDragSource *drag_source, GtkTreePath *path, GtkSelectionData *selection_data)
void
gtk_tree_drag_source_drag_data_get (GtkTreeDragSource *drag_source, GtkTreePath *path, GtkSelectionData *selection_data = NULL)
    PREINIT:
	SV *ret = &PL_sv_undef;
    CODE:
	if (selection_data) {
		if (gtk_tree_drag_source_drag_data_get (drag_source, path,
		                                        selection_data))
			ret = ST(2);
	} else {
		GtkSelectionData new_selection_data = { 0, };
		new_selection_data.target
		  = gdk_atom_intern ("GTK_TREE_MODEL_ROW", FALSE);
		new_selection_data.length = -1;
		if (gtk_tree_drag_source_drag_data_get (drag_source, path,
		                                        &new_selection_data))
			ret = sv_2mortal (newSVGtkSelectionData_copy (&new_selection_data));
	}
	ST(0) = ret;
	XSRETURN(1);

MODULE = Gtk2::TreeDnd	PACKAGE = Gtk2::TreeDragDest	PREFIX = gtk_tree_drag_dest_

=for apidoc __hide__
=cut
void
_ADD_INTERFACE (class, const char * target_class)
    CODE:
    {
	static const GInterfaceInfo iface_info = {
		(GInterfaceInitFunc) gtk2perl_tree_drag_dest_iface_init,
		(GInterfaceFinalizeFunc) NULL,
		(gpointer) NULL
	};
	GType gtype = gperl_object_type_from_package (target_class);
	g_type_add_interface_static (gtype, GTK_TYPE_TREE_DRAG_DEST, &iface_info);
    }

## gboolean gtk_tree_drag_dest_drag_data_received (GtkTreeDragDest *drag_dest, GtkTreePath *dest, GtkSelectionData *selection_data)
gboolean
gtk_tree_drag_dest_drag_data_received (drag_dest, dest, selection_data)
	GtkTreeDragDest *drag_dest
	GtkTreePath *dest
	GtkSelectionData *selection_data

## gboolean gtk_tree_drag_dest_row_drop_possible (GtkTreeDragDest *drag_dest, GtkTreePath *dest_path, GtkSelectionData *selection_data)
gboolean
gtk_tree_drag_dest_row_drop_possible (drag_dest, dest_path, selection_data)
	GtkTreeDragDest *drag_dest
	GtkTreePath *dest_path
	GtkSelectionData *selection_data

MODULE = Gtk2::TreeDnd	PACKAGE = Gtk2::SelectionData	PREFIX = gtk_tree_

## gboolean gtk_tree_set_row_drag_data (GtkSelectionData *selection_data, GtkTreeModel *tree_model, GtkTreePath *path)
gboolean
gtk_tree_set_row_drag_data (selection_data, tree_model, path)
	GtkSelectionData *selection_data
	GtkTreeModel *tree_model
	GtkTreePath *path

## gboolean gtk_tree_get_row_drag_data (GtkSelectionData *selection_data, GtkTreeModel **tree_model, GtkTreePath **path)
=for apidoc
If $selection_data is not of target type GTK_TREE_MODEL_ROW then the return is
an empty list.
=for signature (tree_model, path) = $selection_data->get_row_drag_data
=cut
void
gtk_tree_get_row_drag_data (selection_data)
	GtkSelectionData *selection_data
    PREINIT:
	GtkTreeModel *tree_model;
	GtkTreePath *path;
    PPCODE:
	if (! gtk_tree_get_row_drag_data (selection_data, &tree_model, &path))
		XSRETURN_EMPTY;
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVGtkTreeModel (tree_model)));
	PUSHs (sv_2mortal (newSVGtkTreePath_own (path)));

