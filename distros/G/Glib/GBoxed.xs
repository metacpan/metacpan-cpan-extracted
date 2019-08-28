/*
 * Copyright (C) 2003-2005, 2009-2013 by the gtk2-perl team (see the file
 * AUTHORS for the full list)
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

=head2 GBoxed

=over

=item GPerlBoxedWrapperClass

Specifies the vtable of functions to be used for bringing boxed types in
and out of perl.  The structure is defined like this:

 typedef struct _GPerlBoxedWrapperClass GPerlBoxedWrapperClass;
 struct _GPerlBoxedWrapperClass {
          GPerlBoxedWrapFunc    wrap;
          GPerlBoxedUnwrapFunc  unwrap;
          GPerlBoxedDestroyFunc destroy;
 };

The members are function pointers, each of which serves a specific purpose:

=over

=item GPerlBoxedWrapFunc

turn a boxed pointer into an SV.  gtype is the type of the boxed pointer,
and package is the package to which that gtype is registered (the lookup
has already been done for you at this point).  if own is true, the wrapper
is responsible for freeing the object; if it is false, some other code 
owns the object and you must NOT free it.

 typedef SV*      (*GPerlBoxedWrapFunc)    (GType        gtype,
                                            const char * package,
                                            gpointer     boxed,
                                            gboolean     own);

=item GPerlBoxedUnwrapFunc

turn an SV into a boxed pointer.  like GPerlBoxedWrapFunc, gtype and package
are the registered type pair, already looked up for you (in the process of
finding the proper wrapper class).  sv is the sv to unwrap.

 typedef gpointer (*GPerlBoxedUnwrapFunc)  (GType        gtype,
                                            const char * package,
                                            SV         * sv);

=item GPerlBoxedDestroyFunc

this will be called by Glib::Boxed::DESTROY, when the wrapper is destroyed.
it is a hook that allows you to destroy an object owned by the wrapper;
note, however, that you will have had to keep track yourself of whether
the object was to be freed.

 typedef void     (*GPerlBoxedDestroyFunc) (SV         * sv);

=back

=cut
/* there's still one list open! */

#include "gperl.h"

/* #define NOISY */

/*
!PRIVATE!

BoxedInfo

similar to ClassInfo in GObject.xs, BoxedInfo stores information about a
boxed type's mapping from C to perl.  we keep two hashes of these structures,
one indexed by GType, the other by perl package name, for quick and easy
lookup.

the fundamental job of this mapping is to tell us what perl package 
corresponds to a particular GType.

the next most important thing is the wrapper_class --- this tells the bindings
what set of functions to use to convert this boxed type in and out of perl.
a default implementation is supplied; see the BoxedWrapper and default_*
stuff.

 */

static GHashTable * info_by_gtype = NULL;
static GHashTable * info_by_package = NULL;

/* and thread-safety for the above: */
G_LOCK_DEFINE_STATIC (info_by_gtype);
G_LOCK_DEFINE_STATIC (info_by_package);

typedef struct _BoxedInfo BoxedInfo;
typedef struct _BoxedWrapper BoxedWrapper;

struct _BoxedInfo {
	GType                    gtype;
	char                   * package;
	GPerlBoxedWrapperClass * wrapper_class;
};


static BoxedInfo *
boxed_info_new (GType gtype,
		const char * package,
		GPerlBoxedWrapperClass * wrapper_class)
{
	BoxedInfo * boxed_info;
	boxed_info = g_new0 (BoxedInfo, 1);
	boxed_info->gtype = gtype;
	boxed_info->package = package ? g_strdup (package) : NULL;
	boxed_info->wrapper_class = wrapper_class;
	return boxed_info;
}

static BoxedInfo *
boxed_info_copy (BoxedInfo * boxed_info)
{
	BoxedInfo * new_boxed_info;
	new_boxed_info = g_new0 (BoxedInfo, 1);
	memcpy (new_boxed_info, boxed_info, sizeof (BoxedInfo));
	new_boxed_info->package = g_strdup (boxed_info->package);
	return new_boxed_info;
}

