/*
 * Copyright (C) 2004 by the gtk2-perl team
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * $Id$
 */

#include "gtkmozembed2perl.h"
#include "gperl_marshal.h"

/* ------------------------------------------------------------------------- */

GType
gtk2perl_moz_embed_reload_flags_get_type(void)
{
  static GType reload_flags_type = 0;

  if (!reload_flags_type) {
    static const GFlagsValue values[] = {
      { GTK_MOZ_EMBED_FLAG_RELOADNORMAL, "GTK_MOZ_EMBED_FLAG_RELOADNORMAL", "reloadnormal" },
      { GTK_MOZ_EMBED_FLAG_RELOADBYPASSCACHE, "GTK_MOZ_EMBED_FLAG_RELOADBYPASSCACHE", "reloadbypasscache" },
      { GTK_MOZ_EMBED_FLAG_RELOADBYPASSPROXY, "GTK_MOZ_EMBED_FLAG_RELOADBYPASSPROXY", "reloadbypassproxy" },
      { GTK_MOZ_EMBED_FLAG_RELOADBYPASSPROXYANDCACHE, "GTK_MOZ_EMBED_FLAG_RELOADBYPASSPROXYANDCACHE", "reloadbypassproxyandcache" },
      { GTK_MOZ_EMBED_FLAG_RELOADCHARSETCHANGE, "GTK_MOZ_EMBED_FLAG_RELOADCHARSETCHANGE", "reloadcharset" },
      { 0, NULL, NULL }
    };
    reload_flags_type = g_flags_register_static ("GtkMozEmbedReloadFlags", values);
  }

  return reload_flags_type;
}

/* ------------------------------------------------------------------------- */

GType
gtk2perl_moz_embed_chrome_flags_get_type(void)
{
  static GType chrome_flags_type = 0;

  if (!chrome_flags_type) {
    static const GFlagsValue values[] = {
      { GTK_MOZ_EMBED_FLAG_DEFAULTCHROME, "GTK_MOZ_EMBED_FLAG_DEFAULTCHROME", "defaultchrome" },
      { GTK_MOZ_EMBED_FLAG_WINDOWBORDERSON, "GTK_MOZ_EMBED_FLAG_WINDOWBORDERSON", "windowborderson" },
      { GTK_MOZ_EMBED_FLAG_WINDOWCLOSEON, "GTK_MOZ_EMBED_FLAG_WINDOWCLOSEON", "windowcloseon" },
      { GTK_MOZ_EMBED_FLAG_WINDOWRESIZEON, "GTK_MOZ_EMBED_FLAG_WINDOWRESIZEON", "windowresizeon" },
      { GTK_MOZ_EMBED_FLAG_MENUBARON, "GTK_MOZ_EMBED_FLAG_MENUBARON", "menubaron" },
      { GTK_MOZ_EMBED_FLAG_TOOLBARON, "GTK_MOZ_EMBED_FLAG_TOOLBARON", "toolbaron" },
      { GTK_MOZ_EMBED_FLAG_LOCATIONBARON, "GTK_MOZ_EMBED_FLAG_LOCATIONBARON", "locationbaron" },
      { GTK_MOZ_EMBED_FLAG_STATUSBARON, "GTK_MOZ_EMBED_FLAG_STATUSBARON", "statusbaron" },
      { GTK_MOZ_EMBED_FLAG_PERSONALTOOLBARON, "GTK_MOZ_EMBED_FLAG_PERSONALTOOLBARON", "personaltoolbaron" },
      { GTK_MOZ_EMBED_FLAG_SCROLLBARSON, "GTK_MOZ_EMBED_FLAG_SCROLLBARSON", "scrollbarson" },
      { GTK_MOZ_EMBED_FLAG_TITLEBARON, "GTK_MOZ_EMBED_FLAG_TITLEBARON", "titlebaron" },
      { GTK_MOZ_EMBED_FLAG_EXTRACHROMEON, "GTK_MOZ_EMBED_FLAG_EXTRACHROMEON", "extrachromeon" },
      { GTK_MOZ_EMBED_FLAG_ALLCHROME, "GTK_MOZ_EMBED_FLAG_ALLCHROME", "allchrome" },
      { GTK_MOZ_EMBED_FLAG_WINDOWRAISED, "GTK_MOZ_EMBED_FLAG_WINDOWRAISED", "windowraised" },
      { GTK_MOZ_EMBED_FLAG_WINDOWLOWERED, "GTK_MOZ_EMBED_FLAG_WINDOWLOWERED", "windowlowered" },
      { GTK_MOZ_EMBED_FLAG_CENTERSCREEN, "GTK_MOZ_EMBED_FLAG_CENTERSCREEN", "centerscreen" },
      { GTK_MOZ_EMBED_FLAG_DEPENDENT, "GTK_MOZ_EMBED_FLAG_DEPENDENT", "dependent" },
      { GTK_MOZ_EMBED_FLAG_MODAL, "GTK_MOZ_EMBED_FLAG_MODAL", "modal" },
      { GTK_MOZ_EMBED_FLAG_OPENASDIALOG, "GTK_MOZ_EMBED_FLAG_OPENASDIALOG", "openasdialog" },
      { GTK_MOZ_EMBED_FLAG_OPENASCHROME, "GTK_MOZ_EMBED_FLAG_OPENASCHROME", "openaschrome" },
      { 0, NULL, NULL }
    };
    chrome_flags_type = g_flags_register_static ("GtkMozEmbedChromeFlags", values);
  }

  return chrome_flags_type;
}

