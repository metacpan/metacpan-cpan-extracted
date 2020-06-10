/*
 * Copyright (C) 2003-2006, 2010, 2012-2013 by the gtk2-perl team (see the
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

/*
 * the POD directives in here will be stripped by xsubpp before compilation,
 * and are intended to be extracted by podselect when creating xs api
 * reference documentation.  pod must NOT appear within C comments, because
 * it gets replaced by a comment that says "embedded pod stripped".
 */

=head2 GObject

To deal with the intricate interaction of the different reference-counting
semantics of Perl objects versus GObjects, the bindings create a combined
PerlObject+GObject, with the GObject's pointer in magic attached to the Perl
object, and the Perl object's pointer in the GObject's user data.  Thus it's
not really a "wrapper", but we refer to it as one, because "combined Perl
object + GObject" is a cumbersome and confusing mouthful.

GObjects are represented as blessed hash references.  The GObject user data
mechanism is not typesafe, and thus is used only for unsigned integer values;
the Perl-level hash is available for any type of user data.  The combined
nature of the wrapper means that data stored in the hash will stick around as
long as the object is alive.

Since the C pointer is stored in attached magic, the C pointer is not available
to the Perl developer via the hash object, so there's no need to worry about
breaking it from perl.

Propers go to Marc Lehmann for dreaming most of this up.

=over

=cut

#include "gperl.h"
#include "gperl-private.h" /* for GPERL_SET_CONTEXT and
	                    * _gperl_sv_from_value_internal */

typedef struct _ClassInfo ClassInfo;
typedef struct _SinkFunc  SinkFunc;

struct _ClassInfo {
	GType   gtype;
	char  * package;
	gboolean initialized;
};

struct _SinkFunc {
	GType               gtype;
	GPerlObjectSinkFunc func;
};

static GHashTable * types_by_type    = NULL;
static GHashTable * types_by_package = NULL;

/* store outside of the class info maps any options we expect to be sparse;
 * this will save us a fair amount of space. */
static GHashTable * nowarn_by_type = NULL;
static GArray     * sink_funcs     = NULL;

static GQuark wrapper_quark; /* this quark stores the object's wrapper sv */

/* what should be done here */
#define GPERL_THREAD_SAFE !GPERL_DISABLE_THREADSAFE

#if GPERL_THREAD_SAFE
/* keep a list of all gobjects */
static gboolean     perl_gobject_tracking = FALSE;
static GHashTable * perl_gobjects = NULL;
G_LOCK_DEFINE_STATIC (perl_gobjects);
#endif

/* thread safety locks for the modifiables above */
G_LOCK_DEFINE_STATIC (types_by_type);
G_LOCK_DEFINE_STATIC (types_by_package);
G_LOCK_DEFINE_STATIC (nowarn_by_type);
G_LOCK_DEFINE_STATIC (sink_funcs);


static MGVTBL gperl_mg_vtbl;

/*
 * Attach a C<ptr> to the given C<sv>. It can be retrieved later using
 * C<_gperl_find_mg> and removed again using C<_gperl_remove_mg>.
 */

void
_gperl_attach_mg (SV * sv, void * ptr)
{
	sv_magicext (sv, NULL, PERL_MAGIC_ext, &gperl_mg_vtbl,
		     (const char *)ptr, 0);
}

/*
 * Retrieve the magic used to attach a pointer to the given C<sv> using
 * C<_gperl_attach_mg>. The C<mg_ptr> member of the returned struct will contain
 * the actual pointer attached to the scalar.
 */

MAGIC *
_gperl_find_mg (SV * sv)
{
	MAGIC *mg;

	if (SvTYPE (sv) < SVt_PVMG)
		return NULL;

	for (mg = SvMAGIC (sv); mg; mg = mg->mg_moremagic) {
		if (mg->mg_type == PERL_MAGIC_ext
		    && mg->mg_virtual == &gperl_mg_vtbl) {
			assert (mg->mg_ptr);
			return mg;
		}
	}

	return NULL;
}

/* copied from ppport.h, needed for older perls (< 5.8.8?) */
#ifndef SvMAGIC_set
#  define SvMAGIC_set(sv, val)           \
                STMT_START { assert(SvTYPE(sv) >= SVt_PVMG); \
                (((XPVMG*) SvANY(sv))->xmg_magic = (val)); } STMT_END
#endif

/*
 * Remove the association between a pointer attached to C<sv> using
 * C<_gperl_attach_mg> and the C<sv>.
 */

void
_gperl_remove_mg (SV * sv)
{
	MAGIC *mg, *prevmagic = NULL, *moremagic = NULL;

	if (SvTYPE (sv) < SVt_PVMG || !SvMAGIC (sv))
		return;

	for (mg = SvMAGIC (sv); mg; prevmagic = mg, mg = moremagic) {
		moremagic = mg->mg_moremagic;

		if (mg->mg_type == PERL_MAGIC_ext
		    && mg->mg_virtual == &gperl_mg_vtbl)
			break;
	}

	if (prevmagic) {
		prevmagic->mg_moremagic = moremagic;
	} else {
		SvMAGIC_set (sv, moremagic);
	}

	mg->mg_moremagic = NULL;
	Safefree (mg);
}

static ClassInfo *
class_info_new (GType gtype,
		const char * package)
{
	ClassInfo * class_info;

	class_info = g_new0 (ClassInfo, 1);
	class_info->gtype = gtype;
	class_info->package = g_strdup (package);
	class_info->initialized = FALSE;

	return class_info;
}

static void
class_info_destroy (ClassInfo * class_info)
{
	if (class_info) {
		g_free (class_info->package);
		g_free (class_info);
	}
}

