/*
 * Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for
 * the full list)
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

/* stuff from gmain.h, the main loop and friends */
/*

GMainLoop is in libglib; GClosure is in libgobject.  the mainloop can't refer
to GClosure for dependency reasons, but the code is designed to be used with
GClosure anyway.  that's what we'll do here.

specifically, GSourceDummyMarshal is just a placeholder for GClosureMarshal.

since we have GClosure implemented in GClosure.xs, we'll use it to handle
the callbacks here.


in the more general sense, this file offers the GLib-level interface to the
main loop stuff wrapped by the Gtk2 module.  at the current point, i can't
think of any reason to expose the lower-level main loop stuff here, because
how many apps are going to be using the event loop without Gtk?  then again,
it's quite conceivable that you'd want to do that, so it's not precluded
(just not done).

if you want to implement the main loop stuff here, you'll need to create
typemaps for these types:

	GMainContext	<- Opaque
	GMainLoop	<- Opaque

and you'll need to typemap these if you want to create custom sources
from perl:

	GSource
	GSourceCallbackFuncs
	GSourceFuncs

as far as i can tell, each of these is a ref-counted object, but none
are GObject or GBoxed descendents (as they are part of glib, not gobject!).


for anyone who needs to implement this stuff, i've left the majority
of gmain.h in here, commented out.

*/


/*
 * Since 5.7.3, perl uses "safe" signal handling by default.
 * (As gtk2-perl requires at least 5.8.0, this is relevant to us.)
 * To protect the interpreter from having signal handlers run during
 * important and otherwise uninterruptible operations, when something
 * is installed in %SIG, perl installs a sigaction handler that simply
 * sets a flag saying that a signal is pending; then, at "strategic"
 * points in later operation, it checks that flag.  This is done using
 * the PERL_ASYNC_CHECK() macro after each op.
 *
 * This is important, because while a glib main loop is running, it generally
 * sleeps in a poll(), and control does not normally return to perl.  That
 * causes pending signals to pile up, and looks to the user as though the
 * signals are being ignored.
 *
 * To solve this, the bindings will always install an event source which
 * watches PL_sig_pending, and calls the PERL_ASYNC_CHECK() macro whenever
 * we see it go true.  Since an async signal will wake up a poll(), this
 * will always run at just the right time, so no delays or other performance
 * penalties result.
 *
 * Thanks to Jan Hudec for the implementation idea:
 * http://mail.gnome.org/archives/gtk-perl-list/2004-December/msg00034.html
 */

static gboolean
async_watcher_prepare (GSource * source,
		       gint * timeout)
{
	PERL_UNUSED_VAR (source);
	/* wait as long as you like.  we rely on the fact that the
	 * poll will be awoken by the receipt of an async signal. */
	*timeout = -1;
	return FALSE;
}
static gboolean
async_watcher_check (GSource * source)
{
	PERL_UNUSED_VAR (source);
	return PL_sig_pending;
}
static gboolean
async_watcher_dispatch (GSource     * source,
                        GSourceFunc   callback,
                        gpointer      user_data)
{
	PERL_UNUSED_VAR (source);
	PERL_UNUSED_VAR (callback);
	PERL_UNUSED_VAR (user_data);
	/* this checks PL_sig_pending again, but that's probably not
	 * a bad thing -- it's conceivable that since the check, some
	 * other handler has triggered a perl callback, which would've
	 * cause perl to dispatch the signal handlers, and if we didn't
	 * recheck here we'd redispatch. */
	PERL_ASYNC_CHECK ();
	return TRUE;
}
static void
async_watcher_install (void)
{
	static GSourceFuncs async_watcher_funcs = {
		async_watcher_prepare,
		async_watcher_check,
		async_watcher_dispatch,
		NULL,
		NULL,
		NULL
	};
	/* FIXME: we never unref the watcher. */
	GSource * async_watcher =
		g_source_new (&async_watcher_funcs, sizeof (GSource));
	g_source_attach (async_watcher, NULL);
}

#if GLIB_CHECK_VERSION (2, 4, 0)