/* ------------------------------------------------------------------------- */

static void
gtk2perl_moz_embed_new_window_marshal (GClosure *closure,
                                       GValue *return_value,
                                       guint n_param_values,
                                       const GValue *param_values,
                                       gpointer invocation_hint,
                                       gpointer marshal_data)
{
	dGPERL_CLOSURE_MARSHAL_ARGS;
	GtkMozEmbed **embed;

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);

	/* param_values + 1 is the pointer we're supposed to fill.
	 * param_values + 2 is the chrome mask. */
	XPUSHs (sv_2mortal (newSVGtkMozEmbedChromeFlags
	                     (g_value_get_uint (param_values + 2))));

	GPERL_CLOSURE_MARSHAL_PUSH_DATA;

	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_SCALAR);

	SPAGAIN;

	if (count != 1)
		croak ("signal handlers for `new_window' are supposed to "
		       "return the new GtkMozEmbed object");

	embed = (GtkMozEmbed **) g_value_get_pointer (param_values + 1);
	*embed = SvGtkMozEmbed (POPs);

	PUTBACK;
	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

/* the following two can probably be combined
   if we can find the signal name */

/* gint (* dom_key_press) (GtkMozEmbed *embed, gpointer dom_event); */

#ifdef __cplusplus  /* implies Mozilla::DOM is installed */

static void
gtk2perl_moz_embed_dom_key_marshal (GClosure *closure,
                                    GValue *return_value,
                                    guint n_param_values,
                                    const GValue *param_values,
                                    gpointer invocation_hint,
                                    gpointer marshal_data)
{
	dGPERL_CLOSURE_MARSHAL_ARGS;

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);

	/* param_values + 1 is the `gpointer dom_event' */
	XPUSHs (sv_2mortal (newSVnsIDOMKeyEvent ((nsIDOMKeyEvent *)
                              g_value_get_pointer (param_values + 1))));


	GPERL_CLOSURE_MARSHAL_PUSH_DATA;

	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_SCALAR);

	SPAGAIN;

	if (count != 1)
		croak ("signal handlers for `dom_key_*' are supposed to "
		       "return an integer");

	gperl_value_from_sv (return_value, POPs);

	PUTBACK;

	FREETMPS;
	LEAVE;
}

static void
gtk2perl_moz_embed_dom_mouse_marshal (GClosure *closure,
                                      GValue *return_value,
                                      guint n_param_values,
                                      const GValue *param_values,
                                      gpointer invocation_hint,
                                      gpointer marshal_data)
{
	dGPERL_CLOSURE_MARSHAL_ARGS;

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);

	/* param_values + 1 is the `gpointer dom_event' */
	XPUSHs (sv_2mortal (newSVnsIDOMMouseEvent ((nsIDOMMouseEvent *)
                              g_value_get_pointer (param_values + 1))));


	GPERL_CLOSURE_MARSHAL_PUSH_DATA;

	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_SCALAR);

	SPAGAIN;

	if (count != 1)
		croak ("signal handlers for `dom_mouse_*' are supposed to "
		       "return an integer");

	gperl_value_from_sv (return_value, POPs);

	PUTBACK;

	FREETMPS;
	LEAVE;
}

