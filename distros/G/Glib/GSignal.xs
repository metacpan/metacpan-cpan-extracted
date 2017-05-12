/*
 * Copyright (C) 2003-2004, 2009, 2012-2013 by the gtk2-perl team (see the
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

=head2 GSignal

=over

=cut

/* #define NOISY */

#include "gperl.h"
#include "gperl-gtypes.h"
#include "gperl-private.h" /* for SAVED_STACK_SV */

/*
 * here's a nice G_LOCK-like front-end to GStaticRecMutex.  we need this 
 * to keep other threads from fiddling with the closures list while we're
 * modifying it.
 */
#ifdef G_THREADS_ENABLED
# if GLIB_CHECK_VERSION (2, 32, 0)
#  define GPERL_REC_LOCK_DEFINE_STATIC(name)    static GPERL_REC_LOCK_DEFINE (name)
#  define GPERL_REC_LOCK_DEFINE(name)           GRecMutex G_LOCK_NAME (name)
#  define GPERL_REC_LOCK(name)                  g_rec_mutex_lock (&G_LOCK_NAME (name))
#  define GPERL_REC_UNLOCK(name)                g_rec_mutex_unlock (&G_LOCK_NAME (name))
# else
#  define GPERL_REC_LOCK_DEFINE_STATIC(name)	\
	GStaticRecMutex G_LOCK_NAME (name) = G_STATIC_REC_MUTEX_INIT
#  define GPERL_REC_LOCK(name)	\
	g_static_rec_mutex_lock (&G_LOCK_NAME (name))
#  define GPERL_REC_UNLOCK(name)	\
	g_static_rec_mutex_unlock (&G_LOCK_NAME (name))
# endif
#else
# define GPERL_REC_LOCK_DEFINE_STATIC(name) extern void glib_dummy_decl (void)
# define GPERL_REC_LOCK(name)
# define GPERL_REC_UNLOCK(name)
#endif


SV *
newSVGSignalFlags (GSignalFlags flags)
{
	return gperl_convert_back_flags (GPERL_TYPE_SIGNAL_FLAGS, flags);
}

GSignalFlags
SvGSignalFlags (SV * sv)
{
	return gperl_convert_flags (GPERL_TYPE_SIGNAL_FLAGS, sv);
}


SV *
newSVGSignalInvocationHint (GSignalInvocationHint * ihint)
{
	HV * hv = newHV ();
	gperl_hv_take_sv_s (hv, "signal_name",
	                    newSVGChar (g_signal_name (ihint->signal_id)));
	gperl_hv_take_sv_s (hv, "detail",
	                    newSVGChar (g_quark_to_string (ihint->detail)));
	gperl_hv_take_sv_s (hv, "run_type",
	                    newSVGSignalFlags (ihint->run_type));
	return newRV_noinc ((SV*)hv);
}


#define GET_NAME(name, gtype)				\
	(name) = gperl_package_from_type (gtype);	\
	if (!(name))					\
		(name) = g_type_name (gtype);
SV *
newSVGSignalQuery (GSignalQuery * query)
{
	HV * hv;
	AV * av;
	guint j;
	const char * pkgname;

	if (!query)
		return &PL_sv_undef;

	hv = newHV ();
	gperl_hv_take_sv_s (hv, "signal_id", newSViv (query->signal_id));
	gperl_hv_take_sv_s (hv, "signal_name",
	                    newSVpv (query->signal_name, 0));
	GET_NAME (pkgname, query->itype);
	if (pkgname)
		gperl_hv_take_sv_s (hv, "itype", newSVpv (pkgname, 0));
	gperl_hv_take_sv_s (hv, "signal_flags",
	                    newSVGSignalFlags (query->signal_flags));
	if (query->return_type != G_TYPE_NONE) {
		GType t = query->return_type & ~G_SIGNAL_TYPE_STATIC_SCOPE;
		GET_NAME (pkgname, t);
		if (pkgname)
			gperl_hv_take_sv_s (hv, "return_type",
			                    newSVpv (pkgname, 0));
	}
	av = newAV ();
	for (j = 0; j < query->n_params; j++) {
		GType t = query->param_types[j] & ~G_SIGNAL_TYPE_STATIC_SCOPE;
		GET_NAME (pkgname, t);
		av_push (av, newSVpv (pkgname, 0));
	}
	gperl_hv_take_sv_s (hv, "param_types", newRV_noinc ((SV*)av));
	/* n_params is inferred by the length of the av in param_types */

	return newRV_noinc ((SV*)hv);
}
#undef GET_NAME


/*
now back to our regularly-scheduled bindings.
*/

static GSList * closures = NULL;
GPERL_REC_LOCK_DEFINE_STATIC (closures);

