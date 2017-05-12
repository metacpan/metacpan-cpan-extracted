/*
 * Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
 * full list)
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at your
 * option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
 *
 * THIS IS A PRIVATE HEADER FOR USE ONLY IN Gtk2 ITSELF.
 *
 * $Id$
 */

#ifndef _GTK2PERL_PRIVATE_H_
#define _GTK2PERL_PRIVATE_H_

#include "gtk2perl.h"

/* Implemented in GtkItemFactory.xs. */
GPerlCallback * gtk2perl_translate_func_create (SV * func, SV * data);
gchar * gtk2perl_translate_func (const gchar *path, gpointer data);

/* Implemented in GtkRecentManager.xs */
const gchar ** gtk2perl_sv_to_strv (SV *sv);
SV * gtk2perl_sv_from_strv (const gchar **strv);

#if GTK_CHECK_VERSION (2, 6, 0)
/* Implemented in GtkTreeView.xs. */
GPerlCallback * gtk2perl_tree_view_row_separator_func_create (SV * func,
							      SV * data);
gboolean gtk2perl_tree_view_row_separator_func (GtkTreeModel *model,
				                GtkTreeIter  *iter,
				                gpointer      data);
#endif

/* Implemented in GtkDialog.xs. */
gint gtk2perl_dialog_response_id_from_sv (SV * sv);
SV * gtk2perl_dialog_response_id_to_sv (gint response);
void gtk2perl_dialog_response_marshal (GClosure * closure,
                                       GValue * return_value,
                                       guint n_param_values,
                                       const GValue * param_values,
                                       gpointer invocation_hint,
                                       gpointer marshal_data);

#endif /* _GTK2PERL_PRIVATE_H_ */