#endif   /* ifdef __cplusplus */

/* ------------------------------------------------------------------------- */

MODULE = Gtk2::MozEmbed	PACKAGE = Gtk2::MozEmbed	PREFIX = gtk_moz_embed_

BOOT:
#include "register.xsh"
#include "boot.xsh"
#ifdef GTK_MOZ_EMBED_PERL_XULRUNNER_PATH
	gtk_moz_embed_set_path (GTK_MOZ_EMBED_PERL_XULRUNNER_PATH);
#endif /* GTK_MOZ_EMBED_PERL_XULRUNNER_PATH */
	gperl_signal_set_marshaller_for (GTK_TYPE_MOZ_EMBED,
	                                 "new_window",
	                                 gtk2perl_moz_embed_new_window_marshal);
	/* gperl_signal_set_marshaller_for (GTK_TYPE_MOZ_EMBED_SINGLE,
	                                 "new_window_orphan",
	                                 gtk2perl_moz_embed_new_window_marshal); */
#ifdef __cplusplus
	gperl_signal_set_marshaller_for (GTK_TYPE_MOZ_EMBED,
	                                 "dom_key_down",
	                                 gtk2perl_moz_embed_dom_key_marshal);
	gperl_signal_set_marshaller_for (GTK_TYPE_MOZ_EMBED,
	                                 "dom_key_press",
	                                 gtk2perl_moz_embed_dom_key_marshal);
	gperl_signal_set_marshaller_for (GTK_TYPE_MOZ_EMBED,
	                                 "dom_key_up",
	                                 gtk2perl_moz_embed_dom_key_marshal);
	gperl_signal_set_marshaller_for (GTK_TYPE_MOZ_EMBED,
	                                 "dom_mouse_down",
	                                 gtk2perl_moz_embed_dom_mouse_marshal);
	gperl_signal_set_marshaller_for (GTK_TYPE_MOZ_EMBED,
	                                 "dom_mouse_up",
	                                 gtk2perl_moz_embed_dom_mouse_marshal);
	gperl_signal_set_marshaller_for (GTK_TYPE_MOZ_EMBED,
	                                 "dom_mouse_click",
	                                 gtk2perl_moz_embed_dom_mouse_marshal);
	gperl_signal_set_marshaller_for (GTK_TYPE_MOZ_EMBED,
	                                 "dom_mouse_dbl_click",
	                                 gtk2perl_moz_embed_dom_mouse_marshal);
	gperl_signal_set_marshaller_for (GTK_TYPE_MOZ_EMBED,
	                                 "dom_mouse_over",
	                                 gtk2perl_moz_embed_dom_mouse_marshal);
	gperl_signal_set_marshaller_for (GTK_TYPE_MOZ_EMBED,
	                                 "dom_mouse_out",
	                                 gtk2perl_moz_embed_dom_mouse_marshal);
#endif  /* ifdef __cplusplus */

=for object Gtk2::MozEmbed::main

=cut

=for apidoc

This function returns a new Gtk Mozilla embedding widget. On failure it will
return I<undef>.

=cut
##  GtkWidget * gtk_moz_embed_new (void)
GtkWidget_ornull *
gtk_moz_embed_new (class)
    C_ARGS:
	/* void */
    CLEANUP:
#if !GTK_MOZ_EMBED_CHECK_VERSION (1, 7, 3)
	/* To avoid getting a segfault, add an additional ref so that the thing
	   will never get destroyed. */
	if (RETVAL)
		gtk_widget_ref (RETVAL);
#endif

##  void gtk_moz_embed_push_startup (void)
void
gtk_moz_embed_push_startup (class)
    C_ARGS:
	/* void */

##  void gtk_moz_embed_pop_startup (void)
void
gtk_moz_embed_pop_startup (class)
    C_ARGS:
	/* void */

=for apidoc

This function must be called before the first widget is created or XPCOM is
initialized. It allows you to set the path to the mozilla components.

=cut
##  void gtk_moz_embed_set_comp_path (char *aPath)
void
gtk_moz_embed_set_comp_path (class, aPath)
	char *aPath
    C_ARGS:
	aPath

## void gtk_moz_embed_set_profile_path (char *aDir, char *aName)
void
gtk_moz_embed_set_profile_path (class, aDir, aName)
	char *aDir
	char *aName
    C_ARGS:
	aDir, aName