static void
forget_closure (SV * callback,
                GPerlClosure * closure)
{
#ifdef NOISY
	warn ("forget_closure %p / %p", callback, closure);
#else
	PERL_UNUSED_VAR (callback);
#endif
	
	GPERL_REC_LOCK (closures);
	closures = g_slist_remove (closures, closure);
	GPERL_REC_UNLOCK (closures);
}

static void
remember_closure (GPerlClosure * closure)
{
#ifdef NOISY
	warn ("remember_closure %p / %p", closure->callback, closure);
	warn ("   callback %s\n", SvPV_nolen (closure->callback));
#endif
	GPERL_REC_LOCK (closures);
	closures = g_slist_prepend (closures, closure);
	GPERL_REC_UNLOCK (closures);
	g_closure_add_invalidate_notifier ((GClosure *) closure,
	                                   closure->callback,
	                                   (GClosureNotify) forget_closure);
}

=item void gperl_signal_set_marshaller_for (GType instance_type, char * detailed_signal, GClosureMarshal marshaller)

You need this function only in rare cases, usually as workarounds for bad
signal parameter types or to implement writable arguments.  Use the given
I<marshaller> to marshal all handlers for I<detailed_signal> on
I<instance_type>.  C<gperl_signal_connect> will look for marshallers
registered here, and apply them to the GPerlClosure it creates for the given
callback being connected.

A canonical form of I<detailed_signal> will be used so that I<marshaller> is
applied for all possible spellings of the signal name.

Use the helper macros in gperl_marshal.h to help write your marshaller
function.  That header, which is installed with the Glib module but not
#included through gperl.h, includes commentary and examples which you
should follow closely to avoid nasty bugs.  Use the Source, Luke.

WARNING: Bend over backwards and turn your head around 720 degrees before
attempting to write a GPerlClosure marshaller without using the macros in
gperl_marshal.h.  If you absolutely cannot use those macros, be certain to
understand what those macros do so you can get the semantics correct, and
keep your code synchronized with them, or you may miss very important
bugfixes.

=cut

/* We need to store the custom marshallers indexed by (type, signal) tuples
 * since signal names are not unique (GtkDialog and GtkInfoBar both have a
 * "response" signal, for example). */
static GHashTable * marshallers_by_type = NULL;
G_LOCK_DEFINE_STATIC (marshallers_by_type);

/* gobject treats hyphens and underscores in signal names as equivalent.  We
 * thus need to do this as well to ensure that a custom marshaller is used for
 * all spellings of a signal name. */
static char *
canonicalize_signal_name (char * signal_name)
{
	return g_strdelimit (signal_name, "_", '-');
}

void
gperl_signal_set_marshaller_for (GType instance_type,
                                 char * detailed_signal,
                                 GClosureMarshal marshaller)
{
	g_return_if_fail (instance_type != 0);
	g_return_if_fail (detailed_signal != NULL);
	G_LOCK (marshallers_by_type);
	if (!marshaller && !marshallers_by_type) {
		/* nothing to do */
	} else {
		GHashTable *marshallers_by_signal;
		char *canonical_detailed_signal;
		if (!marshallers_by_type)
			marshallers_by_type =
				g_hash_table_new_full (g_direct_hash,
				                       g_direct_equal,
				                       NULL,
				                       (GDestroyNotify)
				                         g_hash_table_destroy);
		marshallers_by_signal = g_hash_table_lookup (
		                          marshallers_by_type,
		                          (gpointer) instance_type);
		if (!marshallers_by_signal) {
			marshallers_by_signal = g_hash_table_new_full (
			                          g_str_hash,
			                          g_str_equal,
			                          g_free,
			                          NULL);
			g_hash_table_insert (marshallers_by_type,
			                     (gpointer) instance_type,
			                     marshallers_by_signal);
		}
		canonical_detailed_signal = canonicalize_signal_name (
			g_strdup (detailed_signal));
		if (marshaller) {
			g_hash_table_insert
					(marshallers_by_signal,
					 canonical_detailed_signal,
					 marshaller);
		} else {
			g_hash_table_remove (marshallers_by_signal,
			                     canonical_detailed_signal);
			g_free (canonical_detailed_signal);
		}
	}
	G_UNLOCK (marshallers_by_type);
}

/* Called with lock on marshallers_by_type held. */
static GClosureMarshal
lookup_specific_marshaller (GType specific_type,
                            char * detailed_signal)
{
	GHashTable *marshallers_by_signal =
		g_hash_table_lookup (marshallers_by_type,
		                     (gpointer) specific_type);
	if (marshallers_by_signal) {
		char *canonical_detailed_signal;
		GClosureMarshal marshaller;
		canonical_detailed_signal = canonicalize_signal_name (
			g_strdup (detailed_signal));
		marshaller = g_hash_table_lookup (marshallers_by_signal,
		                                  canonical_detailed_signal);
		g_free (canonical_detailed_signal);
		return marshaller;
	}
	return NULL;
}

