/*
 * Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::IMContextSimple	PACKAGE = Gtk2::IMContextSimple	PREFIX = gtk_im_context_simple_

GtkIMContext_noinc * gtk_im_context_simple_new (class)
    C_ARGS:
        /*void*/

### This just copies the pointer value, so we'd have to keep that memory alive;
### likely attached to the object.
##void gtk_im_context_simple_add_table (GtkIMContextSimple *context_simple,
##                                      guint16            *data,
##                                      gint                max_seq_len,
##                                      gint                n_seqs);