=for apidoc

This function starts loading a url in the embedding widget. All loads are
asynchronous. The url argument should be in the form of http://www.gnome.org.

=cut
##  void gtk_moz_embed_load_url (GtkMozEmbed *embed, const char *url)
void
gtk_moz_embed_load_url (embed, url)
	GtkMozEmbed *embed
	const char *url

=for apidoc

This function will allow you to stop the load of a document that is being
loaded in the widget.

=cut
##  void gtk_moz_embed_stop_load (GtkMozEmbed *embed)
void
gtk_moz_embed_stop_load (embed)
	GtkMozEmbed *embed

=for apidoc

This function will return whether or not you can go backwards in the document's
navigation history. It will return I<TRUE> if it can go backwards, I<FALSE> if
it can't.

=cut
##  gboolean gtk_moz_embed_can_go_back (GtkMozEmbed *embed)
gboolean
gtk_moz_embed_can_go_back (embed)
	GtkMozEmbed *embed

=for apidoc

This function will return whether or not you can go forwards in the document's
navigation history. It will return I<TRUE> if it can go forwards, I<FALSE> if
it can't.

=cut
##  gboolean gtk_moz_embed_can_go_forward (GtkMozEmbed *embed)
gboolean
gtk_moz_embed_can_go_forward (embed)
	GtkMozEmbed *embed

=for apidoc

This function will go backwards one step in the document's navigation history.

=cut
##  void gtk_moz_embed_go_back (GtkMozEmbed *embed)
void
gtk_moz_embed_go_back (embed)
	GtkMozEmbed *embed

=for apidoc

This function will go forward one step in the document's navigation history.

=cut
##  void gtk_moz_embed_go_forward (GtkMozEmbed *embed)
void
gtk_moz_embed_go_forward (embed)
	GtkMozEmbed *embed

=for apidoc

This function will allow you to take a chunk of random data and render it into
the document. You need to pass in the data and the length of the data. The
C<$base_uri> is used to resolve internal references in the document and the
C<$mime_type> is used to determine how to render the document internally.

=cut
##  void gtk_moz_embed_render_data (GtkMozEmbed *embed, const char *data, guint32 len, const char *base_uri, const char *mime_type)
void
gtk_moz_embed_render_data (embed, data, base_uri, mime_type)
	GtkMozEmbed *embed
	SV *data
	const char *base_uri
	const char *mime_type
    PREINIT:
	char *real_data;
	STRLEN len;
    CODE:
	real_data = SvPV (data, len);
	gtk_moz_embed_render_data (embed, real_data, len, base_uri, mime_type);

=for apidoc

This function is used to start loading a document from an external source into
the embedding widget. You need to pass in the C<$base_uri> for resolving
internal links and and the C<$mime_type> of the document.

=cut
##  void gtk_moz_embed_open_stream (GtkMozEmbed *embed, const char *base_uri, const char *mime_type)
void
gtk_moz_embed_open_stream (embed, base_uri, mime_type)
	GtkMozEmbed *embed
	const char *base_uri
	const char *mime_type

=for apidoc

This function allows you to append data to an already opened stream in the
widget. You need to pass in the data that you want to append to the document.

=cut
##  void gtk_moz_embed_append_data (GtkMozEmbed *embed, const char *data, guint32 len)
void
gtk_moz_embed_append_data (embed, data)
	GtkMozEmbed *embed
	SV *data
    PREINIT:
	char *real_data;
	STRLEN len;
    CODE:
	real_data = SvPV (data, len);
	gtk_moz_embed_append_data (embed, real_data, len);

=for apidoc

This function closes the stream that you have been using to append data
manually to the embedding widget.

=cut
##  void gtk_moz_embed_close_stream (GtkMozEmbed *embed)
void
gtk_moz_embed_close_stream (embed)
	GtkMozEmbed *embed

=for apidoc

This function returns the current link message of the document if there is one.

=cut
##  char * gtk_moz_embed_get_link_message (GtkMozEmbed *embed)
char_own *
gtk_moz_embed_get_link_message (embed)
	GtkMozEmbed *embed

=for apidoc

This function returns the js_status message if there is one.

=cut
##  char * gtk_moz_embed_get_js_status (GtkMozEmbed *embed)
char_own *
gtk_moz_embed_get_js_status (embed)
	GtkMozEmbed *embed

=for apidoc

This function will get the current title for a document.

