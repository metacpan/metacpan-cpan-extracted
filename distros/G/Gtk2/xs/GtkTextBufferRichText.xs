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
#include <gperl_marshal.h>

static GPerlCallback *
gtk2perl_text_buffer_serialize_func_create (SV * func,
                                            SV * data)
{
        GType param_types[4];
        param_types[0] = GTK_TYPE_TEXT_BUFFER;
        param_types[1] = GTK_TYPE_TEXT_BUFFER;
        param_types[2] = GTK_TYPE_TEXT_ITER;
        param_types[3] = GTK_TYPE_TEXT_ITER;
        return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
                                   param_types, GPERL_TYPE_SV);
}

static guint8 *
gtk2perl_text_buffer_serialize_func (GtkTextBuffer     *register_buffer,
                                     GtkTextBuffer     *content_buffer,
                                     const GtkTextIter *start,
                                     const GtkTextIter *end,
                                     gsize             *length,
                                     gpointer           user_data)
{
        GPerlCallback * callback = (GPerlCallback *) user_data;
        GValue value = {0, };
        SV * ret_sv;
        guint8 * data;
        g_value_init (&value, GPERL_TYPE_SV);
        gperl_callback_invoke (callback, &value,
                               register_buffer, content_buffer, start, end);
        ret_sv = g_value_get_boxed (&value);
        if (gperl_sv_is_defined (ret_sv)) {
                data = (guint8 *) g_strdup (SvPV (ret_sv, (*length)));
        } else {
                *length = 0;
                data = NULL;
        }
        g_value_unset (&value);

        return data;
}

static GPerlCallback *
gtk2perl_text_buffer_deserialize_func_create (SV * func,
                                              SV * data)
{
        GType param_types[5];
        param_types[0] = GTK_TYPE_TEXT_BUFFER;
        param_types[1] = GTK_TYPE_TEXT_BUFFER;
        param_types[2] = GTK_TYPE_TEXT_ITER;
        param_types[3] = GPERL_TYPE_SV,
        param_types[4] = G_TYPE_BOOLEAN;
        return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
                                   param_types, G_TYPE_NONE);
}

static gboolean
gtk2perl_text_buffer_deserialize_func (GtkTextBuffer     *register_buffer,
                                       GtkTextBuffer     *content_buffer,
                                       GtkTextIter       *iter,
                                       const guint8      *data,
                                       gsize              length,
                                       gboolean           create_tags,
                                       gpointer           user_data,
                                       GError           **error)
{
        GPerlCallback *callback = (GPerlCallback*) user_data;
        gboolean retval = TRUE;
        dGPERL_CALLBACK_MARSHAL_SP;

        /* we should trap exceptions and turn those into GErrors.
         * that will require using call_sv() directly. */
        GPERL_CALLBACK_MARSHAL_INIT (callback);

        ENTER;
        SAVETMPS;

        PUSHMARK (SP);

        XPUSHs (sv_2mortal (newSVGtkTextBuffer (register_buffer)));
        XPUSHs (sv_2mortal (newSVGtkTextBuffer (content_buffer)));
        XPUSHs (sv_2mortal (newSVGtkTextIter (iter)));
        XPUSHs (sv_2mortal (newSVpvn ((const char *) data, length)));
        XPUSHs (sv_2mortal (newSViv (create_tags)));
        if (callback->data)
                XPUSHs (callback->data);

        PUTBACK;

        call_sv (callback->func, G_DISCARD | G_EVAL);
        if (gperl_sv_is_defined (ERRSV) && SvTRUE (ERRSV)) {
                if (SvROK (ERRSV) && sv_derived_from (ERRSV, "Glib::Error")) {
                        gperl_gerror_from_sv (ERRSV, error);
                } else {
                        /* g_error_new_literal() won't let us pass 0 for
                         * the domain... */
                        g_set_error (error, 0, 0, "%s", SvPV_nolen (ERRSV));
                }
                retval = FALSE;
        }

        FREETMPS;
        LEAVE;

        return retval;
}