static void
boxed_info_destroy (BoxedInfo * boxed_info)
{
	if (boxed_info) {
		boxed_info->gtype = 0;
		if (boxed_info->package)
			g_free (boxed_info->package);
		boxed_info->package = NULL;
		boxed_info->wrapper_class = NULL;
		g_free (boxed_info);
	}
}

=item void gperl_register_boxed (GType gtype, const char * package, GPerlBoxedWrapperClass * wrapper_class)

Register a mapping between the GBoxed derivative I<gtype> and I<package>.  The
specified, I<wrapper_class> will be used to wrap and unwrap objects of this
type; you may pass NULL to use the default wrapper (the same one returned by
gperl_default_boxed_wrapper_class()).

In normal usage, the standard opaque wrapper supplied by the library is
sufficient and correct.  In some cases, however, you want a boxed type to map
directly to a native perl type; for example, some struct may be more
appropriately represented as a hash in perl.  Since the most necessary place
for this conversion to happen is in gperl_value_from_sv() and
gperl_sv_from_value(), the only reliable and robust way to implement this 
is a hook into gperl_get_boxed_check() and gperl_new_boxed(); that is
exactly the purpose of I<wrapper_class>.  See C<GPerlBoxedWrapperClass>.

I<gperl_register_boxed> does not copy the contents of I<wrapper_class> -- it
assumes that I<wrapper_class> is statically allocated and that it will be valid
for the whole lifetime of the program.

=cut
void
gperl_register_boxed (GType gtype,
                      const char * package,
                      GPerlBoxedWrapperClass * wrapper_class)
{
	BoxedInfo * boxed_info;

	G_LOCK (info_by_gtype);
	G_LOCK (info_by_package);

	if (!info_by_gtype) {
		info_by_gtype = g_hash_table_new_full (g_direct_hash,
						       g_direct_equal,
						       NULL, 
						       (GDestroyNotify)
							 boxed_info_destroy);
		info_by_package = g_hash_table_new_full (g_str_hash,
						         g_str_equal,
						         NULL, 
						         NULL);
	}
	boxed_info = boxed_info_new (gtype, package, wrapper_class);

	/* We need to insert into info_by_package first because there might
	 * otherwise be trouble if we overwrite an entry: inserting into
	 * info_by_gtype frees the boxed_info of the overwritten entry, so that
	 * boxed_info->package is no longer valid at this point.
	 *
	 * Note also it's g_hash_table_replace() for info_by_package,
	 * because the old key string in the old boxed_info will be freed
	 * when info_by_gtype updates the value there.
	 */
	g_hash_table_replace (info_by_package, boxed_info->package, boxed_info);
	g_hash_table_insert (info_by_gtype, (gpointer) gtype, boxed_info);

	/* GBoxed types are plain structures, so it would be really
	 * surprising to find a boxed type that actually inherits another
	 * boxed type.  we'll do that at the perl level, for example with
	 * GdkEvent, but at the C level it's not safe.  such things should
	 * be objects.
	 *  so, we don't have to worry about the complicated semantics of
	 * type registration like gperl_register_object, and life is simple
	 * and beautiful.
	 */
	if (package && gtype != G_TYPE_BOXED)
		gperl_set_isa (package, "Glib::Boxed");
#ifdef NOISY
	warn ("gperl_register_boxed (%d(%s), %s, %p)\n",
	      gtype, g_type_name (gtype), package, wrapper_class);
#endif

	G_UNLOCK (info_by_gtype);
	G_UNLOCK (info_by_package);
}

=item void gperl_register_boxed_alias (GType gtype, const char * package)

Makes I<package> an alias for I<type>.  This means that the package name
specified by I<package> will be mapped to I<type> by
I<gperl_boxed_type_from_package>, but I<gperl_boxed_package_from_type> won't
map I<type> to I<package>.  This is useful if you want to change the canonical
package name of a type while preserving backwards compatibility with code which
uses I<package> to specify I<type>.

In order for this to make sense, another package name should be registered for
I<type> with I<gperl_register_boxed>.

=cut

