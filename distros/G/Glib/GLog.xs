/*
 * Copyright (C) 2003-2005, 2009, 2012-2013 by the gtk2-perl team (see the
 * file AUTHORS for the full list)
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
#include "gperl-gtypes.h"
#include "gperl-private.h" /* for GPERL_SET_CONTEXT */

=head2 GLog

GLib has a message logging mechanism which it uses for the g_return_if_fail()
assertion macros, etc.; it's really versatile and allows you to set various
levels to be fatal and whatnot.  Libraries use these for various types of
message reporting.

These functions let you reroute those messages from Perl.  By default, 
the warning, critical, and message levels go through perl's warn(), and
fatal ones go through croak().  [i'm not sure that these get to croak()
before GLib abort()s on them...]

=over

=cut

#if 0
/* Log level shift offset for user defined
 * log levels (0-7 are used by GLib).
 */
#define G_LOG_LEVEL_USER_SHIFT  (8)

/* GLib log levels that are considered fatal by default */
#define G_LOG_FATAL_MASK        (G_LOG_FLAG_RECURSION | G_LOG_LEVEL_ERROR)
#endif

SV *
newSVGLogLevelFlags (GLogLevelFlags flags)
{
	return gperl_convert_back_flags (GPERL_TYPE_LOG_LEVEL_FLAGS, flags);
}

GLogLevelFlags
SvGLogLevelFlags (SV * sv)
{
	return gperl_convert_flags (GPERL_TYPE_LOG_LEVEL_FLAGS, sv);
}

/* for GLogFunc style, to be invoked by gperl_log_func() below */
static GPerlCallback *
gperl_log_callback_new (SV *log_func, SV *user_data)
{
	GType param_types[3];
	param_types[0] = G_TYPE_STRING;
	param_types[1] = GPERL_TYPE_LOG_LEVEL_FLAGS;
	param_types[2] = G_TYPE_STRING;
	return gperl_callback_new (log_func, user_data,
				   3, param_types, G_TYPE_NONE);
}
static void
gperl_log_func (const gchar   *log_domain,
                GLogLevelFlags log_level,
                const gchar   *message,
                gpointer       user_data)
{
	gperl_callback_invoke ((GPerlCallback *) user_data, NULL,
	                       log_domain, log_level, message);
}

#if GLIB_CHECK_VERSION (2, 6, 0)
/* the GPerlCallback currently installed through
   g_log_set_default_handler(), or NULL if no such */
static GPerlCallback *gperl_log_default_handler_callback = NULL;
G_LOCK_DEFINE_STATIC (gperl_log_default_handler_callback);
#endif

void
gperl_log_handler (const gchar   *log_domain,
                   GLogLevelFlags log_level,
                   const gchar   *message,
                   gpointer       user_data)
{
        char *desc;
        char *env;

	gboolean in_recursion = (log_level & G_LOG_FLAG_RECURSION) != 0;
	gboolean is_fatal = (log_level & G_LOG_FLAG_FATAL) != 0;
	PERL_UNUSED_VAR (user_data);

	log_level &= G_LOG_LEVEL_MASK;

	if (!message)
		message = "(NULL) message";

	switch (log_level) {
                case G_LOG_LEVEL_ERROR:    desc = "ERROR";    break;
                case G_LOG_LEVEL_CRITICAL: desc = "CRITICAL"; break;
                case G_LOG_LEVEL_WARNING:  desc = "WARNING";  break;
                case G_LOG_LEVEL_MESSAGE:  desc = "Message";  break;
                case G_LOG_LEVEL_INFO:     desc = "INFO";     break;
                case G_LOG_LEVEL_DEBUG:    desc = "DEBUG";    break;
                default: desc = "LOG";
	}

        /* GLib will automatically skip debug messages unless the
         * G_MESSAGES_DEBUG environment variable is set to either
         * "all" or a colon-separated list of log domains that include
         * the domain used for the message.
         */
        if (log_level & (G_LOG_LEVEL_INFO | G_LOG_LEVEL_DEBUG)) {
                const char *env = g_getenv ("G_MESSAGES_DEBUG");
                if (env == NULL)
                        return;
                if (strcmp (env, "all") != 0 &&
                    (log_domain == NULL || strstr (env, log_domain) == NULL)) {
                        return;
                }
        }

	GPERL_SET_CONTEXT;
	warn ("%s%s%s %s**: %s",
	      (log_domain ? log_domain : ""),
	      (log_domain ? "-" : ""),
	      desc,
	      (in_recursion ? "(recursed) " : ""),
	      message);

	/* the standard log handler calls abort() for G_LOG_LEVEL_ERROR
	 * messages.  this is handy for being able to stop gdb on the
	 * error and get a backtrace.  we originally mapped the error
	 * level stuff to croak(), but this broke the ability to find
	 * these errors in gdb, and didn't stop the script as expected
	 * in the perl debugger.  so, let's preserve the GLib semantics. */
	if (is_fatal)
		/* XXX would be nice to get a perl backtrace here, but
		 * XXX Carp::cluck() doesn't print anything useful here. */
		abort ();
}

