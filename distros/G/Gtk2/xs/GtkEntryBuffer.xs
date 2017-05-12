/*
 * Copyright (c) 2010 by the gtk2-perl team (see the file AUTHORS)
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
 * License along with this library. If not, see http://www.gnu.org/licenses/
 */

#include "gtk2perl.h"

MODULE = Gtk2::EntryBuffer      PACKAGE = Gtk2::EntryBuffer     PREFIX = gtk_entry_buffer_

=for apidoc
=for position DESCRIPTION

The B<Gtk2::EntryBuffer> class contains the actual text displayed in a
L<Gtk2::Entry> widget.

A single Gtk2::EntryBuffer object can be shared by multiple Gtk2::Entry
widgets which will then share the same text content, but not the cursor
position, visibility attributes, icon etc.

Gtk2::EntryBuffer may be derived from. Such a derived class might allow
text to be stored in an alternate location, such as non-pageable memory,
useful in the case of important passwords. Or a derived class could
integrate with an application's concept of undo/redo.

=cut

=for apidoc
=for signature entrybuffer = Gtk2::EntryBuffer->new ($initial_chars=undef)
=for arg initial_chars (string)
=cut
GtkEntryBuffer_noinc *
gtk_entry_buffer_new (class, const gchar_utf8_length *initial_chars=NULL, gint length(initial_chars))
    CODE:
        if (initial_chars == NULL) {
                RETVAL = gtk_entry_buffer_new (NULL, 0);
        }
        else {
                RETVAL = gtk_entry_buffer_new (initial_chars, XSauto_length_of_initial_chars);
        }
    OUTPUT:
        RETVAL

gsize gtk_entry_buffer_get_bytes (GtkEntryBuffer *buffer);

guint gtk_entry_buffer_get_length (GtkEntryBuffer *buffer);

const gchar * gtk_entry_buffer_get_text (GtkEntryBuffer *buffer);

void gtk_entry_buffer_set_text (GtkEntryBuffer *buffer, const gchar_utf8_length *chars, gint length(chars));

void gtk_entry_buffer_set_max_length (GtkEntryBuffer *buffer, gint max_length);

gint gtk_entry_buffer_get_max_length (GtkEntryBuffer *buffer);

void gtk_entry_buffer_insert_text (GtkEntryBuffer *buffer, guint position, const gchar_utf8_length *chars, gint length(chars));

guint gtk_entry_buffer_delete_text (GtkEntryBuffer *buffer, guint position=0, gint n_chars=-1);

void gtk_entry_buffer_emit_inserted_text (GtkEntryBuffer *buffer, guint position, const gchar *chars, guint n_chars);

void gtk_entry_buffer_emit_deleted_text (GtkEntryBuffer *buffer, guint position, guint n_chars);