static void
gperl_child_watch_callback (GPid pid, gint status, gpointer cb)
{
	gperl_callback_invoke ((GPerlCallback*)cb, NULL, (int) pid, status);
}

#endif /* 2.4 */

MODULE = Glib::MainLoop	PACKAGE = Glib	PREFIX = g_

BOOT:
	async_watcher_install ();

=for object Glib::MainLoop
=cut

#if GLIB_CHECK_VERSION(2,4,0)

=for apidoc __function__
Find the current main loop recursion level.  This is handy in fringe
situations, but those are very rare; see the C API reference for a more
in-depth discussion.
=cut
int g_main_depth ()

#endif

MODULE = Glib::MainLoop	PACKAGE = Glib::MainContext	PREFIX = g_main_context_

=for object Glib::MainLoop An event source manager
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

Event-driven programs need some sort of loop which watches for events and
launches the appropriate actions.  Glib::MainLoop provides this functionality.

Mainloops have context, provided by the MainContext object.  For the most part
you can use the default context (see C<default>), but if you want to create a
subcontext for a nested loop which doesn't have the same event sources, etc,
you can.

Event sources, attached to main contexts, watch for events to happen, and
launch appropriate actions.  Glib provides a few ready-made event sources,
the Glib::Timeout, Glib::Idle, and io watch (C<< Glib::IO->add_watch >>).

Under the hood, Gtk+ adds event sources for GdkEvents to dispatch events to
your widgets.  In fact, Gtk2 provides an abstraction of Glib::MainLoop (See
C<< Gtk2->main >> and friends), so you may rarely have cause to use
Glib::MainLoop directly.

Note: As of version 1.080, the Glib module uses a custom event source to
ensure that perl's safe signal handling and the glib polling event loop
play nicely together.  It is no longer necessary to install a timeout to
ensure that async signals get handled in a timely manner.

=head1 CONSTANTS

C<SOURCE_REMOVE> and C<SOURCE_CONTINUE> are designed for use as the
return values from timeout, idle and I/O watch source functions.  They
return true to keep running or false to remove themselves.  These
constants can help you get that the right way around.

    Glib::SOURCE_CONTINUE     # true
    Glib::SOURCE_REMOVE       # false

=cut
 
 #####################
 ### GMainContext: ###
 #####################

GMainContext *
g_main_context_new (class)
    C_ARGS:
	/*void*/
    CLEANUP:
	g_main_context_unref (RETVAL); /* release the typemap's ref, so the 
	                                  wrapper owns the object */

void
DESTROY (maincontext)
	GMainContext * maincontext
    CODE:
	g_main_context_unref (maincontext);

 ## these are automatic, now
##void          g_main_context_ref       (GMainContext *context);
##void          g_main_context_unref     (GMainContext *context);

GMainContext *
g_main_context_default (class)
    C_ARGS:
	/*void*/

gboolean g_main_context_iteration (GMainContext *context, gboolean may_block);

gboolean g_main_context_pending (GMainContext *context);


##/* For implementation of legacy interfaces */
##GSource *g_main_context_find_source_by_id (GMainContext *context,
##	   				     guint source_id);
##GSource *g_main_context_find_source_by_user_data (GMainContext *context,
##	   					    gpointer user_data);
##GSource *g_main_context_find_source_by_funcs_user_data (GMainContext *context,
## 							  GSourceFuncs *funcs,
##							  gpointer user_data);


##/* Low level functions for implementing custom main loops. */
##void     g_main_context_wakeup  (GMainContext *context);
##gboolean g_main_context_acquire (GMainContext *context);
##void     g_main_context_release (GMainContext *context);
##gboolean g_main_context_wait    (GMainContext *context,
##				 GCond        *cond,
##				 GMutex       *mutex);
##
##gboolean g_main_context_prepare  (GMainContext *context,
##				  gint         *priority);
##gint     g_main_context_query    (GMainContext *context,
##				  gint          max_priority,
##				  gint         *timeout_,
##				  GPollFD      *fds,
##				  gint          n_fds);
##gint     g_main_context_check    (GMainContext *context,
##				  gint          max_priority,
##				  GPollFD      *fds,
##				  gint          n_fds);
##void     g_main_context_dispatch (GMainContext *context);
##
##void      g_main_context_set_poll_func (GMainContext *context,
##					GPollFunc     func);
##GPollFunc g_main_context_get_poll_func (GMainContext *context);
##
##/* Low level functions for use by source implementations */
##void g_main_context_add_poll      (GMainContext *context,
##				   GPollFD      *fd,
##				   gint          priority);
##void g_main_context_remove_poll   (GMainContext *context,
##				   GPollFD      *fd);