=cut
##  char * gtk_moz_embed_get_title (GtkMozEmbed *embed)
char_own *
gtk_moz_embed_get_title (embed)
	GtkMozEmbed *embed

=for apidoc

This function will return the current location of the document.

=cut
##  char * gtk_moz_embed_get_location (GtkMozEmbed *embed)
char_own *
gtk_moz_embed_get_location (embed)
	GtkMozEmbed *embed

=for apidoc

This function reloads the document. The flags argument can be used to control
the behaviour of the reload.

=cut
##  void gtk_moz_embed_reload (GtkMozEmbed *embed, gint32 flags)
void
gtk_moz_embed_reload (embed, flags)
	GtkMozEmbed *embed
	GtkMozEmbedReloadFlags flags

=for apidoc

This function is used to set the chome mask for this window.

=cut
##  void gtk_moz_embed_set_chrome_mask (GtkMozEmbed *embed, guint32 flags)
void
gtk_moz_embed_set_chrome_mask (embed, flags)
	GtkMozEmbed *embed
	GtkMozEmbedChromeFlags flags

=for apidoc

This function gets the current chome mask for this window. Please see the
documentation for L<Gtk2::MozEmbed::set_chrome_mask> for the value of the
return mask.

=cut
##  guint32 gtk_moz_embed_get_chrome_mask (GtkMozEmbed *embed)
GtkMozEmbedChromeFlags
gtk_moz_embed_get_chrome_mask (embed)
	GtkMozEmbed *embed
    CODE:
	RETVAL = (GtkMozEmbedChromeFlags) gtk_moz_embed_get_chrome_mask (embed);
    OUTPUT:
	RETVAL

#ifdef __cplusplus   /* implies Mozilla::DOM is installed */

=for apidoc

This method gets the nsIWebBrowser for this window.
It is only available if Mozilla::DOM was installed
before building Gtk2::MozEmbed.

Note: it seems that this will return NULL before you've called `show_all'
on your Gtk2::Window object, so check if this returns undef.

=cut
##  void gtk_moz_embed_get_nsIWebBrowser (GtkMozEmbed *embed, nsIWebBrowser **retval)
nsIWebBrowser *
gtk_moz_embed_get_nsIWebBrowser (embed)
	GtkMozEmbed *embed
    PREINIT:
	nsIWebBrowser *browser;
    CODE:
	gtk_moz_embed_get_nsIWebBrowser (embed, &browser);
	RETVAL = browser;
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #

=for object Gtk2::MozEmbed::main

=head1 SIGNALS

=over

=item B<link_message> (Gtk2::MozEmbed)

This signal is emitted when the link message changes. This happens when the
user moves the mouse over a link in a web page. Please use
L<Gtk2::MozEmbed::get_link_message> to get the actual value of the link
message.

=item B<js_status> (Gtk2::MozEmbed)

This signal is emitted when the JavaScript status message changes. Please use
L<Gtk2::MozEmbed::get_js_status> to get the actual value of the js status
message.

=item B<location> (Gtk2::MozEmbed)

This signal is emitted any time that the location of the document has
changed. Please use L<Gtk2::MozEmbed::get_location> to get the actual value of
the location.

=item B<title> (Gtk2::MozEmbed)

This signal is emitted any time that the title of a document has
changed. Please use the L<Gtk2::MozEmbed::get_title> call to get the actual
value of the title.

=item B<progress> (Gtk2::MozEmbed, integer (cur), integer (max))

This signal is emitted any time that there is a change in the progress of
loading a document.

The cur value indicates how much of the document has been downloaded.

The max value indicates the length of the document. If the value of max is less
than one the full length of the document can not be determined.

=item B<net_state> (Gtk2::MozEmbed, integer (flags), unsigned integer (status))

This signal is emitted when there's a change in the state of the loading of a
document.

=item B<net_start> (Gtk2::MozEmbed)

This signal is emitted any time that the load of a document has been started.

=item B<net_stop> (Gtk2::MozEmbed)

This signal is emitted any time that the loading of a document has completed.

=item Gtk2::MozEmbed B<new_window> (Gtk2::MozEmbed, Gtk2::MozEmbed::Chrome)

This signal is emitted any time that a new toplevel window is requested by the
document. This will happen in the case of a window.open() in
JavaScript. Responding to this signal allows you to surround a new toplevel
window with your chrome.