static GClosureMarshal
lookup_marshaller (GType instance_type,
                   char * detailed_signal)
{
	GClosureMarshal marshaller = NULL;
	G_LOCK (marshallers_by_type);
	if (marshallers_by_type) {
		GType type = instance_type;
		/* We need to walk the ancestry to make sure that, say,
		 * GtkFileChooseDialog also gets the custom "response"
		 * marshaller from GtkDialog.  This always terminates because
		 * g_type_parent (G_TYPE_OBJECT) == 0. */
		while (marshaller == NULL && type != 0) {
			marshaller = lookup_specific_marshaller (
			               type, detailed_signal);
			type = g_type_parent (type);
		}
		/* We also need to look at interfaces. */
		if (marshaller == NULL) {
			GType *interface_types =
				g_type_interfaces (instance_type, NULL);
			GType *interface = interface_types;
			/* interface_types is 0-terminated. */
			while (marshaller == NULL && *interface != 0) {
				marshaller = lookup_specific_marshaller (
			                       *interface, detailed_signal);
				interface++;
			}
		}
	}
	G_UNLOCK (marshallers_by_type);
	return marshaller;
}

=item gulong gperl_signal_connect (SV * instance, char * detailed_signal, SV * callback, SV * data, GConnectFlags flags)

The actual workhorse behind GObject::signal_connect, the binding for
g_signal_connect, for use from within XS.  This creates a C<GPerlClosure>
wrapper for the given I<callback> and I<data>, and connects that closure to the
signal named I<detailed_signal> on the given GObject I<instance>.  This is only
good for named signals.  I<flags> is the same as for g_signal_connect().
I<data> may be NULL, but I<callback> must not be.

Returns the id of the installed callback.

=cut
gulong
gperl_signal_connect (SV * instance,
                      char * detailed_signal,
                      SV * callback, SV * data,
                      GConnectFlags flags)
{
	GObject * object;
	GPerlClosure * closure;
	GClosureMarshal marshaller = NULL;
	gulong id;

	object = gperl_get_object (instance);
	marshaller = lookup_marshaller (G_OBJECT_TYPE (object), detailed_signal);
	closure = (GPerlClosure *)
			gperl_closure_new_with_marshaller
			                     (callback, data,
			                      flags & G_CONNECT_SWAPPED,
			                      marshaller);

	/* after is true only if we're called as signal_connect_after */
	id =	g_signal_connect_closure (object,
		                          detailed_signal,
		                          (GClosure*) closure, 
		                          flags & G_CONNECT_AFTER);

	if (id > 0) {
		closure->id = id;
		remember_closure (closure);
	} else {
		/* not connected, usually bad detailed_signal name */
		g_closure_unref ((GClosure*) closure);
	}
	return id;
}

/*
G_SIGNAL_MATCH_ID        The signal id must be equal.
G_SIGNAL_MATCH_DETAIL    The signal detail be equal.
G_SIGNAL_MATCH_CLOSURE   The closure must be the same.
G_SIGNAL_MATCH_FUNC      The C closure callback must be the same.
G_SIGNAL_MATCH_DATA      The closure data must be the same.
G_SIGNAL_MATCH_UNBLOCKED Only unblocked signals may matched.

at the perl level, the CV replaces both the FUNC and CLOSURE.  it's rare
people will specify any of the others than FUNC and DATA, but i can see
how they would be useful so let's support them.
*/
typedef guint (*sig_match_callback) (gpointer           instance,
                                     GSignalMatchType   mask,
                                     guint              signal_id,
                                     GQuark             detail,
                                     GClosure         * closure,
                                     gpointer           func,
                                     gpointer           data);