#if GLIB_CHECK_VERSION (2, 12, 0)

gboolean g_main_context_is_owner (GMainContext *context);

#endif


MODULE = Glib::MainLoop	PACKAGE = Glib::MainLoop	PREFIX = g_main_loop_

 ##################
 ### GMainLoop: ###
 ##################

 ## the OUTPUT typemap for GMainLoop* takes a ref on the object, and the
 ## DESTROY method for the wrapper releases it.  g_main_loop_new returns
 ## a new object that is to be owned by the wrapper, so it releases the
 ## typemap's reference in the CLEANUP section.

##GMainLoop *g_main_loop_new (GMainContext *context, gboolean is_running);
GMainLoop *
g_main_loop_new (class, context=NULL, is_running=FALSE)
	GMainContext *context
	gboolean is_running
    C_ARGS:
	context, is_running
    CLEANUP:
	g_main_loop_unref (RETVAL);

void
DESTROY (mainloop)
	GMainLoop * mainloop
    CODE:
	g_main_loop_unref (mainloop);

void g_main_loop_run (GMainLoop *loop);

void g_main_loop_quit (GMainLoop *loop);

 ## see above, these are taken care of for you
##GMainLoop *g_main_loop_ref        (GMainLoop    *loop);
##void       g_main_loop_unref      (GMainLoop    *loop);

gboolean g_main_loop_is_running (GMainLoop * loop);

GMainContext * g_main_loop_get_context (GMainLoop * loop);

 ### NOTE: stuff behind G_DISABLE_DEPRECATED shall not be bound.
 ###       i've left their declarations here as a reminder that we didn't
 ###       forget them, they're just not supposed to be included.
 ###
 ##/* ============== Compat main loop stuff ================== */
 ##
 ###ifndef G_DISABLE_DEPRECATED
 ##
 ##/* Legacy names for GMainLoop functions */
 ###define 	g_main_new(is_running)	g_main_loop_new (NULL, is_running);
 ###define         g_main_run(loop)        g_main_loop_run(loop)
 ###define         g_main_quit(loop)       g_main_loop_quit(loop)
 ###define         g_main_destroy(loop)    g_main_loop_unref(loop)
 ###define         g_main_is_running(loop) g_main_loop_is_running(loop)
 ##
 ##/* Functions to manipulate the default main loop */
 ##
 ###define	g_main_iteration(may_block) g_main_context_iteration      (NULL, may_block)
 ###define g_main_pending()            g_main_context_pending        (NULL)
 ##
 ###define g_main_set_poll_func(func)   g_main_context_set_poll_func (NULL, func)
 ##
 ###endif /* G_DISABLE_DEPRECATED */


MODULE = Glib::MainLoop	PACKAGE = Glib::Source	PREFIX = g_source_