static void
class_info_finish_loading (ClassInfo * class_info)
{
	char * child_isa_full;
	AV * isa;
	AV * new_isa;
	int i, items;

#ifdef NOISY
	static int depth = 0;
	char leader[50] = "";
	depth++;
	for (i = 0 ; i < depth ; i++)
		leader[i] = ' ';
	leader[i] = '\0';

	warn ("%s%s(0x%p) -> %s\n",
	      leader, __FUNCTION__, class_info, class_info->package);
#endif

	child_isa_full = g_strconcat (class_info->package, "::ISA", NULL);
	isa = get_av (child_isa_full, FALSE); /* supposed to exist already */
	if (!isa)
		croak ("internal inconsistency -- finishing lazy loading, "
		       "but %s::ISA does not exist", class_info->package);
	g_free (child_isa_full);

	/*
	 * Rather than just blowing away the old @ISA and replacing it with
	 * one of our own, we need to replace the _LazyLoader marker with
	 * the proper new info.  This is because some classes may need to
	 * have interfaces appear in @ISA *before* the parent class, in order
	 * to resolve name clashes -- think of Gtk2::TreeModel::get versus
	 * Glib::Object::get, for example.
	 *
	 * Thus, this will be a little roundabout.
	 */

	new_isa = newAV ();

	items = av_len (isa) + 1;
	for (i = 0 ; i < items ; i++) {
		/* We're shifting the entries off of the @ISA array here
		 * because just accessing them and later calling av_clear
		 * seems to break the caching magic associated with @ISA when
		 * running under perl 5.10.0. */
		SV * sv = av_shift (isa);
		if (!sv)
			continue;
		if (strEQ (SvPV_nolen (sv), "Glib::Object::_LazyLoader")) {
			/* omit _LazyLoader, fill with proper info */
			GType parent_type;
			GType *interfaces;
			guint n_interfaces;
			const char * package;
			int i;

			parent_type = g_type_parent (class_info->gtype);
			if (!parent_type)
				/* we just found GObject or GInterface.
				 * this is legal. */
				continue;

			if (parent_type == G_TYPE_INTERFACE)
				/* not interested in setting this up. */
				continue;

			/* possibly recurse, loading all the way down to
			 * GObject if necessary */
			package = gperl_object_package_from_type (parent_type);

			if (!package) {
				warn ("WHOA!  parent %s of %s is not an object"
				      " or interface!",
				      g_type_name (parent_type),
				      g_type_name (class_info->gtype));
				continue;
			}

			av_push (new_isa, newSVpv (package, 0));

			/* add in any interfaces we can find. */
			interfaces = g_type_interfaces (class_info->gtype,
							&n_interfaces);
			for (i = 0 ; interfaces[i] != 0 ; i++) {
				package = gperl_object_package_from_type
						(interfaces[i]);
				if (package)
					av_push (new_isa,
						 newSVpv (package, 0));
				else
					warn ("interface type %s(%"G_GSIZE_FORMAT") is not"
					      " registered",
					      g_type_name (interfaces[i]),
					      interfaces[i]);
			}
			if (interfaces)
				g_free (interfaces);

			/* this scalar is not needed anymore */
			sv_free (sv);
		} else {
			/* ownership of sv is transferred to new_isa */
			av_push (new_isa, sv);
		}
	}

	/* copy back to the now empty isa */
	items = av_len (new_isa) + 1;
	for (i = 0 ; i < items ; i++) {
		SV ** svp = av_fetch (new_isa, i, FALSE);
		if (svp && *svp)
			av_push (isa, SvREFCNT_inc (*svp));
		else
			warn ("bad pointer inside av\n");
	}

	av_clear (new_isa);
	av_undef (new_isa);

	class_info->initialized = TRUE;

#ifdef NOISY
	warn ("%sdone\n", leader);
	depth--;
#endif
}

static ClassInfo *
find_registered_type_in_ancestry (const char *package)
{
	char *isa_name;
	AV *isa;

	isa_name = g_strconcat (package, "::ISA", NULL);
	isa = get_av (isa_name, FALSE); /* supposed to exist already */
	g_free (isa_name);

	if (isa) {
		int i, n_items = av_len (isa) + 1;
		for (i = 0; i < n_items; i++) {
			ClassInfo *class_info;
			SV **entry;

			entry = av_fetch (isa, i, 0);
			if (!entry || !gperl_sv_is_defined (*entry))
				continue;

			G_LOCK (types_by_package);
			class_info = (ClassInfo*)
				g_hash_table_lookup (types_by_package,
						     SvPV_nolen (*entry));
			G_UNLOCK (types_by_package);

			if (!class_info) {
				/* If this package is not registered, maybe one
				 * of its ancestors is?  So try to recurse into
				 * this package's @ISA. */
				class_info =
					find_registered_type_in_ancestry (
						SvPV_nolen (*entry));
			}

			if (class_info) {
				return class_info;
			}
		}
	}

	return NULL;
}


=item void gperl_register_object (GType gtype, const char * package)

tell the GPerl type subsystem what Perl package corresponds with a given
GObject by GType.  automagically sets up @I<package>::ISA for you.

note that @ISA will not be created for gtype until gtype's parent has
been registered.  if you are experiencing strange problems with a class'
@ISA not being set up, change the order in which you register them.

=cut

void
gperl_register_object (GType gtype,
                       const char * package)
{
	ClassInfo * class_info;

	G_LOCK (types_by_type);
	G_LOCK (types_by_package);

	if (!types_by_type) {
		/* we put the same data pointer into each hash table, so we
		 * must only associate the destructor with one of them.
		 * also, for the string-keyed hashes, the keys will be
		 * destroyed by the ClassInfo destructor, so we don't need
		 * a key_destroy_func. */
		types_by_type = g_hash_table_new_full (g_direct_hash,
						       g_direct_equal,
						       NULL,
						       (GDestroyNotify)
						          class_info_destroy);
		types_by_package = g_hash_table_new_full (g_str_hash,
							  g_str_equal,
							  NULL,
							  NULL);
	}
	class_info = class_info_new (gtype, package);

	/* We need to insert into types_by_package first because there might
	 * otherwise be trouble if we overwrite an entry: inserting into
	 * types_by_type frees the class_info of the overwritten entry, so
	 * that class_info->package is no longer valid at this point.
	 *
	 * Note also it's g_hash_table_replace() for types_by_package,
	 * because the old key string in the old class_info will be freed
	 * when types_by_type updates the value there.
	 */
	g_hash_table_replace (types_by_package, class_info->package, class_info);
	g_hash_table_insert (types_by_type,
	                     (gpointer) class_info->gtype, class_info);
	/* warn ("registered type %s to package %s\n", g_type_name (class_info->gtype), class_info->package); */

	/* defer the actual ISA setup to Glib::Object::_LazyLoader */
	gperl_set_isa (package, "Glib::Object::_LazyLoader");

	G_UNLOCK (types_by_type);
	G_UNLOCK (types_by_package);

	if (G_TYPE_IS_INTERFACE (gtype))
		/*
		 * Force GInterfaces to finish loading now.  In some cases,
		 * we won't cause a call to gperl_object_package_from_type()
		 * on the interface type to happen from perl code before
		 * somebody tries to do a lookup on an object type that
		 * implements that interface, which causes _LazyLoader to
		 * get upset.  Since GInterfaces are not deep-derivable, an
		 * alternative is simply to avoid setting up lazy loading
		 * for GInterfaces, but that can cause problems if the
		 * GInterface type is not registered.
		 *
		 * NOTE:  class_info_finish_loading() may call other
		 *        functions that grab locks, so we need to be
		 *        unlocked.
		 */
		class_info_finish_loading (class_info);
}

=item void gperl_register_object_alias (GType gtype, const char * package)

Makes I<package> an alias for I<type>.  This means that the package name
specified by I<package> will be mapped to I<type> by
I<gperl_object_type_from_package>, but I<gperl_object_package_from_type> won't
map I<type> to I<package>.  This is useful if you want to change the canonical
package name of a type while preserving backwards compatibility with code which
uses I<package> to specify I<type>.

In order for this to make sense, another package name should be registered for
I<type> with I<gperl_register_object>.

=cut