static guint
foreach_closure_matched (gpointer instance,
                         GSignalMatchType mask,
                         guint signal_id,
                         GQuark detail,
                         SV * func,
                         SV * data,
                         sig_match_callback callback)
{
	guint n = 0;
	GSList * i;

	if (mask & G_SIGNAL_MATCH_CLOSURE || /* this isn't too likely */
	    mask & G_SIGNAL_MATCH_FUNC ||
	    mask & G_SIGNAL_MATCH_DATA) {
		/*
		 * to match against a function or data, we need to find the
		 * scalars for those in the GPerlClosures; we'll have to
		 * proxy this stuff.  we'll replace the func and data bits
		 * with closure in the mask.
		 *    however, we can't do the match for any of the other
		 * flags at this level, so even though our design means one
		 * closure per handler id, we still have to pass that closure
		 * on to the real C functions to do any other filtering for
		 * us.
		 */
		/* we'll compare SVs by their stringified values.  cache the
		 * stringified needles, but there's no way to cache the
		 * haystack. */
		const char * str_func = func ? SvPV_nolen (func) : NULL;
		const char * str_data = data ? SvPV_nolen (data) : NULL;

		mask &= ~(G_SIGNAL_MATCH_FUNC | G_SIGNAL_MATCH_DATA);
		mask |= G_SIGNAL_MATCH_CLOSURE;

		/* this is a little hairy because the callback may disconnect
		 * a closure, which would modify the list while we're iterating
		 * over it. */
		GPERL_REC_LOCK (closures);
		i = closures;
		while (i != NULL) {
			GPerlClosure * c = (GPerlClosure*) i->data;
			i = i->next;
			if ((!func || strEQ (str_func, SvPV_nolen (c->callback))) &&
			    (!data || strEQ (str_data, SvPV_nolen (c->data)))) {
				n += callback (instance, mask, signal_id,
				               detail, (GClosure*)c,
				               NULL, NULL);
			}
		}
		GPERL_REC_UNLOCK (closures);
	} else {
		/* we're not matching against a closure, so we can just
		 * pass this on through. */
		n = callback (instance, mask, signal_id, detail,
		              NULL, NULL, NULL);
	}
	return n;
}


static GType
get_gtype_or_croak (SV * object_or_class_name)
{
	GType gtype;

	if (gperl_sv_is_ref (object_or_class_name)) {
		GObject * object = SvGObject (object_or_class_name);
		if (!object)
			croak ("bad object in signal_query");
		gtype = G_OBJECT_TYPE (object);
	} else {
		gtype = gperl_object_type_from_package
					(SvPV_nolen (object_or_class_name));
		if (!gtype)
			croak ("package %s is not registered with GPerl",
			       SvPV_nolen (object_or_class_name));
	}
	
	return gtype;
}

static guint
parse_signal_name_or_croak (const char * detailed_name,
			    GType instance_type,
			    GQuark * detail) /* return, NULL if not wanted */
{
	guint signal_id;
	if (!g_signal_parse_name (detailed_name, instance_type, &signal_id,
				  detail, TRUE))
		croak ("Unknown signal %s for object of type %s", 
			detailed_name, g_type_name (instance_type));
	return signal_id;
}

static GPerlCallback *
gperl_signal_emission_hook_create (SV * func,
				   SV * data)
{
	GType param_types[2];
	param_types[0] = GPERL_TYPE_SV;
	param_types[1] = GPERL_TYPE_SV;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_BOOLEAN);
}

static gboolean
gperl_signal_emission_hook (GSignalInvocationHint * ihint,
			    guint n_param_values,
			    const GValue * param_values,
			    gpointer data)
{
	GPerlCallback * callback = (GPerlCallback *) data;
	gboolean retval;
	AV * av;
	guint i;
	GValue return_value = {0, };
	g_value_init (&return_value, G_TYPE_BOOLEAN);
	av = newAV();
	for (i = 0 ; i < n_param_values ; i++)
		av_push (av, sv_2mortal (gperl_sv_from_value (param_values+i)));
	gperl_callback_invoke (callback, &return_value,
			       newSVGSignalInvocationHint (ihint),
			       newRV_noinc ((SV*) av));
	retval = g_value_get_boolean (&return_value);
	g_value_unset (&return_value);
	return retval;
}


=back

=cut


MODULE = Glib::Signal	PACKAGE = Glib::Signal

=for position DESCRIPTION

=head1 DESCRIPTION

This page describes some functions related to signals in Glib.  Since most
things you can do with signals are tied to L<Glib::Object> instances, the
majority of the signal functions are documented there.

=head2 Thread safety

Some libraries, most notably GStreamer, sometimes invoke signal handlers from a
foreign thread that has no Perl interpreter associated with it.  When this
happens, we have no choice but to hand the marshalling over to the main loop
which in turn later wakes up the main thread and lets it handle the request.
We cannot invoke the signal handler from the foreign thread since the Perl
interpreter may not be used concurrently.

The downside to this approach is that the foreign thread is blocked until the
main thread has finished executing the signal handler.  This might lead to
deadlocks.  It might help in this case to wrap the crucial parts of the signal
handler inside a L<Glib::Idle> callback so that the signal handler can return
directly.

=cut

=for see_also Glib::Object

=cut

BOOT:
	gperl_register_fundamental (GPERL_TYPE_SIGNAL_FLAGS,
	                            "Glib::SignalFlags");
	gperl_register_fundamental (GPERL_TYPE_CONNECT_FLAGS,
	                            "Glib::ConnectFlags");

=for flags Glib::SignalFlags

=cut


