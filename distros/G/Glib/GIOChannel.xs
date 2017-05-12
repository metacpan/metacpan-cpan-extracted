/*
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the full
 * list)
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
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * $Id$
 */

#include "gperl.h"

/*
GIOChannel is GLib's way to creating a portable and unified for IO
over files, sockets, pipes, and whatever else acts like an FD 
on unix.

but perl's filehandles already do this.

so we'll just replace the GLib concept of GIOChannel with perl
file handles or at least filenos.

thus, pretty much nothing from this header is bound to perl,
except for a one-way boxed wrapper to convert GIOChannels into
file descriptors for gperl_closure_marshal.
*/

static SV*
gperl_io_channel_wrap (GType        gtype,
                       const char * package,
                       GIOChannel * channel,
                       gboolean     own)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	PERL_UNUSED_VAR (own);
	return newSViv (g_io_channel_unix_get_fd (channel));
}
static gpointer
gperl_io_channel_unwrap (GType        gtype,
                         const char * package,
                         SV         * sv)
{
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);
	PERL_UNUSED_VAR (sv);
	croak ("can't unwrap GIOChannels -- how'd you get one in perl?!?\n"
	       " you appear to have found a bug in gtk2-perl-xs.  congratulations.\n"
	       " please report this bug to gtk-perl-list@gnome.org\n"
	       " croaking ");
	return NULL;
}

static GPerlBoxedWrapperClass io_channel_wrapper_class = {
	(GPerlBoxedWrapFunc) gperl_io_channel_wrap,
	gperl_io_channel_unwrap,
	NULL
};

MODULE = Glib::IO::Channel	PACKAGE = Glib::IO::Channel	PREFIX = g_io_channel_

BOOT:
	gperl_register_boxed (G_TYPE_IO_CHANNEL, "Glib::IO::Channel",
	                      &io_channel_wrapper_class);

##void        g_io_channel_init   (GIOChannel    *channel);
##void        g_io_channel_ref    (GIOChannel    *channel);
##void        g_io_channel_unref  (GIOChannel    *channel);
##
###ifndef G_DISABLE_DEPRECATED
##GIOError g_io_channel_read (GIOChannel *channel, gchar *buf, gsize count, gsize *bytes_read);
##GIOError g_io_channel_write (GIOChannel *channel, const gchar *buf, gsize count, gsize *bytes_written);
##GIOError g_io_channel_seek (GIOChannel *channel, gint64 offset, GSeekType type);
##void g_io_channel_close (GIOChannel *channel);
###endif /* G_DISABLE_DEPRECATED */
##
##GIOStatus g_io_channel_shutdown (GIOChannel      *channel,
##				 gboolean         flush,
##				 GError         **err);

####
#### g_io_add_watch is bound in GMainLoop.xs as Glib::IO->add_watch
####
##guint     g_io_add_watch_full   (GIOChannel      *channel,
##				 gint             priority,
##				 GIOCondition     condition,
##				 GIOFunc          func,
##				 gpointer         user_data,
##				 GDestroyNotify   notify);
##GSource * g_io_create_watch     (GIOChannel      *channel,
##				 GIOCondition     condition);
##guint     g_io_add_watch        (GIOChannel      *channel,
##				 GIOCondition     condition,
##				 GIOFunc          func,
##				 gpointer         user_data);