void
gperl_register_object_alias (GType gtype,
			     const char * package)
{
	ClassInfo *class_info;

	G_LOCK (types_by_type);
	class_info = (ClassInfo *)
		g_hash_table_lookup (types_by_type, (gpointer) gtype);
	G_UNLOCK (types_by_type);

	if (!class_info) {
		croak ("cannot register alias %s for the unregistered type %s",
		       package, g_type_name (gtype));
	}

	G_LOCK (types_by_package);
	/* associate package with the same class_info.  class_info is still
	   owned by types_by_type.  types_by_package doesn't have a
	   free-function installed, so that's ok. */
	g_hash_table_insert (types_by_package, (char *) package, class_info);
	G_UNLOCK (types_by_package);
}


=item void gperl_register_sink_func (GType gtype, GPerlObjectSinkFunc func)

Tell gperl_new_object() to use I<func> to claim ownership of objects derived
from I<gtype>.

gperl_new_object() always refs a GObject when wrapping it for the first time.
To have the Perl wrapper claim ownership of a GObject as part of
gperl_new_object(), you unref the object after ref'ing it. however, different
GObject subclasses have different ways to claim ownership; for example,
GtkObject simply requires you to call gtk_object_sink().  To make this concept
generic, this function allows you to register a function to be called when then
wrapper should claim ownership of the object.  The I<func> registered for a
given I<type> will be called on any object for which C<< g_type_isa
(G_TYPE_OBJECT (object), type) >> succeeds.

If no sinkfunc is found for an object, g_object_unref() will be used.

Even though GObjects don't need sink funcs, we need to have them in Glib
as a hook for upstream objects.  If we create a GtkObject (or any
other type of object which uses a different way to claim ownership) via
Glib::Object->new, any upstream wrappers, such as gtk2perl_new_object(), will
B<not> be called.  Having a sink func facility down here enables us always to
do the right thing.

=cut
/*
 * this stuff is directly inspired by pygtk.  i didn't actually copy
 * and paste the code, but it sure looks like i did, down to the names.
 * hey, they were the obvious names!
 *
 * for the record, i think this is a rather dodgy way to do sink funcs
 * --- it presumes that you'll find the right one first; i prepend new
 * registrees in the hopes that this will work out, but nothing guarantees
 * that this will work.  to do it right, the wrappers need to have
 * some form of inherited vtable or something...  but i've had enough
 * problems just getting the object caching working, so i can't really
 * mess with that right now.
 */
void
gperl_register_sink_func (GType gtype,
                          GPerlObjectSinkFunc func)
{
	SinkFunc sf;

	G_LOCK (sink_funcs);

	if (!sink_funcs)
		sink_funcs = g_array_new (FALSE, FALSE, sizeof (SinkFunc));
	sf.gtype = gtype;
	sf.func  = func;
	g_array_prepend_val (sink_funcs, sf);

	G_UNLOCK (sink_funcs);
}

/*
 * helper for gperl_new_object; do whatever you have to do to this
 * object to ensure that the calling code now owns the object.  assumes
 * the object has already been ref'd once.  to do this, we look up the
 * proper sink func; if none has been registered for this type, then
 * just call g_object_unref.
 */
static void
gperl_object_take_ownership (GObject * object)
{
	G_LOCK (sink_funcs);

	if (sink_funcs) {
		guint i;
		for (i = 0 ; i < sink_funcs->len ; i++)
			if (g_type_is_a (G_OBJECT_TYPE (object),
			                 g_array_index (sink_funcs,
			                                SinkFunc, i).gtype)) {
				g_array_index (sink_funcs,
				               SinkFunc, i).func (object);
				G_UNLOCK (sink_funcs);
				return;
			}
	}

	G_UNLOCK (sink_funcs);

	g_object_unref (object);
}

#if GLIB_CHECK_VERSION (2, 10, 0)
static void
sink_initially_unowned (GObject *object)
{
	/* FIXME: This is not correct when the object is not floating.  The
	 * sink function is supposed to effectively remove a reference, but
	 * when the object is not floating, ref_sink+unref == ref+unref == nop.
	 * Luckily, there do not seem to be functions of GInitiallyUnowned
	 * descendants out there that transfer ownership of a non-floating
	 * reference to the caller.  If we ever encounter one, this needs to be
	 * revisited.
	 *
	 * One peculiar corner case is Glib::Object::Introspection's handling
	 * of GtkWindow and its descendants.  G:O:I marks all constructors of
	 * GInitiallyUnowned descendants as transferring ownership (to override
	 * special-casing done by gobject-introspection).  This is thus
	 * inadvertedly also applied to GtkWindow and its descendants even
	 * though their constructors do not transfer ownership (because gtk+
	 * keeps an internal reference to each window).  But due to this
	 * incorrect code below, the ownership transfer is effectively ignored,
	 * resulting in correct behavior. */
	g_object_ref_sink (object);
	g_object_unref (object);
}
#endif


=item void gperl_object_set_no_warn_unreg_subclass (GType gtype, gboolean nowarn)

In versions 1.00 through 1.10x of Glib, the bindings required all types
to be registered ahead of time.  Upon encountering an unknown type, the
bindings would emit a warning to the effect of "unknown type 'Foo';
representing as first known parent type 'Bar'".  However, for some
types, such as GtkStyle or GdkGC, the actual object returned is an
instance of a child type of a private implementation (e.g., a theme
engine ("BlueCurveStyle") or gdk backend ("GdkGCX11")); we neither can
nor should have registered names for these types.  Therefore, it is
possible to tell the bindings not to warn about these unregistered
subclasses, and simply represent them as the parent type.

With 1.12x, the bindings will automatically register unknown classes
into the namespace Glib::Object::_Unregistered to avoid possible
breakage resulting from unknown ancestors of known children.  To
preserve the old registered-as-unregistered behavior, the value
installed by this function is used to prevent the _Unregistered mapping
for such private backend classes.


Note: this assumes I<gtype> has already been registered with
gperl_register_object().

=cut
void
gperl_object_set_no_warn_unreg_subclass (GType gtype,
                                         gboolean nowarn)
{
	G_LOCK (nowarn_by_type);

	if (!nowarn_by_type) {
		if (!nowarn)
			return;
		nowarn_by_type = g_hash_table_new (g_direct_hash,
		                                   g_direct_equal);
	}
	g_hash_table_insert (nowarn_by_type,
	                     (gpointer) gtype,
	                     GINT_TO_POINTER (nowarn));

	G_UNLOCK (nowarn_by_type);
}

static gboolean
gperl_object_get_no_warn_unreg_subclass (GType gtype)
{
	gboolean result;

	G_LOCK (nowarn_by_type);

	if (!nowarn_by_type)
		result = FALSE;
	else
		result = GPOINTER_TO_INT
		              (g_hash_table_lookup (nowarn_by_type,
		                                    (gpointer) gtype));

	G_UNLOCK (nowarn_by_type);

	return result;
}


=item const char * gperl_object_package_from_type (GType gtype)

Get the package corresponding to I<gtype>.  If I<gtype> is not a GObject
or GInterface, returns NULL.  If I<gtype> is not registered to a package
name, a new name of the form C<Glib::Object::_Unregistered::$c_type_name>
will be created, used to register the class, and then returned.