void
gperl_register_boxed_alias (GType gtype,
			    const char * package)
{
	BoxedInfo * boxed_info;

	G_LOCK (info_by_gtype);
	boxed_info = (BoxedInfo *)
		g_hash_table_lookup (info_by_gtype, (gpointer) gtype);
	G_UNLOCK (info_by_gtype);

	if (!boxed_info) {
		croak ("cannot register alias %s for the unregistered type %s",
		       package, g_type_name (gtype));
	}

	G_LOCK (info_by_package);
	/* associate package with the same boxed_info.  boxed_info is still
	   owned by info_by_gtype.  info_by_package doesn't have a
	   free-function installed, so that's ok. */
	g_hash_table_insert (info_by_package, (char *) package, boxed_info);
	G_UNLOCK (info_by_package);
}

=item void gperl_register_boxed_synonym (GType registered_gtype, GType synonym_gtype)

Registers I<synonym_gtype> as a synonym for I<registered_gtype>.  All boxed
objects of type I<synonym_gtype> will then be treated as if they were of type
I<registered_gtype>, and I<gperl_boxed_package_from_type> will return the
package associated with I<registered_gtype>.

I<registered_gtype> must have been registered with I<gperl_register_boxed>
already.

=cut

void
gperl_register_boxed_synonym (GType registered_gtype,
                              GType synonym_gtype)
{
	BoxedInfo * registered_boxed_info, * synonym_boxed_info;

	G_LOCK (info_by_gtype);

	registered_boxed_info = (BoxedInfo *)
		g_hash_table_lookup (info_by_gtype, (gpointer) registered_gtype);

	if (!registered_boxed_info) {
		croak ("cannot make %s synonymous to the unregistered type %s",
		       g_type_name (synonym_gtype),
		       g_type_name (registered_gtype));
	}

	synonym_boxed_info = boxed_info_copy (registered_boxed_info);
	g_hash_table_insert (info_by_gtype, (gpointer) synonym_gtype,
	                     synonym_boxed_info);

	G_UNLOCK (info_by_gtype);
}

=item GType gperl_boxed_type_from_package (const char * package)

Look up the GType associated with package I<package>.  Returns 0 if I<type> is
not registered.

=cut
GType
gperl_boxed_type_from_package (const char * package)
{
	BoxedInfo * boxed_info;

	G_LOCK (info_by_package);

	boxed_info = (BoxedInfo*)
		g_hash_table_lookup (info_by_package, package);

	G_UNLOCK (info_by_package);

	if (!boxed_info)
		return 0;
	return boxed_info->gtype;
}

=item const char * gperl_boxed_package_from_type (GType type)

Look up the package associated with GBoxed derivative I<type>.  Returns NULL if
I<type> is not registered.

=cut
const char *
gperl_boxed_package_from_type (GType type)
{
	BoxedInfo * boxed_info;

	G_LOCK (info_by_gtype);

	boxed_info = (BoxedInfo*)
		g_hash_table_lookup (info_by_gtype, (gpointer) type);

	G_UNLOCK (info_by_gtype);

	if (!boxed_info)
		return NULL;
	return boxed_info->package;
}

/************************************************************/

/*
BoxedWrapper

In order to make life simple, we supply a default GPerlBoxedWrapperClass,
which wraps boxed type objects into an opaque data structure.

GBoxed types don't know what their own type is, nor do they give you a way
to store metadata.  thus, we actually wrap a BoxedWrapper struct into 
the perl wrapper, and store the boxed object and some metadata in the
BoxedWrapper.
*/

/* inspired by pygtk */
struct _BoxedWrapper {
	gpointer boxed;
	GType gtype;
	gboolean free_on_destroy;
};

static BoxedWrapper *
boxed_wrapper_new (gpointer boxed,
                   GType gtype,
                   gboolean free_on_destroy)
{
	BoxedWrapper * boxed_wrapper;
	boxed_wrapper = g_new (BoxedWrapper, 1);
	boxed_wrapper->boxed = boxed;
	boxed_wrapper->gtype = gtype;
	boxed_wrapper->free_on_destroy = free_on_destroy;
	return boxed_wrapper;
}