MODULE = Glib::Signal	PACKAGE = Glib::Object	PREFIX = g_

##
##/* --- typedefs --- */
##typedef struct _GSignalQuery		 GSignalQuery;
##typedef struct _GSignalInvocationHint	 GSignalInvocationHint;
##typedef GClosureMarshal			 GSignalCMarshaller;
##typedef gboolean (*GSignalEmissionHook) (GSignalInvocationHint *ihint,
##					 guint			n_param_values,
##					 const GValue	       *param_values,
##					 gpointer		data);
##typedef gboolean (*GSignalAccumulator)	(GSignalInvocationHint *ihint,
##					 GValue		       *return_accu,
##					 const GValue	       *handler_return,
##					 gpointer               data);


###
### ## creating signals ##
### new signals are currently created as a byproduct of Glib::Type::register
###
##        g_signal_newv
##        g_signal_new_valist
##        g_signal_new

###
### ## emitting signals ##
### all versions of g_signal_emit go through Glib::Object::signal_emit,
### which is mostly equivalent to g_signal_emit_by_name.
###
##        g_signal_emitv
##        g_signal_emit_valist
##        g_signal_emit
##        g_signal_emit_by_name

## heavily borrowed from gtk-perl and goran's code in gtk2-perl, which
## was inspired by pygtk's pyobject.c::pygobject_emit

=for apidoc

=for signature retval = $object->signal_emit ($name, ...)

=for arg name (string) the name of the signal

=for arg ... (list) any arguments to pass to handlers.

Emit the signal I<name> on I<$object>.  The number and types of additional
arguments in I<...> are determined by the signal; similarly, the presence
and type of return value depends on the signal being emitted.

=cut
void
g_signal_emit (instance, name, ...)
	GObject * instance
	char * name
    PREINIT:
	guint signal_id, i;
	GQuark detail;
	GSignalQuery query;
	GValue * params;
    PPCODE:
#define ARGOFFSET 2
	signal_id = parse_signal_name_or_croak
				(name, G_OBJECT_TYPE (instance), &detail);

	g_signal_query (signal_id, &query);

	if (((guint)(items-ARGOFFSET)) != query.n_params) 
		croak ("Incorrect number of arguments for emission of signal %s in class %s; need %d but got %d",
		       name, G_OBJECT_TYPE_NAME (instance),
		       query.n_params, (gint) items-ARGOFFSET);

	/* set up the parameters to g_signal_emitv.   this is an array
	 * of GValues, where [0] is the emission instance, and the rest 
	 * are the query.n_params arguments. */
	params = g_new0 (GValue, query.n_params + 1);

	g_value_init (&params[0], G_OBJECT_TYPE (instance));
	g_value_set_object (&params[0], instance);

	for (i = 0 ; i < query.n_params ; i++) {
		g_value_init (&params[i+1], 
			      query.param_types[i] & ~G_SIGNAL_TYPE_STATIC_SCOPE);
		if (!gperl_value_from_sv (&params[i+1], ST (ARGOFFSET+i)))
			croak ("Couldn't convert value %s to type %s for parameter %d of signal %s on a %s",
			       SvPV_nolen (ST (ARGOFFSET+i)),
			       g_type_name (G_VALUE_TYPE (&params[i+1])),
			       i, name, G_OBJECT_TYPE_NAME (instance));
	}

	/* now actually call it.  what we do depends on the return type of
	 * the signal; if the signal returns anything we need to capture it
	 * and push it onto the return stack. */
	if (query.return_type != G_TYPE_NONE) {
		/* signal returns a value, woohoo! */
		GValue ret = {0,};
		g_value_init (&ret, query.return_type);
		g_signal_emitv (params, signal_id, detail, &ret);
		EXTEND (SP, 1);
		SAVED_STACK_PUSHs (sv_2mortal (gperl_sv_from_value (&ret)));
		g_value_unset (&ret);
	} else {
		g_signal_emitv (params, signal_id, detail, NULL);
	}

	/* clean up */
	for (i = 0 ; i < query.n_params + 1 ; i++)
		g_value_unset (&params[i]);
	g_free (params);
#undef ARGOFFSET


##guint                 g_signal_lookup       (const gchar        *name,
##					     GType               itype);
##G_CONST_RETURN gchar* g_signal_name         (guint               signal_id);

##void g_signal_query (guint signal_id, GSignalQuery *query);
=for apidoc
Look up information about the signal I<$name> on the instance type
I<$object_or_class_name>, which may be either a Glib::Object or a package
name.

See also C<Glib::Type::list_signals>, which returns the same kind of
hash refs as this does.