=cut
const char *
gperl_object_package_from_type (GType gtype)
{
	ClassInfo * class_info;

	if (!g_type_is_a (gtype, G_TYPE_OBJECT) &&
	    !g_type_is_a (gtype, G_TYPE_INTERFACE))
		return NULL;

	if (!types_by_type)
		croak ("internal problem: gperl_object_package_from_type "
		       "called before any classes were registered");

	G_LOCK (types_by_type);

	class_info = (ClassInfo *)
		g_hash_table_lookup (types_by_type, (gpointer) gtype);

	G_UNLOCK (types_by_type);

	if (!class_info) {
                /*
                 * Walk up the ancestry to see if we're the child of a type
                 * whose children are private.  In the old days, we called
                 * this "no-warn", to suppress warnings about unregistered
                 * types (e.g. Styles, GCs, etc).  Now we'll use it to
                 * map "private" GTypes to known parent classes.
                 */
                GType parent = gtype;
                while (0 != (parent = g_type_parent (parent))) {
                        if (gperl_object_get_no_warn_unreg_subclass (parent)) {
                                /* Use this class's ClassInfo instead. */
                                class_info = (ClassInfo *)
                                        g_hash_table_lookup (types_by_type,
                                                             (gpointer) parent);
                                break;
                        }
                }
        }

	if (!class_info) {
		gchar * package;

		package = g_strconcat ("Glib::Object::_Unregistered::",
				       g_type_name (gtype), NULL);
		/* XXX find a way to do this without locking twice */
		gperl_register_object (gtype, package);
		g_free (package);
		G_LOCK (types_by_type);
		class_info = (ClassInfo*)
			g_hash_table_lookup (types_by_type, (gpointer) gtype);
		G_UNLOCK (types_by_type);
	}

	g_assert (class_info);

	if (!class_info->initialized) {
		/* do a proper @ISA setup for this guy. */
		class_info_finish_loading (class_info);
	}

	return class_info->package;
}


=item HV * gperl_object_stash_from_type (GType gtype)

Get the stash corresponding to I<gtype>; returns NULL if I<gtype> is
not registered.  The stash is useful for C<bless>ing.

=cut

HV *
gperl_object_stash_from_type (GType gtype)
{
	const char * package = gperl_object_package_from_type (gtype);
	if (package)
		return gv_stashpv (package, TRUE);
	else
		return NULL;
}


=item GType gperl_object_type_from_package (const char * package)

Inverse of gperl_object_package_from_type(),  returns 0 if I<package>
is not registered.

=cut

GType
gperl_object_type_from_package (const char * package)
{
	if (types_by_package) {
		ClassInfo * class_info;

		G_LOCK (types_by_package);

		class_info = (ClassInfo *)
			g_hash_table_lookup (types_by_package, package);

		G_UNLOCK (types_by_package);

		if (class_info) {
			/* class_info_finish_loading calls us, so even if
			 * !class_info->initialized, we should not call it to
			 * avoid recursion. */
			return class_info->gtype;
		} else {
			return 0;
		}
	} else
		croak ("internal problem: gperl_object_type_from_package "
		       "called before any classes were registered");
	return 0; /* not reached */
}

/*
 * Manipulate a pointer to indicate that an SV is undead.
 * Relies on SV pointers being word-aligned.
 */
#define IS_UNDEAD(x) (PTR2UV(x) & 1)
#define MAKE_UNDEAD(x) INT2PTR(void*, PTR2UV(x) | 1)
#define REVIVE_UNDEAD(x) INT2PTR(void*, PTR2UV(x) & ~1)

/*
 * this function is called whenever the gobject gets destroyed. this only
 * happens if the perl object is no longer referenced anywhere else, so
 * put it to final rest here.
 */
static void
gobject_destroy_wrapper (SV *obj)
{
	GPERL_SET_CONTEXT;

	/* As of perl 5.16, this function needs to run even during global
	 * destruction (i.e. when PL_in_clean_objs is true) since we might
	 * otherwise end up with undead HVs hanging on to garbage.  Prior to
	 * 5.16, this did not matter, but recent versions of perl will find
	 * these HVs and call DESTROY on them. */

#ifdef NOISY
        warn ("gobject_destroy_wrapper (%p)[%d]\n", obj,
              SvREFCNT ((SV*)REVIVE_UNDEAD(obj)));
#endif
        obj = REVIVE_UNDEAD(obj);
        _gperl_remove_mg (obj);

        /* we might want to optimize away the call to DESTROY here for non-perl classes. */
        SvREFCNT_dec (obj);
}

static void
update_wrapper (GObject *object, gpointer obj)
{
        /* printf("update_wrapper [%p] (%p)\n", object, obj); */
        g_object_steal_qdata (object, wrapper_quark);
        g_object_set_qdata_full (object,
                                 wrapper_quark,
                                 obj,
                                 (GDestroyNotify)gobject_destroy_wrapper);
}

=item SV * gperl_new_object (GObject * object, gboolean own)

Use this function to get the perl part of a GObject.  If I<object>
has never been seen by perl before, a new, empty perl object will
be created and added to a private key under I<object>'s qdata.  If
I<object> already has a perl part, a new reference to it will be
created. The gobject + perl object together form a combined object that
is properly refcounted, i.e. both parts will stay alive as long as at
least one of them is alive, and only when both perl object and gobject are
no longer referenced will both be freed.

The perl object will be blessed into the package corresponding to the GType
returned by calling G_OBJECT_TYPE() on I<object>; if that class has not
been registered via gperl_register_object(), this function will emit a
warning to that effect (with warn()), and attempt to bless it into the
first known class in the object's ancestry.  Since Glib::Object is
already registered, you'll get a Glib::Object if you are lazy, and thus
this function can fail only if I<object> isn't descended from GObject,
in which case it croaks.  (In reality, if you pass a non-GObject to this
function, you'll be lucky if you don't get a segfault, as there's not
really a way to trap that.)  In practice these warnings can be unavoidable,
so you can use gperl_object_set_no_warn_unreg_subclass() to quell them
on a class-by-class basis.

However, when perl code is calling a GObject constructor (any function
which returns a new GObject), call gperl_new_object() with I<own> set to
%TRUE; this will cause the first matching sink function to be called
on the GObject to claim ownership of that object, so that it will be
destroyed when the perl object goes out of scope. The default sink func
is g_object_unref(); other types should supply the proper function;
e.g., GtkObject should use gtk_object_sink() here.

Returns the blessed perl object, or #&PL_sv_undef if object was #NULL.

=cut

