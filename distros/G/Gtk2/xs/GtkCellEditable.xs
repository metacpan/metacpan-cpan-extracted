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
this is an interface
*/

#define PREP		\
	dSP;		\
	ENTER;		\
	SAVETMPS;	\
	PUSHMARK (SP);	\
	PUSHs (sv_2mortal (newSVGObject (G_OBJECT (cell))));

#define CALL		\
	PUTBACK;	\
	call_sv ((SV *)GvCV (slot), G_VOID|G_DISCARD);

#define FINISH		\
	FREETMPS;	\
	LEAVE;

#define GET_METHOD(method)	\
	HV * stash = gperl_object_stash_from_type (G_OBJECT_TYPE (cell)); \
	GV * slot = gv_fetchmethod (stash, method);

#define METHOD_EXISTS (slot && GvCV (slot))
		

static void
gtk2perl_cell_editable_start_editing (GtkCellEditable *cell,
                                      GdkEvent *event)
{
	GET_METHOD ("START_EDITING");

	if (METHOD_EXISTS) {
		PREP;
		XPUSHs (sv_2mortal (newSVGdkEvent (event)));
		CALL;
		FINISH;
	}
}

static void
gtk2perl_cell_editable_editing_done (GtkCellEditable *cell)
{
	GET_METHOD ("EDITING_DONE");

	if (METHOD_EXISTS) {
		PREP;
		CALL;
		FINISH;
	}
}

static void
gtk2perl_cell_editable_remove_widget (GtkCellEditable *cell)
{
	GET_METHOD ("REMOVE_WIDGET");

	if (METHOD_EXISTS) {
		PREP;
		CALL;
		FINISH;
	}
}

static void
gtk2perl_cell_editable_init (GtkCellEditableIface * iface)
{
	iface->start_editing = gtk2perl_cell_editable_start_editing;
	iface->editing_done  = gtk2perl_cell_editable_editing_done;
	iface->remove_widget = gtk2perl_cell_editable_remove_widget;
}

MODULE = Gtk2::CellEditable	PACKAGE = Gtk2::CellEditable	PREFIX = gtk_cell_editable_

=for apidoc __hide__
=cut
void
_ADD_INTERFACE (class, const char * target_class)
    CODE:
    {
	static const GInterfaceInfo iface_info = {
		(GInterfaceInitFunc) gtk2perl_cell_editable_init,
		(GInterfaceFinalizeFunc) NULL,
		(gpointer) NULL
	};
	GType gtype = gperl_object_type_from_package (target_class);
	g_type_add_interface_static (gtype, GTK_TYPE_CELL_EDITABLE,
	                &iface_info);
    }

## void gtk_cell_editable_start_editing (GtkCellEditable *cell_editable, GdkEvent *event)
void
gtk_cell_editable_start_editing (cell_editable, event=NULL)
	GtkCellEditable *cell_editable
	GdkEvent_ornull *event

## void gtk_cell_editable_editing_done (GtkCellEditable *cell_editable)
void
gtk_cell_editable_editing_done (cell_editable)
	GtkCellEditable *cell_editable

## void gtk_cell_editable_remove_widget (GtkCellEditable *cell_editable)
void
gtk_cell_editable_remove_widget (cell_editable)
	GtkCellEditable *cell_editable