static void
boxed_wrapper_destroy (BoxedWrapper * boxed_wrapper)
{
	if (boxed_wrapper) {
		if (boxed_wrapper->free_on_destroy)
			g_boxed_free (boxed_wrapper->gtype, boxed_wrapper->boxed);
		g_free (boxed_wrapper);
	} else {
		warn ("boxed_wrapper_destroy called on NULL pointer");
	}
}

static SV *
default_boxed_wrap (GType        gtype,
		    const char * package,
		    gpointer     boxed,
		    gboolean     own)
{
	SV * sv;
	BoxedWrapper * boxed_wrapper;

	boxed_wrapper = boxed_wrapper_new (boxed, gtype, own);

	sv = newSV (0);
	sv_setref_pv (sv, package, boxed_wrapper);

#ifdef NOISY
	warn ("default_boxed_wrap 0x%p for %s 0x%p",
	      boxed_wrapper, package, boxed);
#endif
	return sv;
}

static gpointer
default_boxed_unwrap (GType        gtype,
		      const char * package,
		      SV         * sv)
{
	BoxedWrapper * boxed_wrapper;

	PERL_UNUSED_VAR (gtype);

	if (!gperl_sv_is_ref (sv))
		croak ("expected a blessed reference");

	if (!sv_derived_from (sv, package))
		croak ("%s is not of type %s",
		       gperl_format_variable_for_output (sv),
		       package);

	boxed_wrapper = INT2PTR (BoxedWrapper*, SvIV (SvRV (sv)));
	if (!boxed_wrapper)
		croak ("internal nastiness: boxed wrapper contains NULL pointer");
	return boxed_wrapper->boxed;

}

static void
default_boxed_destroy (SV * sv)
{
#ifdef NOISY
	{
	BoxedWrapper * wrapper = (BoxedWrapper*) SvIV (SvRV (sv));
	warn ("default_boxed_destroy wrapper 0x%p --- %s 0x%p\n", wrapper,
	      g_type_name (wrapper ? wrapper->gtype : 0),
	      wrapper ? wrapper->boxed : NULL);
	}
#endif
	boxed_wrapper_destroy (INT2PTR (BoxedWrapper*, SvIV (SvRV (sv))));
}


static GPerlBoxedWrapperClass _default_wrapper_class = {
	default_boxed_wrap,
	default_boxed_unwrap,
	default_boxed_destroy
};

=item GPerlBoxedWrapperClass * gperl_default_boxed_wrapper_class (void)

get a pointer to the default wrapper class; handy if you want to use
the normal wrapper, with minor modifications.  note that you can just
pass NULL to gperl_register_boxed(), so you really only need this in
fringe cases.

=cut
GPerlBoxedWrapperClass *
gperl_default_boxed_wrapper_class (void)
{
	return &_default_wrapper_class;
}

/***************************************************************************/


=item SV * gperl_new_boxed (gpointer boxed, GType gtype, gboolean own)