=for object Glib::MainLoop
=cut

 ################
 ### GSource: ###
 ################

 ##GSource *g_source_new             (GSourceFuncs   *source_funcs,
 ##				      guint           struct_size);
 ##GSource *g_source_ref             (GSource        *source);
 ##void     g_source_unref           (GSource        *source);
 ##guint    g_source_attach          (GSource        *source,
 ##				      GMainContext   *context);
 ##void     g_source_destroy         (GSource        *source);
 ##void     g_source_set_priority    (GSource        *source,
 ##				      gint            priority);
 ##gint     g_source_get_priority    (GSource        *source);
 ##void     g_source_set_can_recurse (GSource        *source,
 ##				      gboolean        can_recurse);
 ##gboolean g_source_get_can_recurse (GSource        *source);
 ##guint    g_source_get_id          (GSource        *source);
 ##
 ##GMainContext *g_source_get_context (GSource       *source);
 ##
 ##void g_source_set_callback (GSource              *source,
 ##			       GSourceFunc           func,
 ##			       gpointer              data,
 ##			       GDestroyNotify        notify);

 ##void g_source_add_poll         (GSource        *source,
 ##				   GPollFD        *fd);
 ##void g_source_remove_poll      (GSource        *source,
 ##				   GPollFD        *fd);
 ##
 ##void g_source_get_current_time (GSource        *source,
 ##				   GTimeVal       *timeval);
 ##
 ##/* Specific source types */
 ##GSource *g_idle_source_new    (void);
 ##GSource *g_timeout_source_new (guint         interval);

 ##/* Miscellaneous functions
 ## */
 ##void g_get_current_time		        (GTimeVal	*result);


=for apidoc

Remove an event source.  I<$tag> is the number returned by things like
C<< Glib::Timeout->add >>, C<< Glib::Idle->add >>, and
C<< Glib::IO->add_watch >>.

=cut
gboolean
g_source_remove (class, tag)
	guint tag
    C_ARGS:
	tag

 ##gboolean g_source_remove_by_user_data        (gpointer       user_data);
 ##gboolean g_source_remove_by_funcs_user_data  (GSourceFuncs  *funcs,
 ##					      gpointer       user_data);


MODULE = Glib::MainLoop	PACKAGE = Glib::Timeout	PREFIX = g_timeout_

=for object Glib::MainLoop
=cut

 ##########################
 ### Idles and timeouts ###
 ##########################

=for apidoc
=for arg interval number of milliseconds
=for arg callback (subroutine)

Run I<$callback> every I<$interval> milliseconds until I<$callback> returns
false.  Returns a source id which may be used with C<< Glib::Source->remove >>.
Note that a mainloop must be active for the timeout to execute.

=cut
guint
g_timeout_add (class, interval, callback, data=NULL, priority=G_PRIORITY_DEFAULT)
	guint interval
	SV * callback
	SV * data
	gint priority
    PREINIT:
	GClosure * closure;
	GSource * source;
    CODE:
	closure = gperl_closure_new (callback, data, FALSE);
	source = g_timeout_source_new (interval);
	if (priority != G_PRIORITY_DEFAULT)
		g_source_set_priority (source, priority);
	g_source_set_closure (source, closure);
	RETVAL = g_source_attach (source, NULL);
	g_source_unref (source);
    OUTPUT:
	RETVAL

#if GLIB_CHECK_VERSION (2, 14, 0)

guint
g_timeout_add_seconds (class, guint interval, SV * callback, SV * data=NULL, gint priority=G_PRIORITY_DEFAULT)
    PREINIT:
	GClosure * closure;
	GSource * source;
    CODE:
	closure = gperl_closure_new (callback, data, FALSE);
	source = g_timeout_source_new_seconds (interval);
	if (priority != G_PRIORITY_DEFAULT)
		g_source_set_priority (source, priority);
	g_source_set_closure (source, closure);
	RETVAL = g_source_attach (source, NULL);
	g_source_unref (source);
    OUTPUT:
	RETVAL

#endif

MODULE = Glib::MainLoop	PACKAGE = Glib::Idle	PREFIX = g_idle_

=for object Glib::MainLoop
=cut

=for apidoc
=for arg callback (subroutine)

Run I<$callback> when the mainloop is idle.  If I<$callback> returns false,
it will uninstall itself, otherwise, it will run again at the next idle
iteration.  Returns a source id which may be used with
C<< Glib::Source->remove >>.

=cut
guint
g_idle_add (class, callback, data=NULL, priority=G_PRIORITY_DEFAULT_IDLE)
	SV * callback
	SV * data
	gint priority
    PREINIT:
	GClosure * closure;
	GSource * source;
    CODE:
	closure = gperl_closure_new (callback, data, FALSE);
	source = g_idle_source_new ();
	g_source_set_priority (source, priority);
	g_source_set_closure (source, closure);
	RETVAL = g_source_attach (source, NULL);
	g_source_unref (source);
    OUTPUT:
	RETVAL