Since 1.080.
=cut
SV *
g_signal_query (SV * object_or_class_name, const char * name)
    PREINIT:
	GType itype;
	guint signal_id;
	GSignalQuery query;
	GObjectClass * oclass = NULL;
    CODE:
	itype = get_gtype_or_croak (object_or_class_name);
	if (G_TYPE_IS_CLASSED (itype)) {
		/* ref the class to ensure that the signals get created,
		 * otherwise they may not exist at the time we query. */
		oclass = g_type_class_ref (itype);
		if (!oclass)
			croak ("couldn't ref type %s", g_type_name (itype));
	}
	signal_id = g_signal_lookup (name, itype);
	if (0 == signal_id) {
		RETVAL = &PL_sv_undef;
	} else {
		g_signal_query (signal_id, &query);
		RETVAL = newSVGSignalQuery (&query);
	}
	if (oclass)
		g_type_class_unref (oclass);
    OUTPUT:
	RETVAL

##guint*                g_signal_list_ids     (GType               itype,
##					     guint              *n_ids);
##gboolean	      g_signal_parse_name   (const gchar	*detailed_signal,
##					     GType		 itype,
##					     guint		*signal_id_p,
##					     GQuark		*detail_p,
##					     gboolean		 force_detail_quark);

##GSignalInvocationHint* g_signal_get_invocation_hint (gpointer    instance);
=for apidoc
=for signature $ihint = $instance->signal_get_invocation_hint
Get a reference to a hash describing the innermost signal currently active
on C<$instance>.  Returns undef if no signal emission is active.  This
invocation hint is the same object passed to signal emission hooks, and
contains these keys:

=over

=item signal_name

The name of the signal being emitted.

=item detail

The detail passed on for this emission.  For example, a C<notify> signal will
have the property name as the detail.

=item run_type

The current stage of signal emission, one of "run-first", "run-last", or
"run-cleanup".

=back

=cut
SV*
g_signal_get_invocation_hint (GObject *instance)
    PREINIT:
        GSignalInvocationHint *ihint;
    CODE:
        ihint = g_signal_get_invocation_hint (instance);
        RETVAL = ihint ? newSVGSignalInvocationHint (ihint) : &PL_sv_undef;
    OUTPUT:
        RETVAL


##/* --- signal emissions --- */
##void	g_signal_stop_emission		    (gpointer		  instance,
##					     guint		  signal_id,
##					     GQuark		  detail);
##void	g_signal_stop_emission_by_name	    (gpointer		  instance,
##					     const gchar	 *detailed_signal);
void g_signal_stop_emission_by_name (GObject * instance, const gchar * detailed_signal);

##gulong	g_signal_add_emission_hook	    (guint		  signal_id,
##					     GQuark		  quark,
##					     GSignalEmissionHook  hook_func,
##					     gpointer	       	  hook_data,
##					     GDestroyNotify	  data_destroy);
=for apidoc
=for arg detailed_signal (string) of the form "signal-name::detail"
=for arg hook_func (subroutine)
Add an emission hook for a signal.  The hook will be called for any emission
of that signal, independent of the instance.  This is possible only for
signals which don't have the C<G_SIGNAL_NO_HOOKS> flag set.

The I<$hook_func> should be reference to a subroutine that looks something
like this:

  sub emission_hook {
      my ($invocation_hint, $parameters, $hook_data) = @_;
      # $parameters is a reference to the @_ to be passed to
      # signal handlers, including the instance as $parameters->[0].
      return $stay_connected;  # boolean
  }

This function returns an id that can be used with C<remove_emission_hook>.

Since 1.100.
=cut
gulong
g_signal_add_emission_hook (object_or_class_name, detailed_signal, hook_func, hook_data=NULL)
	SV * object_or_class_name
	const char * detailed_signal
	SV * hook_func
	SV * hook_data
    PREINIT:
	GType           itype;
	GObjectClass *  object_class;
	guint           signal_id;
	GQuark          quark;
	GPerlCallback * callback;
    CODE:
	itype = get_gtype_or_croak (object_or_class_name);

	/* See the xsub for g_object_find_property in GObject.xs for why the
	 * class ref/unref stunt is necessary. */
	object_class = g_type_class_ref (itype);

	signal_id = parse_signal_name_or_croak (detailed_signal, itype, &quark);
	callback = gperl_signal_emission_hook_create (hook_func, hook_data);
	RETVAL = g_signal_add_emission_hook
			(signal_id, quark, gperl_signal_emission_hook,
			 callback, (GDestroyNotify)gperl_callback_destroy);

	g_type_class_unref (object_class);
    OUTPUT:
	RETVAL

##void	g_signal_remove_emission_hook	    (guint		  signal_id,
##					     gulong		  hook_id);
=for apidoc
Remove a hook that was installed by C<add_emission_hook>.