SV *
gperl_new_object (GObject * object,
                  gboolean own)
{
	SV *obj;
	SV *sv;

	/* take the easy way out if we can */
	if (!object) {
#ifdef NOISY
		warn ("gperl_new_object (NULL) => undef\n");
#endif
		return &PL_sv_undef;
	}

	if (!G_IS_OBJECT (object))
		croak ("object %p is not really a GObject", object);

        /* fetch existing wrapper_data */
        obj = (SV *)g_object_get_qdata (object, wrapper_quark);

        if (!obj) {
                /* create the perl object */
                GType gtype = G_OBJECT_TYPE (object);

                HV *stash = gperl_object_stash_from_type (gtype);

                /* We should only get NULL for the stash here if gtype is
                 * neither a GObject nor GInterface.  We filtered out all
                 * non-GObject types a few lines back. */
                g_assert (stash != NULL);

                /*
                 * Create the "object", a hash.
                 *
                 * This does not need to be a HV, the only problem is finding
                 * out what to use, and HV is certainly the way to go for any
                 * built-in objects.
                 */

                /* this increases the combined object's refcount. */
                obj = (SV *)newHV ();
                /* attach magic */
                _gperl_attach_mg (obj, object);

                /* The SV has a ref to the C object.  If we are to own this
                 * object, then any other references will be taken care of
                 * below in take_ownership */
                g_object_ref (object);

                /* create the wrapper to return, the _noinc decreases the
                 * combined refcount by one. */
                sv = newRV_noinc (obj);

                /* bless into the package */
                sv_bless (sv, stash);

                /* attach it to the gobject */
                update_wrapper (object, obj);
                /* printf("creating new wrapper for [%p] (%p)\n", object, obj); */

                /* the noinc is so that the SV (initially) exists only as long
                 * as the perl code needs it.  When the DESTROY gets called, we
                 * check and see if the SV is the only referer to the C object,
                 * and if so remove both.  Otherwise, the SV will become
                 * "undead," to be either revived or destroyed with the C
                 * object */

#ifdef NOISY
		warn ("gperl_new_object%d %s(%p)[%d] => %s (%p) (NEW)\n", own,
		      G_OBJECT_TYPE_NAME (object), object, object->ref_count,
		      gperl_object_package_from_type (G_OBJECT_TYPE (object)),
		      SvRV (sv));
#endif
        } else {
                /* create the wrapper to return, increases the combined
                 * refcount by one. */

                /* if the SV is undead, revive it */
                if (IS_UNDEAD(obj)) {
                    g_object_ref (object);
                    obj = REVIVE_UNDEAD(obj);
                    update_wrapper (object, obj);
                    sv = newRV_noinc (obj);
                    /* printf("reviving undead wrapper for [%p] (%p)\n", object, obj); */
                } else {
                    /* printf("reusing previous wrapper for %p\n", obj); */
                    sv = newRV_inc (obj);
                }
        }

#ifdef NOISY
	warn ("gperl_new_object%d %s(%p)[%d] => %s (%p)[%d] (PRE-OWN)\n", own,
	      G_OBJECT_TYPE_NAME (object), object, object->ref_count,
	      gperl_object_package_from_type (G_OBJECT_TYPE (object)),
	      SvRV (sv), SvREFCNT (SvRV (sv)));
#endif

	if (own)
		gperl_object_take_ownership (object);

#if GPERL_THREAD_SAFE
	if(perl_gobject_tracking)
	{
		G_LOCK (perl_gobjects);
/*g_printerr ("adding object: 0x%p - %d\n", object, object->ref_count);*/
		if (!perl_gobjects)
			perl_gobjects = g_hash_table_new (g_direct_hash, g_direct_equal);
		g_hash_table_insert (perl_gobjects, (gpointer)object, (gpointer)1);
		G_UNLOCK (perl_gobjects);
	}
#endif

	return sv;
}



=item GObject * gperl_get_object (SV * sv)

retrieve the GObject pointer from a Perl object.  Returns NULL if I<sv> is not
linked to a GObject.

Note, this one is not safe -- in general you want to use
gperl_get_object_check().

=cut

GObject *
gperl_get_object (SV * sv)
{
	MAGIC *mg;

	if (!gperl_sv_is_ref (sv) || !(mg = _gperl_find_mg (SvRV (sv))))
		return NULL;

	return (GObject *) mg->mg_ptr;
}


=item GObject * gperl_get_object_check (SV * sv, GType gtype);