#define ALL_LOGS (G_LOG_LEVEL_MASK | G_LOG_FLAG_FATAL | G_LOG_FLAG_RECURSION)

=item gint gperl_handle_logs_for (const gchar * log_domain)

Route all g_logs for I<log_domain> through gperl's log handling.  You'll
have to register domains in each binding submodule, because there's no way
we can know about them down here.

And, technically, this traps all the predefined log levels, not any of
the ones you (or your library) may define for yourself.

=cut
gint
gperl_handle_logs_for (const gchar * log_domain)
{
	return g_log_set_handler (log_domain, ALL_LOGS,
	                          gperl_log_handler, NULL);
}

=back

=cut

MODULE = Glib::Log	PACKAGE = Glib::Log	PREFIX = g_log_

=for object Glib::Log A flexible logging mechanism
=cut

BOOT:
	gperl_handle_logs_for (NULL);
	/* gperl_handle_logs_for ("main"); */
	gperl_handle_logs_for ("GLib");
	gperl_handle_logs_for ("GLib-GObject");
	gperl_register_fundamental (GPERL_TYPE_LOG_LEVEL_FLAGS,
	                            "Glib::LogLevelFlags");

=for flags Glib::LogLevelFlags
=cut

##
## Logging mechanism
##
##guint g_log_set_handler (const gchar *log_domain, GLogLevelFlags log_levels, GLogFunc log_func, gpointer user_data);
=for apidoc

=for arg log_domain name of the domain to handle with this callback.

=arg log_levels (GLogLevelFlags) log levels to handle with this callback

=arg log_func (subroutine) handler function

$log_func will be called as

    &$log_func ($log_domain, $log_levels, $message, $user_data);

where $log_domain is the name requested and $log_levels is a
Glib::LogLevelFlags of level and flags being reported.
=cut
guint
g_log_set_handler (class, gchar_ornull * log_domain, SV * log_levels, SV * log_func, SV * user_data=NULL)
    PREINIT:
	GPerlCallback * callback;
    CODE:
	callback = gperl_log_callback_new (log_func, user_data);
	RETVAL = g_log_set_handler (log_domain,
				    SvGLogLevelFlags (log_levels),
				    gperl_log_func, callback);
	/* we have no choice but to leak the callback. */
	/* FIXME what about keeping a hash by the ID, and freeing it on
	 *       Glib::Log->remove_handler ($id)? */
        /*pcg: would probably take more memory in typical programs... */
    OUTPUT:
	RETVAL

##void g_log_remove_handler (const gchar *log_domain, guint handler_id);
=for apidoc
=for arg handler_id as returned by C<set_handler>
=cut
void
g_log_remove_handler (class, gchar_ornull *log_domain, guint handler_id);
    C_ARGS:
	log_domain, handler_id

=for apidoc __function__
=for signature Glib::Log::default_handler ($log_domain, $log_level, $message, ...)
=for arg ... possible "userdata" argument ignored
The arguments are the same as taken by the function for set_handler or
set_default_handler.
=cut
void g_log_default_handler (const gchar *log_domain, SV *log_level, const gchar *message, ...);
    CODE:
	g_log_default_handler (log_domain, SvGLogLevelFlags(log_level),
			       message, NULL);

#if GLIB_CHECK_VERSION (2, 6, 0)

##GLogFunc g_log_set_default_handler (GLogFunc log_func, gpointer user_data);
=for apidoc
=for signature prev_log_func = Glib::Log->set_default_handler ($log_func, $user_data)
=arg log_func (subroutine) handler function or undef
Install log_func as the default log handler.  log_func is called for
anything which doesn't otherwise have a handler (either
Glib::Log->set_handler, or the L<Glib::xsapi|Glib::xsapi>
gperl_handle_logs_for),

    &$log_func ($log_domain, $log_levels, $message, $user_data)

where $log_domain is a string, and $log_levels is a
Glib::LogLevelFlags of level and flags being reported.

If log_func is \&Glib::Log::default_handler or undef then Glib's
default handler is set.