Export a GBoxed derivative to perl, according to whatever
GPerlBoxedWrapperClass is registered for I<gtype>.  In the default
implementation, this means wrapping an opaque perl object around the pointer
to a small wrapper structure which stores some metadata, such as whether
the boxed structure should be destroyed when the wrapper is destroyed
(controlled by I<own>; if the wrapper owns the object, the wrapper is in
charge of destroying it's data).

This function might end up calling other Perl code, so if you use it in XS code
for a generic GType, make sure the stack pointer is set up correctly before the
call, and restore it after the call.

=cut
SV *
gperl_new_boxed (gpointer boxed,
		 GType gtype,
		 gboolean own)
{
	BoxedInfo * boxed_info;
	GPerlBoxedWrapFunc wrap;

	if (!boxed)
	{
#ifdef NOISY
		warn ("NULL pointer made it into gperl_new_boxed");
#endif
		return &PL_sv_undef;
	}

	G_LOCK (info_by_gtype);

	boxed_info = (BoxedInfo*)
		g_hash_table_lookup (info_by_gtype, (gpointer) gtype);

	G_UNLOCK (info_by_gtype);

	if (!boxed_info)
		croak ("GType %s (%lu) is not registered with gperl",
		       g_type_name (gtype), gtype);

	wrap = boxed_info->wrapper_class
	     ? boxed_info->wrapper_class->wrap
	     : _default_wrapper_class.wrap;
	
	if (!wrap)
		croak ("no function to wrap boxed objects of type %s / %s",
		       g_type_name (gtype), boxed_info->package);

	return (*wrap) (gtype, boxed_info->package, boxed, own);
}


=item SV * gperl_new_boxed_copy (gpointer boxed, GType gtype)

Create a new copy of I<boxed> and return an owner wrapper for it.
I<boxed> may not be NULL.  See C<gperl_new_boxed>.

=cut
SV *
gperl_new_boxed_copy (gpointer boxed,
                      GType gtype)
{
	return boxed
		? gperl_new_boxed (g_boxed_copy (gtype, boxed), gtype, TRUE)
		: &PL_sv_undef;
}


=item gpointer gperl_get_boxed_check (SV * sv, GType gtype)

Extract the boxed pointer from a wrapper; croaks if the wrapper I<sv> is not
blessed into a derivative of the expected I<gtype>.  Does not allow undef.

=cut
gpointer
gperl_get_boxed_check (SV * sv, GType gtype)
{
	BoxedInfo * boxed_info;
	GPerlBoxedUnwrapFunc unwrap;

	if (!gperl_sv_is_defined (sv))
		croak ("variable not allowed to be undef where %s is wanted",
		       g_type_name (gtype));

	G_LOCK (info_by_gtype);
	boxed_info = g_hash_table_lookup (info_by_gtype, (gpointer) gtype);
	G_UNLOCK (info_by_gtype);

	if (!boxed_info)
		croak ("internal problem: GType %s (%lu) has not been registered with GPerl",
			g_type_name (gtype), gtype);

	unwrap = boxed_info->wrapper_class
	       ? boxed_info->wrapper_class->unwrap
	       : _default_wrapper_class.unwrap;

	if (!unwrap)
		croak ("no function to unwrap boxed objects of type %s / %s",
		       g_type_name (gtype), boxed_info->package);

	return (*unwrap) (gtype, boxed_info->package, sv);
}

=back

=cut



static BoxedInfo *
lookup_known_package_recursive (const char * package)
{
	BoxedInfo * boxed_info =
		g_hash_table_lookup (info_by_package, package);

	if (!boxed_info) {
		int i;
		char * isa_name = form ("%s::ISA", package);
		AV * isa = get_av (isa_name, FALSE);
		if (!isa)
			return NULL;
		for (i = 0 ; i <= av_len (isa); i++) {
			SV ** sv = av_fetch (isa, i, FALSE);
			char * p = sv ? SvPV_nolen (*sv) : NULL;
			if (p) {
				boxed_info =
					lookup_known_package_recursive (p);
				if (boxed_info)
					break;
			}
		}
	}

	return boxed_info;
}


#if GLIB_CHECK_VERSION (2, 4, 0)


static SV*
strv_wrap (GType        gtype,
	   const char * package,
	   gpointer     boxed,
	   gboolean     own)
{
	AV * av;
	int i;
	gchar ** strv;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);

	if (!boxed)
		return &PL_sv_undef;

	strv = (gchar**) boxed;

	av = newAV ();

	for (i = 0 ; strv[i] != NULL ; i++)
		av_push (av, newSVGChar (strv[i]));

	if (own)
		g_strfreev (strv);

	return newRV_noinc ((SV*)av);
}