MODULE = Gtk2::TextBufferRichText	PACKAGE = Gtk2::TextBuffer	PREFIX = gtk_text_buffer_


GdkAtom gtk_text_buffer_register_serialize_format (GtkTextBuffer *buffer, const gchar *mime_type, SV * function, SV * user_data=NULL);
    CODE:
        RETVAL = gtk_text_buffer_register_serialize_format
                        (buffer, mime_type,
                         gtk2perl_text_buffer_serialize_func,
                         gtk2perl_text_buffer_serialize_func_create
                                                (function, user_data),
                         (GDestroyNotify) gperl_callback_destroy);
    OUTPUT:
        RETVAL

GdkAtom gtk_text_buffer_register_deserialize_format (GtkTextBuffer *buffer, const gchar *mime_type, SV *function, SV *user_data=NULL);
    CODE:
        RETVAL = gtk_text_buffer_register_deserialize_format
                        (buffer, mime_type,
                         gtk2perl_text_buffer_deserialize_func,
                         gtk2perl_text_buffer_deserialize_func_create
                                                (function, user_data),
                         (GDestroyNotify) gperl_callback_destroy);
    OUTPUT:
        RETVAL

GdkAtom gtk_text_buffer_register_serialize_tagset (GtkTextBuffer *buffer, const gchar_ornull *tagset_name);

GdkAtom gtk_text_buffer_register_deserialize_tagset (GtkTextBuffer *buffer, const gchar_ornull *tagset_name);

void gtk_text_buffer_unregister_serialize_format (GtkTextBuffer *buffer, GdkAtom format);

void gtk_text_buffer_unregister_deserialize_format (GtkTextBuffer *buffer, GdkAtom format);

void gtk_text_buffer_deserialize_set_can_create_tags (GtkTextBuffer *buffer, GdkAtom format, gboolean can_create_tags);

gboolean gtk_text_buffer_deserialize_get_can_create_tags (GtkTextBuffer *buffer, GdkAtom format);

void
gtk_text_buffer_get_serialize_formats (GtkTextBuffer *buffer);
    ALIAS:
        get_deserialize_formats = 1
    PREINIT:
        GdkAtom * formats;
        gint n_formats;
    PPCODE:
        if (ix == 1)
                formats = gtk_text_buffer_get_deserialize_formats (buffer,
                                                                   &n_formats);
        else
                formats = gtk_text_buffer_get_serialize_formats (buffer,
                                                                 &n_formats);
        if (formats) {
                gint i;
                EXTEND (SP, n_formats);
                for (i = 0 ; i < n_formats ; i++)
                        PUSHs (sv_2mortal (newSVGdkAtom (formats[i])));
                g_free (formats);
        }

SV *
gtk_text_buffer_serialize (GtkTextBuffer     * register_buffer, \
                           GtkTextBuffer     * content_buffer, \
                           GdkAtom             format, \
                           const GtkTextIter * start, \
                           const GtkTextIter * end)
    PREINIT:
        guint8 * text;
        gsize length;
    CODE:
        text = gtk_text_buffer_serialize (register_buffer, content_buffer,
                                          format, start, end, &length);
        if (!text)
                XSRETURN_UNDEF;
        RETVAL = newSVpvn ((const char *) text, length);
    OUTPUT:
        RETVAL

=for apidoc __gerror__
=cut
void
gtk_text_buffer_deserialize (GtkTextBuffer     * register_buffer, \
                             GtkTextBuffer     * content_buffer, \
                             GdkAtom             format, \
                             GtkTextIter       * iter, \
                             SV                * data)
    PREINIT:
        GError * error = NULL;
        guint8 * text;
        STRLEN length;
    CODE:
        text = (guint8 *) SvPV (data, length);
        if (!gtk_text_buffer_deserialize (register_buffer, content_buffer,
                                          format, iter, text, length, &error))
                gperl_croak_gerror (NULL, error);