##/* character encoding conversion involved functions.
## */
##
##void                  g_io_channel_set_buffer_size      (GIOChannel   *channel,
##							 gsize         size);
##gsize                 g_io_channel_get_buffer_size      (GIOChannel   *channel);
##GIOCondition          g_io_channel_get_buffer_condition (GIOChannel   *channel);
##GIOStatus             g_io_channel_set_flags            (GIOChannel   *channel,
##							 GIOFlags      flags,
##							 GError      **error);
##GIOFlags              g_io_channel_get_flags            (GIOChannel   *channel);
##void                  g_io_channel_set_line_term        (GIOChannel   *channel,
##							 const gchar  *line_term,
##							 gint          length);
##G_CONST_RETURN gchar* g_io_channel_get_line_term        (GIOChannel   *channel,
##							 gint         *length);
##void		      g_io_channel_set_buffered		(GIOChannel   *channel,
##							 gboolean      buffered);
##gboolean	      g_io_channel_get_buffered		(GIOChannel   *channel);
##GIOStatus             g_io_channel_set_encoding         (GIOChannel   *channel,
##							 const gchar  *encoding,
##							 GError      **error);
##G_CONST_RETURN gchar* g_io_channel_get_encoding         (GIOChannel   *channel);
##void                  g_io_channel_set_close_on_unref	(GIOChannel   *channel,
##							 gboolean      do_close);
##gboolean              g_io_channel_get_close_on_unref	(GIOChannel   *channel);
##
##
##GIOStatus   g_io_channel_flush            (GIOChannel   *channel,
##					   GError      **error);
##GIOStatus   g_io_channel_read_line        (GIOChannel   *channel,
##					   gchar       **str_return,
##					   gsize        *length,
##					   gsize        *terminator_pos,
##					   GError      **error);
##GIOStatus   g_io_channel_read_line_string (GIOChannel   *channel,
##					   GString      *buffer,
##					   gsize        *terminator_pos,
##					   GError      **error);
##GIOStatus   g_io_channel_read_to_end      (GIOChannel   *channel,
##					   gchar       **str_return,
##					   gsize        *length,
##					   GError      **error);
##GIOStatus   g_io_channel_read_chars       (GIOChannel   *channel,
##					   gchar        *buf,
##					   gsize         count,
##					   gsize        *bytes_read,
##					   GError      **error);
##GIOStatus   g_io_channel_read_unichar     (GIOChannel   *channel,
##					   gunichar     *thechar,
##					   GError      **error);
##GIOStatus   g_io_channel_write_chars      (GIOChannel   *channel,
##					   const gchar  *buf,
##					   gssize        count,
##					   gsize        *bytes_written,
##					   GError      **error);
##GIOStatus   g_io_channel_write_unichar    (GIOChannel   *channel,
##					   gunichar      thechar,
##					   GError      **error);
##GIOStatus   g_io_channel_seek_position    (GIOChannel   *channel,
##					   gint64        offset,
##					   GSeekType     type,
##					   GError      **error);
##GIOChannel* g_io_channel_new_file         (const gchar  *filename,
##					   const gchar  *mode,
##					   GError      **error);
##
##/* Error handling */
##
##GQuark          g_io_channel_error_quark      (void);
##GIOChannelError g_io_channel_error_from_errno (gint en);
##
##GIOChannel* g_io_channel_unix_new    (int         fd);
##gint        g_io_channel_unix_get_fd (GIOChannel *channel);
##
##/* Hook for GClosure / GSource integration. Don't touch */
##GLIB_VAR GSourceFuncs g_io_watch_funcs;
##
###ifdef G_OS_WIN32
##
##/* You can use this "pseudo file descriptor" in a GPollFD to add
## * polling for Windows messages. GTK applications should not do that.
## */
##
###define G_WIN32_MSG_HANDLE 19981206
##
##/* Use this to get a GPollFD from a GIOChannel, so that you can call
## * g_io_channel_win32_poll(). After calling this you should only use
## * g_io_channel_read() to read from the GIOChannel, i.e. never read()
## * from the underlying file descriptor. For SOCKETs, it is possible to call
## * recv().
## */
##void        g_io_channel_win32_make_pollfd (GIOChannel   *channel,
##					    GIOCondition  condition,
##					    GPollFD      *fd);
##
##/* This can be used to wait a until at least one of the channels is readable.
## * On Unix you would do a select() on the file descriptors of the channels.
## */
##gint        g_io_channel_win32_poll   (GPollFD    *fds,
##				       gint        n_fds,
##				       gint        timeout_);
##
##/* Create an IO channel for Windows messages for window handle hwnd. */
##GIOChannel *g_io_channel_win32_new_messages (guint hwnd);
##
##GIOChannel* g_io_channel_win32_new_fd (gint         fd);
##
##gint        g_io_channel_win32_get_fd (GIOChannel *channel);
##
##/* Create an IO channel for a winsock socket. The parameter should be
## * a SOCKET. Contrary to IO channels for file descriptors (on *Win32),
## * you can use normal recv() or recvfrom() on sockets even if GLib
## * is polling them.
## */
##GIOChannel *g_io_channel_win32_new_socket (gint socket);
##
###endif
##