Since 1.100.
=cut
void
g_signal_remove_emission_hook (SV * object_or_class_name, const char * signal_name, gulong hook_id);
    PREINIT:
	guint signal_id;
	GType gtype;
    CODE:
	gtype = get_gtype_or_croak (object_or_class_name);
	signal_id = parse_signal_name_or_croak (signal_name, gtype, NULL);
	g_signal_remove_emission_hook (signal_id, hook_id);

##
##
##/* --- signal handlers --- */
##gboolean g_signal_has_handler_pending	      (gpointer		  instance,
##					       guint		  signal_id,
##					       GQuark		  detail,
##					       gboolean		  may_be_blocked);

###
### ## connecting signals ##
### currently all versions of signal_connect go through
### Glib::Object::signal_connect, which acts like the g_signal_connect
### convenience function.
###
##gulong g_signal_connect_closure_by_id	      (gpointer		  instance,
##					       guint		  signal_id,
##					       GQuark		  detail,
##					       GClosure		 *closure,
##					       gboolean		  after);
##gulong g_signal_connect_closure	      (gpointer		  instance,
##					       const gchar       *detailed_signal,
##					       GClosure		 *closure,
##					       gboolean		  after);
##gulong g_signal_connect_data		      (gpointer		  instance,
##					       const gchar	 *detailed_signal,
##					       GCallback	  c_handler,
##					       gpointer		  data,
##					       GClosureNotify	  destroy_data,
##					       GConnectFlags	  connect_flags);

=for apidoc Glib::Object::signal_connect

=for arg callback (subroutine) 

=for arg data (scalar) arbitrary data to be passed to each invocation of I<callback>

Register I<callback> to be called on each emission of I<$detailed_signal>.
Returns an identifier that may be used to remove this handler with
C<< $object->signal_handler_disconnect >>.

=cut

=for apidoc Glib::Object::signal_connect_after

Like C<signal_connect>, except that I<$callback> will be run after the default
handler.

=cut

=for apidoc Glib::Object::signal_connect_swapped

Like C<signal_connect>, except that I<$data> and I<$object> will be swapped
on invocation of I<$callback>.

=cut

gulong
g_signal_connect (instance, detailed_signal, callback, data=NULL)
	SV * instance
	char * detailed_signal
	SV * callback
	SV * data
    ALIAS:
	Glib::Object::signal_connect = 0
	Glib::Object::signal_connect_after = 1
	Glib::Object::signal_connect_swapped = 2
    PREINIT:
	GConnectFlags flags = 0;
    CODE:
	if (ix == 1) flags |= G_CONNECT_AFTER;
	if (ix == 2) flags |= G_CONNECT_SWAPPED;
	RETVAL = gperl_signal_connect (instance, detailed_signal,
	                               callback, data, flags);
    OUTPUT:
	RETVAL


void
g_signal_handler_block (object, handler_id)
	GObject * object
	gulong handler_id

void
g_signal_handler_unblock (object, handler_id)
	GObject * object
	gulong handler_id

void
g_signal_handler_disconnect (object, handler_id)
	GObject * object
	gulong handler_id

gboolean
g_signal_handler_is_connected (object, handler_id)
	GObject * object
	gulong handler_id

 ##
 ## this would require a fair bit of the magic used in the *_by_func
 ## wrapper below...
 ##
##gulong   g_signal_handler_find              (gpointer          instance,
##                                             GSignalMatchType  mask,
##                                             guint             signal_id,
##                                             GQuark            detail,
##                                             GClosure         *closure,
##                                             gpointer          func,
##                                             gpointer          data);

 ###
 ### the *_matched functions all have the same signature and thus all 
 ### are handled by matched().
 ###

 ##  g_signal_handlers_block_matched
 ##  g_signal_handlers_unblock_matched
 ##  g_signal_handlers_disconnect_matched

 ##### FIXME oops, no typemap for GSignalMatchType...
##guint
##matched (instance, mask, signal_id, detail, func, data)
##	SV * instance
##	GSignalMatchType mask
##	guint signal_id
##	SV * detail
##	SV * func
##	SV * data
##    ALIAS:
##	Glib::Object::signal_handlers_block_matched = 0
##	Glib::Object::signal_handlers_unblock_matched = 1
##	Glib::Object::signal_handlers_disconnect_matched = 2
##    PREINIT:
##	sig_match_callback callback = NULL;
##	GQuark real_detail = 0;
##    CODE:
##	switch (ix) {
##	    case 0: callback = g_signal_handlers_block_matched; break;
##	    case 1: callback = g_signal_handlers_unblock_matched; break;
##	    case 2: callback = g_signal_handlers_disconnect_matched; break;
##	}
##	if (!callback)
##		croak ("internal problem -- xsub aliased to invalid ix");
##	if (detail && SvPOK (detail)) {
##		real_detail = g_quark_try_string (SvPV_nolen (detail));
##		if (!real_detail)
##			croak ("no such detail %s", SvPV_nolen (detail));
##	}
##	RETVAL = foreach_closure_matched (gperl_get_object (instance),
##	                                  mask, signal_id, real_detail,
##	                                  func, data);
##    OUTPUT:
##	RETVAL

 ### the *_by_func functions all have the same signature, and thus are
 ### handled by signal_handlers_block_by_func.

 ## g_signal_handlers_disconnect_by_func(instance, func, data)
 ## g_signal_handlers_block_by_func(instance, func, data)
 ## g_signal_handlers_unblock_by_func(instance, func, data)