static gpointer
strv_unwrap (GType        gtype,
	     const char * package,
	     SV         * sv)
{
	gchar ** strv = NULL;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);

	/* pass undef */
	if (!gperl_sv_is_defined (sv))
		return NULL;

	if (gperl_sv_is_ref (sv)) {
		AV * av;
		int n;

		/* only allow a reference to an array */
		if (!gperl_sv_is_array_ref (sv))
			croak ("expecting a reference to an array of strings for Glib::Strv");
		av = (AV*) SvRV (sv);
		n = av_len (av) + 1;
		if (n > 0) {
			int i;
			strv = gperl_alloc_temp ((n + 1) * sizeof (gchar *));
			for (i = 0 ; i < n ; i++)
				strv[i] = SvGChar (*av_fetch (av, i, FALSE));
			strv[n] = NULL;
		}
		
	} else {
		/* stringify anything else, assuming it's a one-element list */
		strv = gperl_alloc_temp (2 * sizeof (gchar*));
		strv[0] = SvGChar (sv);
		strv[1] = NULL;
	}

	return strv;
}

static GPerlBoxedWrapperClass strv_wrapper_class = {
	strv_wrap,
	strv_unwrap,
	NULL
};

#endif


static SV*
gstring_wrap (GType        gtype,
	      const char * package,
	      gpointer     boxed,
	      gboolean     own)
{
	SV * sv;
	GString *gstr;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);

	if (!boxed)
		return &PL_sv_undef;

	gstr = (GString*) boxed;

	sv = newSVpv (gstr->str, gstr->len);

	if (own)
		g_string_free (gstr, TRUE);

	return sv;
}

static gpointer
gstring_unwrap (GType        gtype,
	        const char * package,
	        SV         * sv)
{
	GString *gstr = NULL;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);

	/* pass undef */
	if (!gperl_sv_is_defined (sv))
		return NULL;

	gstr = gperl_alloc_temp (sizeof (GString));
	gstr->str = SvPV (sv, gstr->len);
	gstr->allocated_len = gstr->len;

	return gstr;
}

static GPerlBoxedWrapperClass gstring_wrapper_class = {
	gstring_wrap,
	gstring_unwrap,
	NULL
};


#if GLIB_CHECK_VERSION (2, 26, 0)

static SV*
gerror_wrap (GType        gtype,
	     const char * package,
	     gpointer     boxed,
	     gboolean     own)
{
	SV *sv;
	GError *error;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);

	if (!boxed)
		return &PL_sv_undef;

	error = (GError*) boxed;

	sv = gperl_sv_from_gerror (error);

	if (own)
		g_error_free (error);

	return sv;
}

static gpointer
gerror_unwrap (GType        gtype,
	       const char * package,
	       SV         * sv)
{
	GError *error = NULL;
	PERL_UNUSED_VAR (gtype);
	PERL_UNUSED_VAR (package);

	gperl_gerror_from_sv (sv, &error);

	return error;
}

static GPerlBoxedWrapperClass gerror_wrapper_class = {
	gerror_wrap,
	gerror_unwrap,
	NULL
};

#endif



MODULE = Glib::Boxed	PACKAGE = Glib::Boxed

BOOT:
	gperl_register_boxed (G_TYPE_BOXED, "Glib::Boxed", NULL);
	gperl_register_boxed (G_TYPE_STRING, "Glib::String", NULL);
	gperl_set_isa ("Glib::String", "Glib::Boxed");
	gperl_register_boxed (G_TYPE_GSTRING, "Glib::GString", &gstring_wrapper_class);
#if GLIB_CHECK_VERSION (2, 4, 0)
	gperl_register_boxed (G_TYPE_STRV, "Glib::Strv", &strv_wrapper_class);
#endif
#if GLIB_CHECK_VERSION (2, 26, 0)
	gperl_register_boxed (G_TYPE_ERROR, "Glib::Error", &gerror_wrapper_class);
#endif
#if GLIB_CHECK_VERSION (2, 32, 0)
	gperl_register_boxed (G_TYPE_BYTES, "Glib::Bytes", NULL);
#endif


=for object Glib::Boxed Generic wrappers for C structures
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

Glib::Boxed is a generic wrapper mechanism for arbitrary C structures.
For the most part you don't care about this as a Perl developer, but it
is important to know that all Glib::Boxed descendents can be copied with
the C<copy> method.

=cut