croaks if I<sv> is undef or is not blessed into the package corresponding
to I<gtype>.  use this for bringing parameters into xsubs from perl.
Returns the same as gperl_get_object() (provided it doesn't croak first).

=cut

GObject *
gperl_get_object_check (SV * sv,
			GType gtype)
{
	MAGIC *mg;
	const char * package;
	package = gperl_object_package_from_type (gtype);
	if (!package)
		croak ("INTERNAL: GType %s (%lu) is not registered with GPerl!",
		       g_type_name (gtype), gtype);
	if (!gperl_sv_is_ref (sv) || !sv_derived_from (sv, package))
		croak ("%s is not of type %s",
		       gperl_format_variable_for_output (sv),
		       package);
	if (!(mg = _gperl_find_mg (SvRV (sv))))
		croak ("%s is not a proper Glib::Object "
		       "(it doesn't contain the right magic)",
		       gperl_format_variable_for_output (sv));

	return (GObject *) mg->mg_ptr;
}


=item SV * gperl_object_check_type (SV * sv, GType gtype)

Essentially the same as gperl_get_object_check().

This croaks if the types aren't compatible.

=cut

SV *
gperl_object_check_type (SV * sv,
                         GType gtype)
{
	gperl_get_object_check (sv, gtype);
	return sv;
}



/* helper for g_object_[gs]et_parameter */
static void
init_property_value (GObject * object,
		     const char * name,
		     GValue * value)
{
	GParamSpec * pspec;
	pspec = g_object_class_find_property (G_OBJECT_GET_CLASS (object),
	                                      name);
	if (!pspec) {
		const char * classname =
			gperl_object_package_from_type (G_OBJECT_TYPE (object));
		if (!classname)
			classname = G_OBJECT_TYPE_NAME (object);
		croak ("type %s does not support property '%s'",
		       classname, name);
	}
	g_value_init (value, G_PARAM_SPEC_VALUE_TYPE (pspec));
}


=item typedef GObject GObject_noinc

=item typedef GObject GObject_ornull

=item newSVGObject(obj)

=item newSVGObject_noinc(obj)

=item SvGObject(sv)

=item SvGObject_ornull(sv)


=back

=cut

/*
 * $sv = $object->{name}
 *
 * if the key doesn't exist with name, convert - to _ and try again.
 * that is, support both "funny-name" and "funny_name".
 *
 * if create is true, autovivify the key (and always return a value).
 * if create is false, returns NULL is there is no such key.
 */
SV *
_gperl_fetch_wrapper_key (GObject * object,
                          const char * name,
                          gboolean create)
{
	SV ** svp;
	SV * svname;
	HV * wrapper_hash;
	wrapper_hash = g_object_get_qdata (object, wrapper_quark);

	/* we don't care whether the wrapper is alive or undead.  forcibly
	 * remove the undead bit, or the pointer will be unusable. */
	wrapper_hash = REVIVE_UNDEAD (wrapper_hash);

	svname = newSVpv (name, strlen (name));
	svp = hv_fetch (wrapper_hash, SvPV_nolen (svname), SvCUR (svname),
	                FALSE); /* never create on the first try; prefer
	                         * prefer to create the second version. */
	if (!svp) {
		/* the key doesn't exist with that name.  do s/-/_/g and
		 * try again. */
		register char * c;
		for (c = SvPV_nolen (svname); c <= SvEND (svname) ; c++)
			if (*c == '-')
				*c = '_';
		svp = hv_fetch (wrapper_hash,
		                SvPV_nolen (svname), SvCUR (svname),
		                create);
	}
	SvREFCNT_dec (svname);

	return (svp ? *svp : NULL);
}

#if GPERL_THREAD_SAFE
static void
_inc_ref_and_count (GObject * key, gint value, gpointer user_data)
{
	PERL_UNUSED_VAR (user_data);
	g_object_ref (key);
	value += 1;
	g_hash_table_replace (perl_gobjects, key, GINT_TO_POINTER (value));
}
#endif


MODULE = Glib::Object	PACKAGE = Glib::Object	PREFIX = g_object_

#if GPERL_THREAD_SAFE

=for apidoc __hide__

Users shouldn't know this exists.

This is part of the machinery to support object tracking in a threaded
environment.  When perl spawns a new interpreter thread, it invokes
CLONE on all packages -- NOT on objects.  This is our only hook into
that process.

=cut
void
CLONE (gchar * class)
    CODE:
	/* !perl_gobjects can happen when no object has been created yet. */
    	if (perl_gobject_tracking && perl_gobjects &&
	    strcmp (class, "Glib::Object") == 0)
	{
		G_LOCK (perl_gobjects);
/*g_printerr ("we're in clone: %s\n", class);*/
		g_hash_table_foreach (perl_gobjects,
				      (GHFunc)_inc_ref_and_count, NULL);
		G_UNLOCK (perl_gobjects);
	}

#endif

=for apidoc set_threadsafe
Enables/disables threadsafe gobject tracking. Returns whether or not tracking
will be successful and thus whether using perl ithreads will be possible.
=cut
gboolean
set_threadsafe (class, gboolean threadsafe)
    CODE:
#if GPERL_THREAD_SAFE
	RETVAL = perl_gobject_tracking = threadsafe;
#else
	PERL_UNUSED_VAR (threadsafe);
	RETVAL = FALSE;
#endif
    OUTPUT:
	RETVAL

=for object Glib::Object Bindings for GObject
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

GObject is the base object class provided by the gobject library.  It provides
object properties with a notification system, and emittable signals.

Glib::Object is the corresponding Perl object class.  Glib::Objects are
represented by blessed hash references, with a magical connection to the
underlying C object.

=head2 get and set

Some subclasses of C<Glib::Object> override C<get> and C<set> with methods
more useful to the subclass, for example C<Gtk2::TreeModel> getting and
setting row contents.

This is usually done when the subclass has no object properties.  Any object
properties it or a further subclass does have can always be accessed with
C<get_property> and C<set_property> (together with C<find_property> and
C<list_properties> to enquire about them).

Generic code for any object subclass can use the names C<get_property> and
C<set_property> to be sure of getting the object properties as such.

=cut

BOOT:
	gperl_register_object (G_TYPE_INTERFACE, "Glib::Interface");
	gperl_register_object (G_TYPE_OBJECT, "Glib::Object");
#if GLIB_CHECK_VERSION (2, 10, 0)
	gperl_register_object (G_TYPE_INITIALLY_UNOWNED, "Glib::InitiallyUnowned");
	gperl_register_sink_func (G_TYPE_INITIALLY_UNOWNED, sink_initially_unowned);
#endif
	wrapper_quark = g_quark_from_static_string ("Perl-wrapper-object");


void
DESTROY (SV *sv)
    PREINIT:
        GObject *object;
        gboolean was_undead;
    CODE:
        object = gperl_get_object (sv);
        if (!object) /* Happens on GObject destruction. */
                return;
#ifdef NOISY
        warn ("DESTROY< (%p)[%d] => %s (%p)[%d]\n",
              object, object->ref_count,
              gperl_object_package_from_type (G_OBJECT_TYPE (object)),
              sv, SvREFCNT (SvRV(sv)));
#endif
        was_undead = IS_UNDEAD (g_object_get_qdata (object, wrapper_quark));
        /* gobject object still exists, so take back the refcount we lend it. */
        /* this operation does NOT change the refcount of the combined object. */
	if (PL_in_clean_objs) {
                /* be careful during global destruction. basically,
                 * don't bother, since refcounting is no longer meaningful. */
                _gperl_remove_mg (SvRV (sv));
                g_object_steal_qdata (object, wrapper_quark);
        } else {
                SvREFCNT_inc (SvRV (sv));
                if (object->ref_count > 1) {
                    /* become undead */
                    SV *obj = SvRV(sv);
                    update_wrapper (object, MAKE_UNDEAD(obj));
                    /* printf("zombies! [%p] (%p)\n", object, obj);*/
                }
        }
#if GPERL_THREAD_SAFE
	if(perl_gobject_tracking)
	{
		gint count;
		G_LOCK (perl_gobjects);
		count = GPOINTER_TO_INT (g_hash_table_lookup (perl_gobjects, object));
		count--;
		if (count > 0)
		{
/*g_printerr ("decing: %p - %d\n", object, count);*/
			g_hash_table_replace (perl_gobjects, object,
					      GINT_TO_POINTER (count));
		}
		else
		{
/*g_printerr ("removing: %p\n", object);*/
			g_hash_table_remove (perl_gobjects, object);
		}
		G_UNLOCK (perl_gobjects);
	}
#endif
        /* As of perl 5.16, even HVs that are not referenced by any SV will get
         * their DESTROY called during global destruction.  Such HVs can occur
         * when the GObject outlives the HV, as for GtkWindow or GdkScreen.
         * Here in DESTROY such an HV will be in the "undead" state and will
         * not own a reference to the GObject anymore.  Thus we need to avoid
         * calling unref in this case.  See
         * <https://rt.perl.org/rt3//Public/Bug/Display.html?id=36347> for the
         * perl change. */
        if (!was_undead) {
                g_object_unref (object);
        }
#ifdef NOISY
	warn ("DESTROY> (%p) done\n", object);
	/*
        warn ("DESTROY> (%p)[%d] => %s (%p)[%d]",
              object, object->ref_count,
              gperl_object_package_from_type (G_OBJECT_TYPE (object)),
              sv, SvREFCNT (SvRV(sv)));
	*/
#endif

=for apidoc

=for signature object = $class->new (...)

=for arg ... key/value pairs, property values to set on creation

Instantiate a Glib::Object of type I<$class>.  Any key/value pairs in
I<...> are used to set properties on the new object; see C<set>.
This is designed to be inherited by Perl-derived subclasses (see
L<Glib::Object::Subclass>), but you can actually use it to create
any GObject-derived type.

=cut
SV *
g_object_new (class, ...)
	const char *class
    PREINIT:
	int n_params = 0;
        G_GNUC_BEGIN_IGNORE_DEPRECATIONS
	GParameter * params = NULL;
        G_GNUC_END_IGNORE_DEPRECATIONS
	GType object_type;
	GObject * object;
	GObjectClass *oclass = NULL;
    CODE:
        G_GNUC_BEGIN_IGNORE_DEPRECATIONS
#define FIRST_ARG	1
	object_type = gperl_object_type_from_package (class);
	if (!object_type)
		croak ("%s is not registered with gperl as an object type",
		       class);
	if (G_TYPE_IS_ABSTRACT (object_type))
		croak ("cannot create instance of abstract (non-instantiatable)"
		       " type `%s'", g_type_name (object_type));
	if (0 != ((items - 1) % 2))
		croak ("new method expects name => value pairs "
		       "(odd number of arguments detected)");
	if (items > FIRST_ARG) {
		int i;
		if (NULL == (oclass = g_type_class_ref (object_type)))
			croak ("could not get a reference to type class");
		n_params = (items - FIRST_ARG) / 2;
		params = g_new0 (GParameter, n_params);
		for (i = 0 ; i < n_params ; i++) {
			const char * key = SvPV_nolen (ST (FIRST_ARG+i*2+0));
			GParamSpec * pspec;
			pspec = g_object_class_find_property (oclass, key);
			if (!pspec) {
				/* clean up... */
				int j;
				for (j = 0 ; j < i ; j++)
					g_value_unset (&params[j].value);
				g_free (params);
				/* and bail out. */
				croak ("type %s does not support property '%s'",
				       class, key);
			}
			g_value_init (&params[i].value,
			              G_PARAM_SPEC_VALUE_TYPE (pspec));
			/* note: this croaks if there is a problem.  this is
			 * usually the right thing to do, because if it
			 * doesn't know how to convert the value, then there's
			 * something seriously wrong; however, it means that
			 * if there is a problem, all non-trivial values we've
			 * converted will be leaked. */
			gperl_value_from_sv (&params[i].value,
			                     ST (FIRST_ARG+i*2+1));
			params[i].name = key; /* will be valid until this
			                       * xsub is finished */
		}
	}
#undef FIRST_ARG

	object = g_object_newv (object_type, n_params, params);
        G_GNUC_END_IGNORE_DEPRECATIONS

	/* this wrapper *must* own this object!
	 * because we've been through initialization, the perl object
	 * will already exist at this point --- but this still causes
	 * gperl_object_take_ownership to be called. */
	RETVAL = gperl_new_object (object, TRUE);

	if (n_params) {
		int i;
		for (i = 0 ; i < n_params ; i++)
			g_value_unset (&params[i].value);
		g_free (params);
	}
	if (oclass)
		g_type_class_unref (oclass);
    OUTPUT:
	RETVAL


=for apidoc Glib::Object::get
=for arg ... (list) list of property names

Alias for C<get_property> (see L</get and set> above).

=cut

=for apidoc Glib::Object::get_property
=for arg ... (__hide__)

Fetch and return the values for the object properties named in I<...>.

=cut

void
g_object_get (object, ...)
	GObject * object
    ALIAS:
	Glib::Object::get = 0
	Glib::Object::get_property = 1
    PREINIT:
	GValue value = {0,};
	int i;
    CODE:
	/* Use CODE: instead of PPCODE: so we can handle the stack ourselves in
	 * order to avoid that xsubs called by g_object_get_property or
	 * _gperl_sv_from_value_internal overwrite what we put on the stack. */
	PERL_UNUSED_VAR (ix);
	for (i = 1; i < items; i++) {
		char *name = SvPV_nolen (ST (i));
		init_property_value (object, name, &value);
		g_object_get_property (object, name, &value);
		ST (i - 1) =
			sv_2mortal (
				_gperl_sv_from_value_internal (&value, TRUE));
		g_value_unset (&value);
	}
	XSRETURN (items - 1);


=for apidoc Glib::Object::set
=for signature $object->set (key => $value, ...)
=for arg ... key/value pairs

Alias for C<set_property> (see L</get and set> above).

=cut

=for apidoc Glib::Object::set_property
=for signature $object->set_property (key => $value, ...)
=for arg ... (__hide__)

Set object properties.

=cut

void
g_object_set (object, ...)
	GObject * object
    ALIAS:
	Glib::Object::set = 0
	Glib::Object::set_property = 1
    PREINIT:
	GValue value = {0,};
	int i;
    CODE:
	PERL_UNUSED_VAR (ix);
	if (0 != ((items - 1) % 2))
		croak ("set method expects name => value pairs "
		       "(odd number of arguments detected)");

	for (i = 1; i < items; i += 2) {
		char *name = SvPV_nolen (ST (i));
		SV *newval = ST (i + 1);

		init_property_value (object, name, &value);
		gperl_value_from_sv (&value, newval);
		g_object_set_property (object, name, &value);
		g_value_unset (&value);
	}

=for apidoc

Emits a "notify" signal for the property I<$property> on I<$object>.

=cut
void g_object_notify (GObject * object, const gchar * property_name)

=for apidoc

Stops emission of "notify" signals on I<$object>. The signals are queued
until C<thaw_notify> is called on I<$object>.

=cut
void g_object_freeze_notify (GObject * object)

=for apidoc

Reverts the effect of a previous call to C<freeze_notify>. This causes all
queued "notify" signals on I<$object> to be emitted.

=cut
void g_object_thaw_notify (GObject * object)


=for apidoc Glib::Object::list_properties
=for signature list = $object_or_class_name->list_properties
=for arg ... (__hide__)
List all the object properties for I<$object_or_class_name>; returns them as
a list of hashes, containing these keys:

=over

=item name

The name of the property

=item type

The type of the property

=item owner_type

The type that owns the property

=item descr

The description of the property

=item flags

The Glib::ParamFlags of the property

=back

=cut

=for apidoc Glib::Object::find_property
=for signature pspec or undef = $object_or_class_name->find_property ($name)
=for arg name (string)
=for arg ... (__hide__)
Find the definition of object property I<$name> for I<$object_or_class_name>.
Return C<undef> if no such property.  For
the returned data see L<Glib::Object::list_properties>.
=cut
void
g_object_find_property (object_or_class_name, ...)
	SV * object_or_class_name
    ALIAS:
        Glib::Object::list_properties = 1
    PREINIT:
	GType type = G_TYPE_INVALID;
	gchar *name = NULL;
    PPCODE:
	if (gperl_sv_is_ref (object_or_class_name)) {
		GObject * object = SvGObject (object_or_class_name);
		if (!object)
			croak ("wha?  NULL object in list_properties");
		type = G_OBJECT_TYPE (object);
	} else {
		type = gperl_object_type_from_package
		                          (SvPV_nolen (object_or_class_name));
		if (!type)
			croak ("package %s is not registered with GPerl",
			       SvPV_nolen (object_or_class_name));
	}

	if (ix == 0 && items == 2) {
		name = SvGChar (ST (1));
#ifdef NOISY
		warn ("Glib::Object::find_property ('%s', '%s')\n",
		      g_type_name (type),
		      name);
#endif
	}
	else if (ix == 0 && items != 2)
		croak ("Usage: Glib::Object::find_property (class, name)");
	else if (ix == 1 && items != 1)
		croak ("Usage: Glib::Object::list_properties (class)");

	if (G_TYPE_IS_OBJECT (type))
	{
		/* classes registered by perl are kept alive by the bindings.
		 * those coming straight from C are not.  if we had an actual
		 * object, the class will be alive, but if we just had a
		 * package, the class may not exist yet.  thus, we'll have to
		 * do an honest ref here, rather than a peek.
		 */
		GObjectClass *object_class = g_type_class_ref (type);

		if (ix == 0) {
			GParamSpec *pspec;

			pspec = g_object_class_find_property (object_class, name);
			if (pspec)
				XPUSHs (sv_2mortal (newSVGParamSpec (pspec)));
			else
				XPUSHs (newSVsv (&PL_sv_undef));
		}
		else if (ix == 1) {
			GParamSpec **props;
			guint n_props, i;

			props = g_object_class_list_properties (object_class, &n_props);
#ifdef NOISY
			warn ("list_properties: %d properties\n", n_props);
#endif
			if (n_props) {
				EXTEND (SP, (int) n_props);

				for (i = 0; i < n_props; i++)
					PUSHs (sv_2mortal (newSVGParamSpec (props[i])));

			}
			g_free (props); /* must free even when n_props==0 */
		}

		g_type_class_unref (object_class);
	}
#if GLIB_CHECK_VERSION(2,4,0)
	else if (G_TYPE_IS_INTERFACE (type))
	{
		gpointer iface = g_type_default_interface_ref (type);

		if (ix == 0) {
			GParamSpec *pspec;

			pspec = g_object_interface_find_property (iface, name);
			if (pspec)
				XPUSHs (sv_2mortal (newSVGParamSpec (pspec)));
			else
				XPUSHs (newSVsv (&PL_sv_undef));
		}
		else if (ix == 1) {
			GParamSpec **props;
			guint n_props, i;

			props = g_object_interface_list_properties (iface, &n_props);
#ifdef NOISY
			warn ("list_properties: %d properties\n", n_props);
#endif
			if (n_props) {
				EXTEND (SP, (int) n_props);

				for (i = 0; i < n_props; i++)
					PUSHs (sv_2mortal (newSVGParamSpec (props[i])));

			}
			g_free (props); /* must free even when n_props==0 */
		}

		g_type_default_interface_unref (iface);
	}
#endif
	else {
		XSRETURN_EMPTY;
	}

=for apidoc

GObject provides an arbitrary data mechanism that assigns unsigned integers
to key names.  Functionality overlaps with the hash used as the Perl object
instance, so we strongly recommend you use hash keys for your data storage.
The GObject data values cannot store type information, so they are not safe
to use for anything but integer values, and you really should use this method
only if you know what you are doing.

=cut
void
g_object_set_data (object, key, data)
	GObject * object
	gchar * key
	SV * data
    CODE:
	if (SvROK (data) || !SvIOK (data))
		croak ("set_data only sets unsigned integers, use"
		       " a key in the object hash for anything else");
	g_object_set_data (object, key, INT2PTR (gpointer, SvUV (data)));


=for apidoc

Fetch the integer stored under the object data key I<$key>.  These values do not
have types; type conversions must be done manually.  See C<set_data>.

=cut
UV
g_object_get_data (object, key)
	GObject * object
	gchar * key
    CODE:
        RETVAL = PTR2UV (g_object_get_data (object, key));
    OUTPUT:
        RETVAL


###
### rudimentary support for foreign objects.
###

=for apidoc Glib::Object::new_from_pointer

=for arg pointer (unsigned) a C pointer value as an integer.

=for arg noinc (boolean) if true, do not increase the GObject's reference count when creating the Perl wrapper.  this typically means that when the Perl wrapper will own the object.  in general you don't want to do that, so the default is false.

Create a Perl Glib::Object reference for the C object pointed to by I<$pointer>.
You should need this I<very> rarely; it's intended to support foreign objects.

NOTE: the cast from arbitrary integer to GObject may result in a core dump without
warning, because the type-checking macro G_OBJECT() attempts to dereference the
pointer to find a GTypeClass structure, and there is no portable way to validate
the pointer.

=cut
SV *
new_from_pointer (class, pointer, noinc=FALSE)
	gpointer pointer
	gboolean noinc
    CODE:
	RETVAL = gperl_new_object (G_OBJECT (pointer), noinc);
    OUTPUT:
	RETVAL


=for apidoc

Complement of C<new_from_pointer>.

=cut
gpointer
get_pointer (object)
	GObject * object
    CODE:
	RETVAL = object;
    OUTPUT:
	RETVAL

#if 0
=for apidoc
=for arg all if FALSE (or omitted) tie only properties for this object's class, if TRUE tie the properties of this and all parent classes.

A special method available to Glib::Object derivatives, it uses perl's tie
facilities to associate hash keys with the properties of the object. For
example:

  $button->tie_properties;
  # equivilent to $button->set (label => 'Hello World');
  $button->{label} = 'Hello World';
  print "the label is: ".$button->{label}."\n";

Attempts to write to read-only properties will croak, reading a write-only
property will return '[write-only]'.

Care must be taken when using tie_properties with objects of types created with
Glib::Object::Subclass as there may be clashes with existing hash keys that
could cause infinite loops. The solution is to use custom property get/set
functions to alter the storage locations of the properties.
=cut
void
tie_properties (GObject * object, gboolean all=FALSE)

#endif


MODULE = Glib::Object	PACKAGE = Glib::Object::_LazyLoader

=for apidoc __hide__
=cut
void
_load (const char * package)
    PREINIT:
	ClassInfo * class_info;
    CODE:
#ifdef NOISY
	warn ("_load (%s)\n", package);
#endif
	G_LOCK (types_by_package);
	class_info = (ClassInfo*)
		g_hash_table_lookup (types_by_package,
				     package);
	G_UNLOCK (types_by_package);

	/* This can happen when we get called on a package that is not
	 * registered with the type system but is instead manually set up to
	 * inherit from a package that is registered with the type system. For
	 * example:
	 *
	 *   Glib::Object::_LazyLoader
	 *   +----Gtk2::Gdk::Pixmap
	 *        +----Gtk2::Gdk::Bitmap
	 *
	 * When someone tries to call a method on Gtk2::Gdk::Bitmap before
	 * Gtk2::Gdk::Pixmap has been set up, we get in here and class_info ==
	 * NULL.
	 *
	 * So we walk the package's @ISA and look for a package that is
	 * registered.  This is supposed to succeed -- how did we get in here
	 * at all if there is no registered package in the ancestry?
	 */
	if (!class_info)
		class_info = find_registered_type_in_ancestry (package);

	if (!class_info)
		croak ("asked to lazy-load %s, but that package is not "
		       "registered and has no registered packages in its "
		       "ancestry", package);

	class_info_finish_loading (class_info);