### FIXME i'm not sure about how to search for the data if we set SVs there.
##gboolean	g_idle_remove_by_data	(gpointer	data);


MODULE = Glib::MainLoop	PACKAGE = Glib::IO	PREFIX = g_io_

=for object Glib::MainLoop
=cut

BOOT:
	gperl_register_fundamental (G_TYPE_IO_CONDITION, "Glib::IOCondition");

=for enum Glib::IOCondition
=cut

=for apidoc
=for arg fd (integer) file descriptor, e.g. fileno($filehandle)
=for arg callback (subroutine)

Run I<$callback> when there is an event on I<$fd> that matches I<$condition>.
The watch uninstalls itself if I<$callback> returns false.
Returns a source id that may be used with C<< Glib::Source->remove >>.

Glib's IO channels serve the same basic purpose as Perl's file handles, so
for the most part you don't see GIOChannels in Perl.  The IO watch integrates
IO operations with the main loop, which Perl file handles don't do.  For
various reasons, this function requires raw file descriptors, not full
file handles.  See C<fileno> in L<perlfunc>.

=cut
guint
g_io_add_watch (class, fd, condition, callback, data=NULL, priority=G_PRIORITY_DEFAULT)
	int fd
	GIOCondition condition
	SV * callback
	SV * data
	gint priority
    PREINIT:
	GClosure * closure;
	GSource * source;
	GIOChannel * channel;
    CODE:
#ifdef USE_SOCKETS_AS_HANDLES
        /* native win32 doesn't have fd's, so first convert perls fd into a winsock fd */
        channel = g_io_channel_win32_new_socket ((HANDLE)win32_get_osfhandle (fd));
#else
        channel = g_io_channel_unix_new (fd);
#endif  /* USE_SOCKETS_AS_HANDLES */
	source = g_io_create_watch (channel, condition);
	if (priority != G_PRIORITY_DEFAULT)
		g_source_set_priority (source, priority);
	closure = gperl_closure_new (callback, data, FALSE);
	g_source_set_closure (source, closure);
	RETVAL = g_source_attach (source, NULL);
	g_source_unref (source);
	g_io_channel_unref (channel);
    OUTPUT:
	RETVAL


MODULE = Glib::MainLoop	PACKAGE = Glib::Child	PREFIX = g_child_

=for object Glib::MainLoop
=cut

#if GLIB_CHECK_VERSION (2, 4, 0)

=for apidoc
=for arg pid (integer) child process ID
=for arg callback (subroutine)

Add a source to the default main context which will call

    &$callback ($pid, $waitstatus, $data)

when child process $pid terminates.  The return value is a source id
which can be used with C<< Glib::Source->remove >>.  When the callback
is made the source is removed automatically.

In a non-threaded program Glib implements this source by installing a
SIGCHLD handler.  Don't change $SIG{CHLD} in Perl or the callback will
never run.

=cut
guint
g_child_watch_add (class, int pid, SV *callback, SV *data=NULL, gint priority=G_PRIORITY_DEFAULT)
    PREINIT:
	GPerlCallback* cb;
	GType param_types[2];
    CODE:
	/* As of Glib 2.16.4 there's no "callback_closure" func in
	   g_child_watch_funcs, and none added there by
	   g_source_set_closure (unlike idle, timeout and io above),
	   so go GPerlCallback style. */
	param_types[0] = G_TYPE_INT;
	param_types[1] = G_TYPE_INT;
	cb = gperl_callback_new (callback, data, 2, param_types, 0);
	RETVAL = g_child_watch_add_full (priority, (GPid) pid,
	       	 			 gperl_child_watch_callback,
					 cb,
	       	 	(GDestroyNotify) gperl_callback_destroy);
    OUTPUT:
	RETVAL

#endif /* 2.4 */
