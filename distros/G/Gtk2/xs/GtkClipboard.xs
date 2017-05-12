/*
 * Copyright (c) 2003-2006 by the gtk2-perl team (see the file AUTHORS)
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
 * this entire object didn't exist in the original 2.0.0 release.  hrm.
 */
#ifdef GTK_TYPE_CLIPBOARD


#define DEFINE_QUARK(stem)	\
static GQuark								\
stem ## _quark (void) 							\
{									\
	static GQuark q = 0;						\
	if (q == 0)							\
		q = g_quark_from_static_string ("gtk2perl_" #stem );	\
	return q;							\
}

DEFINE_QUARK (clipboard_get)
DEFINE_QUARK (clipboard_clear)
DEFINE_QUARK (clipboard_user_data)

static void 
gtk2perl_clipboard_received_func (GtkClipboard *clipboard,
                                  GtkSelectionData *selection_data,
                                  gpointer data)
{
	GPerlCallback * callback = (GPerlCallback*) data;
	gperl_callback_invoke (callback, NULL, clipboard, selection_data);
	gperl_callback_destroy (callback);
}

static void
gtk2perl_clipboard_text_received_func (GtkClipboard *clipboard,
                                       const gchar *text,
                                       gpointer data)
{
	GPerlCallback * callback = (GPerlCallback*) data;
	gperl_callback_invoke (callback, NULL, clipboard, text);
	gperl_callback_destroy (callback);
}

#if GTK_CHECK_VERSION(2, 4, 0)

static void
gtk2perl_clipboard_targets_received_func (GtkClipboard *clipboard,
                                          GdkAtom * targets,
                                          gint n_targets,
                                          gpointer data)
{
	SV * targetlist;
	AV * av;
	int i;
	GPerlCallback * callback = (GPerlCallback*) data;

	av = newAV ();
	for (i = 0 ; i < n_targets ; i++)
		av_push (av, newSVGdkAtom (targets[i]));
	targetlist = sv_2mortal (newRV_noinc ((SV*) av));
	gperl_callback_invoke (callback, NULL, clipboard, targetlist);
	gperl_callback_destroy (callback);
}

#endif

#if GTK_CHECK_VERSION(2, 6, 0)

static void
gtk2perl_clipboard_image_received_func (GtkClipboard *clipboard,
                                        GdkPixbuf *pixbuf,
                                        gpointer data)
{
	GPerlCallback * callback = (GPerlCallback*) data;
	gperl_callback_invoke (callback, NULL, clipboard, pixbuf);
	gperl_callback_destroy (callback);
}

#endif

static void
gtk2perl_clipboard_get_func (GtkClipboard *clipboard,
                             GtkSelectionData *selection_data,
                             guint info,
                             gpointer user_data_or_owner)
{
	GPerlCallback * callback = (GPerlCallback*)
			g_object_get_qdata (G_OBJECT (clipboard),
			                    clipboard_get_quark());
	gperl_callback_invoke (callback, NULL,
	                       clipboard, selection_data, info,
	                       user_data_or_owner);
}

static void
gtk2perl_clipboard_clear_func (GtkClipboard *clipboard,
                               gpointer user_data_or_owner)
{
	GPerlCallback * callback = (GPerlCallback*)
			g_object_get_qdata (G_OBJECT (clipboard),
			                    clipboard_clear_quark());
	gperl_callback_invoke (callback, NULL, clipboard, user_data_or_owner);
}

#if GTK_CHECK_VERSION (2, 10, 0)

static void
gtk2perl_clipboard_rich_text_received_func (GtkClipboard     *clipboard,
                                            GdkAtom           format,
                                            const guint8     *text,
                                            gsize             length,
                                            gpointer          data)
{
        gperl_callback_invoke ((GPerlCallback*) data, NULL, clipboard,
                               sv_2mortal (newSVGdkAtom (format)),
                               sv_2mortal (newSVpvn ((const char *) text, length)));
}

#endif /* 2.10 */

#if GTK_CHECK_VERSION (2, 14, 0)

static void
gtk2perl_clipboard_uri_received_func (GtkClipboard *clipboard,
				      gchar **uris,
				      gpointer data)
{
	/* uris is not owned by us */
        gperl_callback_invoke ((GPerlCallback*) data, NULL, clipboard, uris);
}

#endif /* 2.14 */

#endif /* defined GTK_TYPE_CLIPBOARD */

MODULE = Gtk2::Clipboard	PACKAGE = Gtk2::Clipboard	PREFIX = gtk_clipboard_

#ifdef GTK_TYPE_CLIPBOARD

##  GtkClipboard *gtk_clipboard_get (GdkAtom selection) 
GtkClipboard *
gtk_clipboard_get (class, selection)
	GdkAtom selection
    C_ARGS:
	selection

#if GTK_CHECK_VERSION(2,2,0)

##  GtkClipboard *gtk_clipboard_get_for_display (GdkDisplay *display, GdkAtom selection) 
GtkClipboard *
gtk_clipboard_get_for_display (class, display, selection)
	GdkDisplay *display
	GdkAtom selection
    C_ARGS:
	display, selection

##  GdkDisplay *gtk_clipboard_get_display (GtkClipboard *clipboard) 
GdkDisplay *
gtk_clipboard_get_display (clipboard)
	GtkClipboard *clipboard

#endif /* >=2.2.0 */

####  gboolean gtk_clipboard_set_with_data (GtkClipboard *clipboard, const GtkTargetEntry *targets, guint n_targets, GtkClipboardGetFunc get_func, GtkClipboardClearFunc clear_func, gpointer user_data) 
=for apidoc
=for arg ... of Gtk2::TargetEntry's
=cut
gboolean
gtk_clipboard_set_with_data (clipboard, get_func, clear_func, user_data, ...)
	GtkClipboard *clipboard
	SV * get_func
	SV * clear_func
	SV * user_data
    PREINIT:
	GtkTargetEntry *targets = NULL;
	guint n_targets;
	GPerlCallback * get_callback;
	GType get_param_types[4];
	GPerlCallback * clear_callback;
	GType clear_param_types[2];
	SV * real_user_data;
    CODE:
    	get_param_types[0] = GTK_TYPE_CLIPBOARD;
    	get_param_types[1] = GTK_TYPE_SELECTION_DATA;
    	get_param_types[2] = G_TYPE_UINT;
	/* since we're on the _data one */
    	get_param_types[3] = GPERL_TYPE_SV;

    	clear_param_types[0] = GTK_TYPE_CLIPBOARD;
	/* since we're on the _data one */
    	clear_param_types[1] = GPERL_TYPE_SV;

	GTK2PERL_STACK_ITEMS_TO_TARGET_ENTRY_ARRAY (4, targets, n_targets);
	/* WARNING: since we're piggybacking on the same callback for
	 *    the _with_data and _with_owner forms, the user_data arg
	 *    will go through the standard GSignal user data, and thus
	 *    we'll pass NULL to gperl_callback_new's user_data parameter.
	 *    this is not typical usage. */
	get_callback = gperl_callback_new (get_func, NULL,
	                                   4, get_param_types, G_TYPE_NONE);
	clear_callback = gperl_callback_new (clear_func, NULL,
	                                     2, clear_param_types, G_TYPE_NONE);
	real_user_data = newSVsv (user_data);

	RETVAL = gtk_clipboard_set_with_data (clipboard, targets, n_targets,
	                                      gtk2perl_clipboard_get_func,
	                                      gtk2perl_clipboard_clear_func,
	                                      real_user_data);
	if (!RETVAL) {
		gperl_callback_destroy (get_callback);
		gperl_callback_destroy (clear_callback);
		SvREFCNT_dec (real_user_data);
	} else {
		g_object_set_qdata_full (G_OBJECT (clipboard),
		                         clipboard_get_quark(),
		                         get_callback,
		                         (GDestroyNotify)
		                                gperl_callback_destroy);
		g_object_set_qdata_full (G_OBJECT (clipboard),
		                         clipboard_clear_quark(),
		                         clear_callback,
		                         (GDestroyNotify)
		                                gperl_callback_destroy);
		g_object_set_qdata_full (G_OBJECT (clipboard),
		                         clipboard_user_data_quark (),
		                         real_user_data,
		                         (GDestroyNotify)
		                                gperl_sv_free);
	}
    OUTPUT:
	RETVAL

##  gboolean gtk_clipboard_set_with_owner (GtkClipboard *clipboard, const GtkTargetEntry *targets, guint n_targets, GtkClipboardGetFunc get_func, GtkClipboardClearFunc clear_func, GObject *owner) 
=for apidoc
=for arg ... of Gtk2::TargetEntry's
=cut
gboolean
gtk_clipboard_set_with_owner (clipboard, get_func, clear_func, owner, ...)
	GtkClipboard *clipboard
	SV * get_func
	SV * clear_func
	GObject *owner
    PREINIT:
	GtkTargetEntry *targets = NULL;
	guint n_targets = 0;
	GPerlCallback * get_callback;
	GType get_param_types[4];
	GPerlCallback * clear_callback;
	GType clear_param_types[2];
    CODE:
    	get_param_types[0] = GTK_TYPE_CLIPBOARD;
    	get_param_types[1] = GTK_TYPE_SELECTION_DATA;
    	get_param_types[2] = G_TYPE_UINT;
	/* since we're on the _owner one */
    	get_param_types[3] = G_TYPE_OBJECT;

    	clear_param_types[0] = GTK_TYPE_CLIPBOARD;
	/* since we're on the _owner one */
    	clear_param_types[1] = G_TYPE_OBJECT;

	GTK2PERL_STACK_ITEMS_TO_TARGET_ENTRY_ARRAY (4, targets, n_targets);
	/* WARNING: since we're piggybacking on the same callback for
	 *    the _with_data and _with_owner forms, the owner arg
	 *    will go through the standard GSignal user data, and thus
	 *    we'll pass NULL to gperl_callback_new's user_data parameter.
	 *    this is not typical usage. 
	 *
	 *    you may be thinking that i should just use the same function
	 *    for both forms, like with signal_connect in Glib.  the 
	 *    difference here is that gtk will treat the owner differently --
	 *    you can query the owner -- so we have to call the proper one.
	 *    of course, we could put both of these in the same perl wrapper...
	 */
	get_callback = gperl_callback_new (get_func, NULL,
	                                   4, get_param_types, G_TYPE_NONE);
	clear_callback = gperl_callback_new (clear_func, NULL,
	                                     2, clear_param_types, G_TYPE_NONE);

	RETVAL = gtk_clipboard_set_with_owner (clipboard, targets, n_targets,
	                                       gtk2perl_clipboard_get_func,
	                                       gtk2perl_clipboard_clear_func,
	                                       owner);
	if (!RETVAL) {
		gperl_callback_destroy (get_callback);
		gperl_callback_destroy (clear_callback);
	} else {
		g_object_set_qdata_full (G_OBJECT (clipboard),
		                         clipboard_get_quark(),
		                         get_callback,
		                         (GDestroyNotify)
		                                gperl_callback_destroy);
		g_object_set_qdata_full (G_OBJECT (clipboard),
		                         clipboard_clear_quark(),
		                         clear_callback,
		                         (GDestroyNotify)
		                                gperl_callback_destroy);
	}
    OUTPUT:
	RETVAL

##  GObject *gtk_clipboard_get_owner (GtkClipboard *clipboard) 
###GObject_ornull *
GObject *
gtk_clipboard_get_owner (clipboard)
	GtkClipboard *clipboard

##  void gtk_clipboard_clear (GtkClipboard *clipboard) 
void
gtk_clipboard_clear (clipboard)
	GtkClipboard *clipboard

void gtk_clipboard_set_text (GtkClipboard *clipboard, const gchar_length *text, int length(text)) 

##  void gtk_clipboard_request_contents (GtkClipboard *clipboard, GdkAtom target, GtkClipboardReceivedFunc callback, gpointer user_data) 
void
gtk_clipboard_request_contents (clipboard, target, callback, user_data=NULL)
	GtkClipboard *clipboard
	GdkAtom target
	SV * callback
	SV * user_data
    PREINIT:
	GPerlCallback * real_callback;
	GType param_types[2];
    CODE:
    	param_types[0] = GTK_TYPE_CLIPBOARD;
	param_types[1] = GTK_TYPE_SELECTION_DATA;
	real_callback = gperl_callback_new (callback, user_data,
	                                    2, param_types, G_TYPE_NONE);
	gtk_clipboard_request_contents (clipboard, target, 
	                                gtk2perl_clipboard_received_func,
					real_callback);

##  void gtk_clipboard_request_text (GtkClipboard *clipboard, GtkClipboardTextReceivedFunc callback, gpointer user_data) 
void
gtk_clipboard_request_text (clipboard, callback, user_data=NULL)
	GtkClipboard *clipboard
	SV * callback
	SV * user_data
    PREINIT:
	GPerlCallback * real_callback;
	GType param_types[2];
    CODE:
    	param_types[0] = GTK_TYPE_CLIPBOARD;
    	param_types[1] = G_TYPE_STRING;
	real_callback = gperl_callback_new (callback, user_data,
	                                    2, param_types, G_TYPE_NONE);
	gtk_clipboard_request_text (clipboard, 
				    gtk2perl_clipboard_text_received_func, 
				    real_callback);

##  GtkSelectionData *gtk_clipboard_wait_for_contents (GtkClipboard *clipboard, GdkAtom target) 
GtkSelectionData_own_ornull *
gtk_clipboard_wait_for_contents (clipboard, target)
	GtkClipboard *clipboard
	GdkAtom target

##  gchar * gtk_clipboard_wait_for_text (GtkClipboard *clipboard) 
gchar *
gtk_clipboard_wait_for_text (clipboard)
	GtkClipboard *clipboard
    CLEANUP:
	g_free (RETVAL);

##  gboolean gtk_clipboard_wait_is_text_available (GtkClipboard *clipboard) 
gboolean
gtk_clipboard_wait_is_text_available (clipboard)
	GtkClipboard *clipboard

#if GTK_CHECK_VERSION (2, 4, 0)

##  void gtk_clipboard_request_targets (GtkClipboard *clipboard, GtkClipboardTargetsReceivedFunc  callback, gpointer user_data);
void
gtk_clipboard_request_targets (GtkClipboard *clipboard, SV * callback, SV * user_data=NULL)
    PREINIT:
	GType param_types[2];
	GPerlCallback * real_callback;
    CODE:
	param_types[0] = GTK_TYPE_CLIPBOARD;
	param_types[1] = GPERL_TYPE_SV;

	real_callback = gperl_callback_new (callback, user_data,
	                                    2, param_types, G_TYPE_NONE);
	gtk_clipboard_request_targets
			(clipboard,
			 gtk2perl_clipboard_targets_received_func,
			 real_callback);

=for apidoc
Returns a list of GdkAtom's.
=cut
##  gboolean gtk_clipboard_wait_for_targets (GtkClipboard  *clipboard, GdkAtom **targets, gint *n_targets);
void
gtk_clipboard_wait_for_targets (GtkClipboard  *clipboard)
    PREINIT:
	GdkAtom *targets = NULL;
	gint n_targets, i;
    PPCODE:
	if (!gtk_clipboard_wait_for_targets (clipboard, &targets, &n_targets))
		XSRETURN_EMPTY;
	if (targets) {
		EXTEND (SP, n_targets);
		for (i = 0 ; i < n_targets ; i++)
			PUSHs (sv_2mortal (newSVGdkAtom (targets[i])));
		g_free (targets);
	}

#endif /* 2.4.0 */

#if GTK_CHECK_VERSION (2, 6, 0)

void gtk_clipboard_set_image (GtkClipboard *clipboard, GdkPixbuf *pixbuf);

GdkPixbuf_noinc_ornull * gtk_clipboard_wait_for_image (GtkClipboard *clipboard);

gboolean gtk_clipboard_wait_is_image_available (GtkClipboard *clipboard);

##  void gtk_clipboard_request_image (GtkClipboard *clipboard, GtkClipboardImageReceivedFunc callback, gpointer user_data);
void
gtk_clipboard_request_image (GtkClipboard *clipboard, SV *callback, SV *user_data=NULL)
    PREINIT:
	GType param_types[2];
	GPerlCallback *real_callback;
    CODE:
	param_types[0] = GTK_TYPE_CLIPBOARD;
	param_types[1] = GDK_TYPE_PIXBUF;

	real_callback = gperl_callback_new (callback, user_data,
	                                    2, param_types, G_TYPE_NONE);
	gtk_clipboard_request_image
			(clipboard,
			 gtk2perl_clipboard_image_received_func,
			 real_callback);

##  void gtk_clipboard_set_can_store (GtkClipboard *clipboard, const GtkTargetEntry *targets, gint n_targets);
=for apidoc
=for arg ... of Gtk2::TargetEntry's
=cut
void
gtk_clipboard_set_can_store (clipboard, ...);
	GtkClipboard *clipboard
    PREINIT:
	GtkTargetEntry *targets = NULL;
	guint n_targets;
    CODE:
	GTK2PERL_STACK_ITEMS_TO_TARGET_ENTRY_ARRAY (1, targets, n_targets);
	gtk_clipboard_set_can_store (clipboard, targets, (gint) n_targets);

void gtk_clipboard_store (GtkClipboard *clipboard);

gboolean gtk_clipboard_wait_is_target_available (GtkClipboard *clipboard, GdkAtom target);

#endif /* 2.6.0 */

#if GTK_CHECK_VERSION (2, 10, 0)

##void
##gtk_clipboard_request_rich_text (GtkClipboard                    *clipboard,
##                                 GtkTextBuffer                   *buffer,
##                                 GtkClipboardRichTextReceivedFunc callback,
##                                 gpointer                         user_data)
void
gtk_clipboard_request_rich_text (clipboard, buffer, callback, user_data=NULL)
        GtkClipboard  * clipboard
        GtkTextBuffer * buffer
        SV * callback
        SV * user_data
    PREINIT:
        GPerlCallback * real_callback;
        GType param_types[3];
    CODE:
        param_types[0] = GTK_TYPE_CLIPBOARD;
        param_types[1] = GPERL_TYPE_SV; /* there is no GDK_TYPE_ATOM */
        /* The real callback gets string and length parameters, but
         * perl scalars know their own length, so we won't expose that.
         * The string may have embedded nuls, so we use an SV. */
        param_types[2] = GPERL_TYPE_SV;
        real_callback = gperl_callback_new (callback, user_data,
                                            G_N_ELEMENTS (param_types),
                                            param_types, G_TYPE_NONE);
        gtk_clipboard_request_rich_text
                                (clipboard, buffer,
                                 gtk2perl_clipboard_rich_text_received_func,
				 real_callback);

##guint8 *
##gtk_clipboard_wait_for_rich_text (GtkClipboard  *clipboard,
##                                  GtkTextBuffer *buffer,
##                                  GdkAtom       *format,
##                                  gsize         *length)
void
gtk_clipboard_wait_for_rich_text (clipboard, buffer)
        GtkClipboard  *clipboard
        GtkTextBuffer *buffer
    PREINIT:
        GdkAtom       format;
        gsize         length;
        guint8       *text;
    PPCODE:
        text = gtk_clipboard_wait_for_rich_text (clipboard, buffer,
                                                 &format, &length);
        if (text) {
                EXTEND (SP, 2);
                PUSHs (sv_2mortal (newSVpvn ((const char *) text, length)));
                PUSHs (sv_2mortal (newSVGdkAtom (format)));
                g_free (text);
        }

gboolean gtk_clipboard_wait_is_rich_text_available (GtkClipboard  *clipboard, GtkTextBuffer *buffer)

#endif /* 2.10.0 */

#if GTK_CHECK_VERSION (2, 14, 0)

# void gtk_clipboard_request_uris (GtkClipboard *clipboard, GtkClipboardURIReceivedFunc callback, gpointer user_data);
void
gtk_clipboard_request_uris (GtkClipboard *clipboard, SV *func, SV *data=NULL)
    PREINIT:
	GPerlCallback * callback;
	GType param_types[2];
    CODE:
	param_types[0] = GTK_TYPE_CLIPBOARD;
	param_types[1] = G_TYPE_STRV;
	callback = gperl_callback_new (func, data,
				       G_N_ELEMENTS (param_types),
				       param_types, G_TYPE_NONE);
	gtk_clipboard_request_uris (clipboard,
				    gtk2perl_clipboard_uri_received_func,
				    callback);

# gchar** gtk_clipboard_wait_for_uris (GtkClipboard *clipboard);
SV *
gtk_clipboard_wait_for_uris (GtkClipboard *clipboard)
    PREINIT:
	gchar **strv;
    CODE:
	strv = gtk_clipboard_wait_for_uris (clipboard);
	RETVAL = gperl_new_boxed (strv, G_TYPE_STRV, TRUE); /* we own the strv */
    OUTPUT:
	RETVAL

gboolean gtk_clipboard_wait_is_uris_available (GtkClipboard *clipboard);

#endif /* 2.14 */

#endif /* defined GTK_TYPE_CLIPBOARD */