You should return the newly created GtkMozEmbed object.

=item B<visibility> (Gtk2::MozEmbed, boolean)

This signal is emitted when the toplevel window in question needs to be shown
or hidden. If the visibility argument is I<TRUE> then the window should be
shown. If it's I<FALSE> it should be hidden.

=item B<destroy_browser> (Gtk2::MozEmbed)

This signal is emitted when the document as requested that the toplevel window
be closed. This will happen in the case of a JavaScript window.close().

=item boolean B<open_uri> (Gtk2::MozEmbed, string)

This signal is emitted when the document tries to load a new document, for
example when someone clicks on a link in a web page. This signal gives the
embedder the opportunity to keep the new document from being loaded. The uri
argument is the uri that's going to be loaded.

If you return I<TRUE> from this signal, the new document will NOT be loaded. If
you return I<FALSE> the new document will be loaded. This is somewhat
non-intuitive. Think of it as the Mozilla engine is asking if you want to
interrupt the loading of a new document. By returning I<TRUE> you are saying
"don't load this document."

=item integer B<dom_key_down> (Gtk2::MozEmbed, Gtk2::MozEmbed::KeyEvent)

This signal is emitted when a key is pressed down. See the DOM Level 3
specification for more details.

=item integer B<dom_key_up> (Gtk2::MozEmbed, Gtk2::MozEmbed::KeyEvent)

This signal is emitted when a key is released. See the DOM Level 3
specification for more details.

=item integer B<dom_key_press> (Gtk2::MozEmbed, Gtk2::MozEmbed::KeyEvent)

This signal is presumably emitted when a key is pressed and released,
i.e. i.e. a combination of L<Gtk2::MozEmbed::main/dom_key_down> and
L<Gtk2::MozEmbed::main/dom_key_up>. (Note however that it seems to also
get emitted repeatedly if you hold the key down.)

=item integer B<dom_mouse_down> (Gtk2::MozEmbed, Gtk2::MozEmbed::MouseEvent)

This signal is emitted when "a pointing device button is pressed over an
element. In the case of nested elements, this event type is always targeted
at the most deeply nested element." See the DOM Level 3 specification for
more details.

=item integer B<dom_mouse_up> (Gtk2::MozEmbed, Gtk2::MozEmbed::MouseEvent)

This signal is emitted when "a pointing device button is released over an
element. In the case of nested elements, this event type is always targeted
at the most deeply nested element. See the DOM Level 3 specification for
more details.

=item integer B<dom_mouse_click> (Gtk2::MozEmbed, Gtk2::MozEmbed::MouseEvent)

This signal is emitted when "a pointing device button is clicked over
an element. The definition of a click depends on the environment
configuration; i.e. may depend on the screen location or the delay
between the press and release of the pointing device button. In any case,
the target node must be the same between the mousedown, mouseup, and click."
In other words, it's basically L<Gtk2::MozEmbed::main/dom_mouse_down>
followed quickly by L<Gtk2::MozEmbed::main/dom_mouse_up>. See the DOM Level 3
specification for more details.

=item integer B<dom_mouse_dbl_click> (Gtk2::MozEmbed, Gtk2::MozEmbed::MouseEvent)

This signal is emitted when a mouse button is double clicked on an element.
(The only thing I found in the DOM Level 3 specification was an example
showing that two click events occur for a double click.)

=item integer B<dom_mouse_over> (Gtk2::MozEmbed, Gtk2::MozEmbed::MouseEvent)

This signal is emitted when "a pointing device is moved onto an element.
In the case of nested elements, this event type is always targeted at
the most deeply nested element." See the DOM Level 3 specification for
more details.

=item integer B<dom_mouse_out> (Gtk2::MozEmbed, Gtk2::MozEmbed::MouseEvent)

This signal is emitted when "a pointing device is moved away from an
element. In the case of nested elements, this event type is always
targeted at the most deeply nested element." See the DOM Level 3
specification for more details.

=back

=cut

# --------------------------------------------------------------------------- #

# MODULE = Gtk2::MozEmbed	PACKAGE = Gtk2::MozEmbedSingle	PREFIX = gtk_moz_embed_single_

# ##  GtkMozEmbedSingle * gtk_moz_embed_single_get (void)
# GtkMozEmbedSingle *
# gtk_moz_embed_single_get (class)
#     C_ARGS:
# 	/* void */