=for apidoc Glib::Object::signal_handlers_unblock_by_func
=for arg func (subroutine) function to block
=for arg data (scalar) data to match, ignored if undef
=cut

=for apidoc Glib::Object::signal_handlers_disconnect_by_func
=for arg func (subroutine) function to block
=for arg data (scalar) data to match, ignored if undef
=cut

=for apidoc
=for arg func (subroutine) function to block
=for arg data (scalar) data to match, ignored if undef
=cut
int
signal_handlers_block_by_func (instance, func, data=NULL)
	GObject * instance
	SV * func
	SV * data
    ALIAS:
	Glib::Object::signal_handlers_unblock_by_func = 1
	Glib::Object::signal_handlers_disconnect_by_func = 2
    PREINIT:
	sig_match_callback callback = NULL;
    CODE:
	switch (ix) {
	    case 0: callback = g_signal_handlers_block_matched; break;
	    case 1: callback = g_signal_handlers_unblock_matched; break;
	    case 2: callback = g_signal_handlers_disconnect_matched; break;
	    default: g_assert_not_reached ();
	}
	RETVAL = foreach_closure_matched (instance, G_SIGNAL_MATCH_CLOSURE,
	                                  0, 0, func, data, callback);
    OUTPUT:
	RETVAL




##/* --- chaining for language bindings --- */
##void	g_signal_override_class_closure	      (guint		  signal_id,
##					       GType		  instance_type,
##					       GClosure		 *class_closure);
##void	g_signal_chain_from_overridden	      (const GValue      *instance_and_params,
##					       GValue            *return_value);
=for apidoc

Chain up to an overridden class closure; it is only valid to call this from
a class closure override.

Translation: because of various details in how GObjects are implemented,
the way to override a virtual method on a GObject is to provide a new "class
closure", or default handler for a signal.  This happens when a class is
registered with the type system (see Glib::Type::register and
L<Glib::Object::Subclass>).  When called from inside such an override, this
method runs the overridden class closure.  This is equivalent to calling
$self->SUPER::$method (@_) in normal Perl objects.

=cut
void
g_signal_chain_from_overridden (GObject * instance, ...)
    PREINIT:
	GSignalInvocationHint * ihint;
	GSignalQuery query;
	GValue * instance_and_params = NULL,
	         return_value = {0,};
	guint i;
    PPCODE:

	ihint = g_signal_get_invocation_hint (instance);
	if (!ihint)
		croak ("could not find signal invocation hint for %s(0x%p)",
		       G_OBJECT_TYPE_NAME (instance), instance);

	g_signal_query (ihint->signal_id, &query);

	if ((guint)items != 1 + query.n_params)
		croak ("incorrect number of parameters for signal %s, "
		       "expected %d, got %d",
		       g_signal_name (ihint->signal_id),
		       1 + query.n_params,
		       (gint) items);

	instance_and_params = g_new0 (GValue, 1 + query.n_params);

	g_value_init (&instance_and_params[0], G_OBJECT_TYPE (instance));
	g_value_set_object (&instance_and_params[0], instance);

	for (i = 0 ; i < query.n_params ; i++) {
		g_value_init (&instance_and_params[i+1],
		              query.param_types[i]
			         & ~G_SIGNAL_TYPE_STATIC_SCOPE);
		gperl_value_from_sv (&instance_and_params[i+1], ST (i+1));
	}

	if (query.return_type != G_TYPE_NONE)
		g_value_init (&return_value,
		              query.return_type
			         & ~G_SIGNAL_TYPE_STATIC_SCOPE);
	
	g_signal_chain_from_overridden (instance_and_params, &return_value);

	for (i = 0 ; i < 1 + query.n_params ; i++)
		g_value_unset (instance_and_params+i);
	g_free (instance_and_params);

	if (G_TYPE_NONE != (query.return_type & ~G_SIGNAL_TYPE_STATIC_SCOPE)) {
		SAVED_STACK_XPUSHs (sv_2mortal (gperl_sv_from_value (&return_value)));
		g_value_unset (&return_value);
	}