=for apidoc
=for signature copy_of_boxed = $boxed->copy
Create and return a new copy of I<$boxed>.
=cut
SV *
copy (SV * sv)
    PREINIT:
	BoxedInfo * boxed_info;
	GPerlBoxedWrapperClass * class;
	gpointer boxed;
	const char * package;
    CODE:
	/* the sticky part is that we have to decipher from the SV what gtype
	 * we actually have; but the SV may have been blessed into some
	 * other type.  however, if we got here, then Glib::Boxed is in the
	 * @ISA somewhere, so we should be able to walk the inheritance
	 * tree until we find a valid GType. */
	package = sv_reftype (SvRV (sv), TRUE);
	G_LOCK (info_by_package);
	boxed_info = lookup_known_package_recursive (package);
	G_UNLOCK (info_by_package);

	if (!boxed_info)
		croak ("can't find boxed class registration info for %s\n",
		       package);

	class = boxed_info->wrapper_class
	      ? boxed_info->wrapper_class
	      : &_default_wrapper_class;

	if (!class->wrap)
		croak ("no function to wrap boxed objects of type %s / %s",
		       g_type_name (boxed_info->gtype), boxed_info->package);
	if (!class->unwrap)
		croak ("no function to unwrap boxed objects of type %s / %s",
		       g_type_name (boxed_info->gtype), boxed_info->package);

	boxed = class->unwrap (boxed_info->gtype, boxed_info->package, sv);

	/* No PUTBACK/SPAGAIN needed here. */
	RETVAL = class->wrap (boxed_info->gtype, boxed_info->package, 
	                      g_boxed_copy (boxed_info->gtype, boxed), TRUE);
    OUTPUT:
	RETVAL

void
DESTROY (sv)
	SV * sv
    PREINIT:
	BoxedInfo * boxed_info;
	const char * class;
	GPerlBoxedDestroyFunc destroy;
    CODE:
	if (!gperl_sv_is_ref (sv) || !SvRV (sv))
		croak ("DESTROY called on a bad value");

	/* we need to find the wrapper class associated with whatever type
	 * the wrapper is blessed into. */
	class = sv_reftype (SvRV (sv), TRUE);
	G_LOCK (info_by_package);
	boxed_info = g_hash_table_lookup (info_by_package, class);
	G_UNLOCK (info_by_package);
#ifdef NOISY
	warn ("Glib::Boxed::DESTROY (%s) for %s -> %s", 
	      SvPV_nolen (sv),
	      class,
	      boxed_info ? g_type_name (boxed_info->gtype) : NULL);
#endif
	destroy = boxed_info
	        ? (boxed_info->wrapper_class
		      ? boxed_info->wrapper_class->destroy
		      : _default_wrapper_class.destroy)
		: NULL;
	if (destroy)
		(*destroy) (sv);

#if GLIB_CHECK_VERSION (2, 32, 0)

MODULE = Glib::Boxed	PACKAGE = Glib::Bytes	PREFIX = g_bytes_

=for object Glib::Bytes Wrappers for bytes objects in GLib

=head1 DESCRIPTION

In addition to the low-level API documented below, L<Glib> also provides
stringification overloading so that you can treat any C<Glib::Bytes> object as
a normal Perl string.

=cut

GBytes_own *
g_bytes_new (class, SV *data)
    PREINIT:
	const char *real_data;
	STRLEN len;
    CODE:
	real_data = SvPVbyte (data, len);
	RETVAL = g_bytes_new (real_data, len);
    OUTPUT:
	RETVAL

SV *
g_bytes_get_data (GBytes *bytes)
    PREINIT:
        gconstpointer data;
	gsize size;
    CODE:
	data = g_bytes_get_data (bytes, &size);
	RETVAL = newSVpv (data, size);
    OUTPUT:
	RETVAL

gsize g_bytes_get_size (GBytes *bytes);

guint g_bytes_hash (GBytes *bytes);

gboolean g_bytes_equal (GBytes *bytes1, GBytes *bytes2);

gint g_bytes_compare (GBytes *bytes1, GBytes *bytes2);

#endif