The return value from C<set_default_handler> is the previous handler.
This is \&Glib::Log::default_handler for Glib's default, otherwise a
Perl function previously installed.  If the handler is some other
non-Perl function then currently the return is undef, but perhaps that
will change to some wrapped thing, except that without associated
userdata there's very little which could be done with it (it couldn't
be reinstalled later without its userdata).
=cut
SV *
g_log_set_default_handler (class, SV * log_func, SV * user_data=NULL)
    PREINIT:
	GLogFunc new_func = &g_log_default_handler;
	GLogFunc old_func;
	GPerlCallback *new_callback = NULL;
	GPerlCallback *old_callback;
    CODE:
	if (gperl_sv_is_defined (log_func)) {
		/* check for log_func == \&Glib::Log::default_handler and
		 * turn that into g_log_default_handler() directly, rather
		 * than making a callback into perl and out again.  This is
		 * mainly an optimization, but if something weird has
		 * happened then the direct C function will be much more
		 * likely to work.
		 */
		HV *st;
		GV *gv;
		CV *cv = sv_2cv(log_func, &st, &gv, 0);
		if (cv && CvXSUB(cv) == XS_Glib__Log_default_handler) {
			/* new_func already initialized to
			 * g_log_default_handler above
                         */
		} else {
			new_func = gperl_log_func;
			new_callback = gperl_log_callback_new
				(log_func, user_data);
		}
	}

	G_LOCK (gperl_log_default_handler_callback);

	old_func = g_log_set_default_handler (new_func, new_callback);
	old_callback = gperl_log_default_handler_callback;
	gperl_log_default_handler_callback = new_callback;

	G_UNLOCK (gperl_log_default_handler_callback);

	RETVAL = &PL_sv_undef;
	if (old_func == g_log_default_handler) {
		CV *cv = get_cv ("Glib::Log::default_handler", 0);
		assert (cv);
		RETVAL = newRV_inc ((SV*) cv);
		SvREFCNT_inc (RETVAL);
	} else if (old_func == gperl_log_func) {
		RETVAL = old_callback->func;
		SvREFCNT_inc (RETVAL);
	}
	if (old_callback) {
		gperl_callback_destroy (old_callback);
	}
    OUTPUT:
	RETVAL

#endif

# this is a little ugly, because i didn't want to export a typemap for
# GLogLevelFlags.

MODULE = Glib::Log	PACKAGE = Glib	PREFIX = g_

=for object Glib::Log
=cut

void g_log (class, gchar_ornull * log_domain, SV * log_level, const gchar *message)
    CODE:
	g_log (log_domain, SvGLogLevelFlags (log_level), "%s", message);

MODULE = Glib::Log	PACKAGE = Glib::Log	PREFIX = g_log_

SV * g_log_set_fatal_mask (class, const gchar *log_domain, SV * fatal_mask);
    CODE:
	RETVAL = newSVGLogLevelFlags 
		(g_log_set_fatal_mask (log_domain,
		                       SvGLogLevelFlags (fatal_mask)));
    OUTPUT:
	RETVAL

SV * g_log_set_always_fatal (class, SV * fatal_mask);
    CODE:
	RETVAL = newSVGLogLevelFlags 
		(g_log_set_always_fatal (SvGLogLevelFlags (fatal_mask)));
    OUTPUT:
	RETVAL


##
## there are, indeed, some incidences in which it would be handy to have
## perl hooks into the g_log mechanism
##

##ifndef G_LOG_DOMAIN
##define G_LOG_DOMAIN    ((gchar*) 0)
##endif  /* G_LOG_DOMAIN */

MODULE = Glib::Log	PACKAGE = Glib

=for object Glib::Log
=cut

###
### these are of dubious value, but i imagine that they could be useful...
###
##define g_error(...)    g_log (G_LOG_DOMAIN, G_LOG_LEVEL_ERROR, __VA_ARGS__)
##define g_message(...)  g_log (G_LOG_DOMAIN, G_LOG_LEVEL_MESSAGE, __VA_ARGS__)
##define g_critical(...) g_log (G_LOG_DOMAIN, G_LOG_LEVEL_CRITICAL, __VA_ARGS__)
##define g_warning(...)  g_log (G_LOG_DOMAIN, G_LOG_LEVEL_WARNING, __VA_ARGS__)
##define g_info(...)     g_log (G_LOG_DOMAIN, G_LOG_LEVEL_INFO, __VA_ARGS__)
##define g_debug(...)    g_log (G_LOG_DOMAIN, G_LOG_LEVEL_DEBUG, __VA_ARGS__)
void
error (class, gchar_ornull * domain, const gchar * message)
    ALIAS:
        error = 0
        critical = 1
        warning = 2
        message = 3
        info = 4
        debug = 5
    PREINIT:
	GLogLevelFlags flags = G_LOG_LEVEL_MESSAGE;
    CODE:
	switch (ix) {
                case 0: flags = G_LOG_LEVEL_ERROR; break;
                case 1: flags = G_LOG_LEVEL_CRITICAL; break;
                case 2: flags = G_LOG_LEVEL_WARNING; break;
                case 3: flags = G_LOG_LEVEL_MESSAGE; break;
                case 4: flags = G_LOG_LEVEL_INFO; break;
                case 5: flags = G_LOG_LEVEL_DEBUG; break;
	}
	g_log (domain, flags, "%s", message);

##
## these are not needed -- perl's print() and warn() do the job.
##
## typedef void (*GPrintFunc) (const gchar *string);
## void g_print (const gchar *format, ...) G_GNUC_PRINTF (1, 2);
## GPrintFunc g_set_print_handler (GPrintFunc func);
## void g_printerr (const gchar *format, ...) G_GNUC_PRINTF (1, 2);
## GPrintFunc g_set_printerr_handler (GPrintFunc func);
##

##
## the assertion and return macros aren't really useful at all in perl;
## there are native perl replacements for them on CPAN.
##
##define g_assert(expr)
##define g_assert_not_reached()
##define g_return_if_fail(expr)
##define g_return_val_if_fail(expr,val)
##define g_return_if_reached()
##define g_return_val_if_reached(val)

