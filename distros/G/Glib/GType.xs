/*
 * Copyright (C) 2003-2005, 2009, 2010, 2013 by the gtk2-perl team (see the
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

=head2 GType / GEnum / GFlags

=over

=cut

#include "gperl.h"
#include "gperl_marshal.h"

#include "gperl-gtypes.h"
#include "gperl-private.h" /* for _gperl_fetch_wrapper_key */

/* for fundamental types */
static GHashTable * types_by_package = NULL;
static GHashTable * packages_by_type = NULL;
static GHashTable * wrapper_class_by_type = NULL;

/* locks for the above */
G_LOCK_DEFINE_STATIC (types_by_package);
G_LOCK_DEFINE_STATIC (packages_by_type);
G_LOCK_DEFINE_STATIC (wrapper_class_by_type);

/*
 * this is just like gtk_type_class --- it keeps a reference on the classes
 * it returns so they stick around.  this is most important for enums and
 * flags, which will be created and destroyed every time you look them up
 * unless you pull this trick.  duplicates a pointer when you are using
 * gtk, but you aren't always using gtk and it's better to be safe than sorry.
 */
gpointer
gperl_type_class (GType type)
{
	static GQuark quark_static_class = 0;
	gpointer class;

	if (!G_TYPE_IS_ENUM (type) && !G_TYPE_IS_FLAGS (type)) {
		g_return_val_if_fail (G_TYPE_IS_OBJECT (type), NULL);
	}

	class = g_type_get_qdata (type, quark_static_class);
	if (!class) {
		if (!quark_static_class)
			quark_static_class = g_quark_from_static_string
						("GPerlStaticTypeClass");
		class = g_type_class_ref (type);
		g_assert (class != NULL);
		g_type_set_qdata (type, quark_static_class, class);
	}

	return class;
}

=item void gperl_register_fundamental (GType gtype, const char * package)

register a mapping between I<gtype> and I<package>.  this is for "fundamental"
types which have no other requirements for metadata storage, such as GEnums,
GFlags, or real GLib fundamental types like G_TYPE_INT, G_TYPE_FLOAT, etc.

=cut
void
gperl_register_fundamental (GType gtype, const char * package)
{
	char * p;
	G_LOCK (types_by_package);
	G_LOCK (packages_by_type);
	if (!types_by_package) {
		types_by_package =
			g_hash_table_new_full (g_str_hash,
			                       g_str_equal,
			                       NULL, NULL);
		packages_by_type =
			g_hash_table_new_full (g_direct_hash,
			                       g_direct_equal,
			                       NULL,
			                       (GDestroyNotify)g_free);
	}
	p = g_strdup (package);
	/* We need to insert into types_by_package first because there might
	 * otherwise be trouble if we overwrite an entry: inserting into
	 * packages_by_type frees the copied package name.
	 *
	 * Note also it's g_hash_table_replace() for types_by_package, because
	 * the old key string will be freed when packages_by_type updates the
	 * value there.
	 */
	g_hash_table_replace (types_by_package, p, (gpointer) gtype);
	g_hash_table_insert (packages_by_type, (gpointer) gtype, p);
	G_UNLOCK (types_by_package);
	G_UNLOCK (packages_by_type);

	if (g_type_is_a (gtype, G_TYPE_FLAGS) && gtype != G_TYPE_FLAGS)
		gperl_set_isa (package, "Glib::Flags");
}

=item void gperl_register_fundamental_alias (GType gtype, const char * package)

Makes I<package> an alias for I<type>.  This means that the package name
specified by I<package> will be mapped to I<type> by
I<gperl_fundamental_type_from_package>, but
I<gperl_fundamental_package_from_type> won't map I<type> to I<package>.  This
is useful if you want to change the canonical package name of a type while
preserving backwards compatibility with code which uses I<package> to specify
I<type>.

In order for this to make sense, another package name should be registered for
I<type> with I<gperl_register_fundamental> or
I<gperl_register_fundamental_full>.

=cut

void
gperl_register_fundamental_alias (GType gtype,
				  const char * package)
{
	const char * res;

	G_LOCK (packages_by_type);
	res = (const char *)
		g_hash_table_lookup (packages_by_type, (gpointer) gtype);
	G_UNLOCK (packages_by_type);

	if (!res) {
		croak ("cannot register alias %s for the unregistered type %s",
		       package, g_type_name (gtype));
	}

	G_LOCK (types_by_package);
	g_hash_table_insert (types_by_package,
			     (char *) package,
			     (gpointer) gtype);
	G_UNLOCK (types_by_package);
}

=item GPerlValueWrapperClass

Specifies the vtable that is to be used to convert fundamental types to and
from Perl variables.

  typedef struct _GPerlValueWrapperClass GPerlValueWrapperClass;
  struct _GPerlValueWrapperClass {
          GPerlValueWrapFunc   wrap;
          GPerlValueUnwrapFunc unwrap;
  };

The members are function pointers, each of which serves a specific purpose:

=over

=item GPerlValueWrapFunc

Turns I<value> into an SV.  The caller assumes ownership of the SV.  I<value>
is not to be modified.

  typedef SV*  (*GPerlValueWrapFunc)   (const GValue * value);

=item GPerlValueUnwrapFunc

Turns I<sv> into its fundamental representation and stores the result in the
pre-configured I<value>.  I<value> must not be overwritten; instead one of the
various C<g_value_set_*()> functions must be used or the C<value-E<gt>data>
pointer must be modified directly.

  typedef void (*GPerlValueUnwrapFunc) (GValue       * value,
                                        SV           * sv);

=back

=cut

=item void gperl_register_fundamental_full (GType gtype, const char * package, GPerlValueWrapperClass * wrapper_class)

Like L<gperl_register_fundamental>, registers a mapping between I<gtype> and
I<package>.  In addition, this also installs the function pointers in
I<wrapper_class> as the handlers for the type.  See L<GPerlValueWrapperClass>.

I<gperl_register_fundamental_full> does not copy the contents of
I<wrapper_class> -- it assumes that I<wrapper_class> is statically allocated
and that it will be valid for the whole lifetime of the program.

=cut
void
gperl_register_fundamental_full (GType gtype,
                                 const char * package,
                                 GPerlValueWrapperClass * wrapper_class)
{
	gperl_register_fundamental (gtype, package);

	G_LOCK (wrapper_class_by_type);
	if (!wrapper_class_by_type) {
		wrapper_class_by_type =
			g_hash_table_new_full (g_direct_hash,
			                       g_direct_equal,
			                       NULL, NULL);
	}
	g_hash_table_insert (wrapper_class_by_type, (gpointer) gtype, wrapper_class);
	G_UNLOCK (wrapper_class_by_type);
}

=item GType gperl_fundamental_type_from_package (const char * package)

look up the GType corresponding to a I<package> registered by
gperl_register_fundamental().

=cut
GType
gperl_fundamental_type_from_package (const char * package)
{
	GType res;
	G_LOCK (types_by_package);
	res = (GType) g_hash_table_lookup (types_by_package, package);
	G_UNLOCK (types_by_package);
	return res;
}

/* objref should be a reference to a blessed something; the return is
   G_TYPE_NONE if it's any other SV.  Is it worth making this public?  Leave
   it private for now.  */
static GType
gperl_fundamental_type_from_obj (SV *objref)
{
	SV *obj;
	const char *package;
	if (!gperl_sv_is_defined (objref))
		return G_TYPE_NONE;  /* ref is not defined */
	obj = SvRV(objref);
	if (obj == NULL)
		return G_TYPE_NONE;  /* ref is not a reference */
	package = sv_reftype (obj, TRUE);
	return gperl_fundamental_type_from_package (package);
}

=item const char * gperl_fundamental_package_from_type (GType gtype)

look up the package corresponding to a I<gtype> registered by
gperl_register_fundamental().

=cut
const char *
gperl_fundamental_package_from_type (GType gtype)
{
	const char * res;
	G_LOCK (packages_by_type);
	res = (const char *)
		g_hash_table_lookup (packages_by_type, (gpointer) gtype);
	G_UNLOCK (packages_by_type);
	return res;
}

=item GPerlValueWrapperClass * gperl_fundamental_wrapper_class_from_type (GType gtype)

look up the wrapper class corresponding to a I<gtype> that has previously been
registered with gperl_register_fundamental_full().

=cut
GPerlValueWrapperClass *
gperl_fundamental_wrapper_class_from_type (GType gtype)
{
	GPerlValueWrapperClass * res = NULL;
	G_LOCK (wrapper_class_by_type);
	if (wrapper_class_by_type) {
		res = (GPerlValueWrapperClass *)
			g_hash_table_lookup (wrapper_class_by_type,
			                     (gpointer) gtype);
	}
	G_UNLOCK (wrapper_class_by_type);
	return res;
}


/****************************************************************************
 * enum and flags handling (mostly from the original gtk2_perl code)
 */

static GEnumValue *
gperl_type_enum_get_values (GType enum_type)
{
	GEnumClass * class;
	g_return_val_if_fail (G_TYPE_IS_ENUM (enum_type), NULL);
	class = gperl_type_class (enum_type);
	return class->values;
}

static GFlagsValue *
gperl_type_flags_get_values (GType flags_type)
{
	GFlagsClass * class;
	g_return_val_if_fail (G_TYPE_IS_FLAGS (flags_type), NULL);
	class = gperl_type_class (flags_type);
	return class->values;
}


=item gboolean gperl_try_convert_enum (GType gtype, SV * sv, gint * val)

return FALSE if I<sv> can't be mapped to a valid member of the registered
enum type I<gtype>; otherwise, return TRUE write the new value to the
int pointed to by I<val>.

you'll need this only in esoteric cases.

=cut
gboolean
gperl_try_convert_enum (GType type,
			SV * sv,
			gint * val)
{
	GEnumValue * vals;
	char *val_p = SvPV_nolen(sv);
	if (*val_p == '-') val_p++;
	vals = gperl_type_enum_get_values (type);
	while (vals && vals->value_nick && vals->value_name) {
		if (gperl_str_eq (val_p, vals->value_nick) ||
		    gperl_str_eq (val_p, vals->value_name)) {
			*val = vals->value;
			return TRUE;
		}
		vals++;
	}
	return FALSE;
}

=item gint gperl_convert_enum (GType type, SV * val)

croak if I<val> is not part of I<type>, otherwise return corresponding value

=cut
gint
gperl_convert_enum (GType type, SV * val)
{
	SV * r;
	int ret;
	GEnumValue * vals;
	if (gperl_try_convert_enum (type, val, &ret))
		return ret;

	/*
	 * This is an error, val should be included in the enum type.
	 * croak with a message.  note that we build the message in an
	 * SV so it will be properly GC'd
	 */
	vals = gperl_type_enum_get_values (type);
	r = newSVpv ("", 0);
	while (vals && vals->value_nick) {
		sv_catpv (r, vals->value_nick);
		if (vals->value_name) {
			sv_catpv (r, " / ");
			sv_catpv (r, vals->value_name);
		}
		if (++vals && vals->value_nick)
			sv_catpv (r, ", ");
	}
	croak ("FATAL: invalid enum %s value %s, expecting: %s",
	       g_type_name (type), SvPV_nolen (val), SvPV_nolen (r));

	/* not reached */
	return 0;
}

=item SV * gperl_convert_back_enum_pass_unknown (GType type, gint val)

return a scalar containing the nickname of the enum value I<val>, or the
integer value of I<val> if I<val> is not a member of the enum I<type>.

=cut
SV *
gperl_convert_back_enum_pass_unknown (GType type,
				      gint val)
{
	GEnumValue * vals = gperl_type_enum_get_values (type);
	while (vals && vals->value_nick && vals->value_name) {
		if (vals->value == val)
			return newSVpv (vals->value_nick, 0);
		vals++;
	}
	return newSViv (val);
}

=item SV * gperl_convert_back_enum (GType type, gint val)

return a scalar which is the nickname of the enum value val, or croak if
val is not a member of the enum.

=cut
SV *
gperl_convert_back_enum (GType type,
			 gint val)
{
	GEnumValue * vals = gperl_type_enum_get_values (type);
	while (vals && vals->value_nick && vals->value_name) {
		if (vals->value == val)
			return newSVpv (vals->value_nick, 0);
		vals++;
	}
	croak ("FATAL: could not convert value %d to enum type %s",
	       val, g_type_name (type));
	return NULL; /* not reached */
}

=item gboolean gperl_try_convert_flag (GType type, const char * val_p, gint * val)

like gperl_try_convert_enum(), but for GFlags.

=cut
gboolean
gperl_try_convert_flag (GType type,
                        const char * val_p,
                        gint * val)
{
	GFlagsValue * vals = gperl_type_flags_get_values (type);
	while (vals && vals->value_nick && vals->value_name) {
		if (gperl_str_eq (val_p, vals->value_name) ||
		    gperl_str_eq (val_p, vals->value_nick)) {
			*val = vals->value;
			return TRUE;
		}
		vals++;
	}

	return FALSE;
}

=item gint gperl_convert_flag_one (GType type, const char * val)

croak if I<val> is not part of I<type>, otherwise return corresponding value.

=cut
gint
gperl_convert_flag_one (GType type,
			const char * val_p)
{
	SV *r;
	GFlagsValue * vals;
	gint ret;
	if (gperl_try_convert_flag (type, val_p, &ret))
		return ret;

	/* This is an error, val should be included in the flags type, die */
	vals = gperl_type_flags_get_values (type);
	r = newSVpv("", 0);
	while (vals && vals->value_nick) {
		sv_catpv (r, vals->value_nick);
		if (vals->value_name) {
			sv_catpv (r, " / ");
			sv_catpv (r, vals->value_name);
		}
		if (++vals && vals->value_nick)
			sv_catpv (r, ", ");
	}
	croak ("FATAL: invalid %s value %s, expecting: %s",
	       g_type_name (type), val_p, SvPV_nolen (r));

	/* not reached */
	return 0;
}

=item gint gperl_convert_flags (GType type, SV * val)

collapse a list of strings to an integer with all the correct bits set,
croak if anything is invalid.

=cut
gint
gperl_convert_flags (GType type,
		     SV * val)
{
	if (gperl_sv_is_ref (val) && sv_derived_from (val, "Glib::Flags"))
		return SvIV (SvRV (val));
	if (gperl_sv_is_array_ref (val)) {
		AV* vals = (AV*) SvRV(val);
		gint value = 0;
		int i;
		for (i=0; i<=av_len(vals); i++)
			value |= gperl_convert_flag_one (type,
					 SvPV_nolen (*av_fetch (vals, i, 0)));
		return value;
	}
	if (SvPOK (val))
		return gperl_convert_flag_one (type, SvPV_nolen (val));

	croak ("FATAL: invalid %s value %s, expecting a string scalar or an arrayref of strings",
	       g_type_name (type), SvPV_nolen (val));
	return 0; /* not reached */
}

static SV *
flags_as_arrayref (GType type,
		   gint val)
{
	GFlagsValue * vals = gperl_type_flags_get_values (type);
	AV * flags = newAV ();
	while (vals && vals->value_nick && vals->value_name) {
		if ((val & vals->value) == vals->value) {
			val -= vals->value;
			av_push (flags, newSVpv (vals->value_nick, 0));
		}
		vals++;
	}
	return newRV_noinc ((SV*) flags);
}

=item SV * gperl_convert_back_flags (GType type, gint val)

convert a bitfield to a list of strings.

=cut
SV *
gperl_convert_back_flags (GType type,
			  gint val)
{
	const char * package;
	package = gperl_fundamental_package_from_type (type);

	if (package) {
		return sv_bless (newRV_noinc (newSViv (val)), gv_stashpv (package, TRUE));
	} else {
		/* return as non-blessed array, and warn. */
		warn ("GFlags %s has no registered perl package, returning as array",
		      g_type_name (type));

		return flags_as_arrayref (type, val);
	}
}

=back

=head2 Inheritance management

=over

=item void gperl_set_isa (const char * child_package, const char * parent_package)

tell perl that I<child_package> inherits I<parent_package>, after whatever else
is already there.  equivalent to C<< push @{$parent_package}::ISA, $child_package; >>

=cut
void
gperl_set_isa (const char * child_package,
               const char * parent_package)
{
	char * child_isa_full;
	AV * isa;

	child_isa_full = g_strconcat (child_package, "::ISA", NULL);
	isa = get_av (child_isa_full, TRUE); /* create on demand */
	/* warn ("--> @%s = qw(%s);\n", child_isa_full, parent_package); */
	g_free (child_isa_full);

	av_push (isa, newSVpv (parent_package, 0));
}


=item void gperl_prepend_isa (const char * child_package, const char * parent_package)

tell perl that I<child_package> inherits I<parent_package>, but before whatever
else is already there.  equivalent to C<< unshift @{$parent_package}::ISA, $child_package; >>

=cut
void
gperl_prepend_isa (const char * child_package,
                   const char * parent_package)
{
	char * child_isa_full;
	AV * isa;

	child_isa_full = g_strconcat (child_package, "::ISA", NULL);
	isa = get_av (child_isa_full, TRUE); /* create on demand */
	/* warn ("--> @%s = qw(%s);\n", child_isa_full, parent_package); */
	g_free (child_isa_full);

	av_unshift (isa, 1);
	av_store (isa, 0, newSVpv (parent_package, 0));
}


=item GType gperl_type_from_package (const char * package)

Look up the GType associated with I<package>, regardless of how it was
registered.  Returns 0 if no mapping can be found.

=cut
GType
gperl_type_from_package (const char * package)
{
	GType t;
	t = gperl_object_type_from_package (package);
	if (t)
		return t;

	t = gperl_boxed_type_from_package (package);
	if (t)
		return t;

	t = gperl_fundamental_type_from_package (package);
	if (t)
		return t;

	t = gperl_param_spec_type_from_package (package);
	if (t)
		return t;

	return 0;
}

=item const char * gperl_package_from_type (GType gtype)

Look up the name of the package associated with I<gtype>, regardless of how it
was registered.  Returns NULL if no mapping can be found.

=cut
const char *
gperl_package_from_type (GType type)
{
	const char * p;
	p = gperl_object_package_from_type (type);
	if (p)
		return p;

	p = gperl_boxed_package_from_type (type);
	if (p)
		return p;

	p = gperl_fundamental_package_from_type (type);
	if (p)
		return p;

	p = gperl_param_spec_package_from_type (type);
	if (p)
		return p;

	return NULL;
}


=back

=head2 Boxed type support for SV

In order to allow GValues to hold perl SVs we need a GBoxed wrapper.

=over

=item GPERL_TYPE_SV

Evaluates to the GType for SVs.  The bindings register a mapping between
GPERL_TYPE_SV and the package 'Glib::Scalar' with gperl_register_boxed().

=item SV * gperl_sv_copy (SV * sv)

implemented as C<< newSVsv (sv) >>.

=item void gperl_sv_free (SV * sv)

implemented as C<< SvREFCNT_dec (sv) >>.

=cut

void
gperl_sv_free (SV * sv)
{
	SvREFCNT_dec (sv);
}

SV *
gperl_sv_copy (SV * sv)
{
	return newSVsv (sv);
}

GType
gperl_sv_get_type (void)
{
	static GType sv_type = 0;
	if (sv_type == 0)
		sv_type = g_boxed_type_register_static ("GPerlSV",
		                                        (GBoxedCopyFunc) gperl_sv_copy,
		                                        (GBoxedFreeFunc) gperl_sv_free);
	return sv_type;
}


=back

=head2 UTF-8 strings with gchar

By convention, gchar* is assumed to point to UTF8 string data,
and char* points to ascii string data.  Here we define a pair of
wrappers for the boilerplate of upgrading Perl strings.  They
are implemented as functions rather than macros, because comma
expressions in macros are not supported by all compilers.

These functions should be used instead of newSVpv and SvPV_nolen
in all cases which deal with gchar* types.

=over

=item gchar * SvGChar (SV * sv)

extract a UTF8 string from I<sv>.

=cut

/*const*/ gchar *
SvGChar (SV * sv)
{
	sv_utf8_upgrade (sv);
	return (/*const*/ gchar*) SvPV_nolen (sv);
}

=item SV * newSVGChar (const gchar * str)

copy a UTF8 string into a new SV.  if str is NULL, returns &PL_sv_undef.

=cut

SV *
newSVGChar (const gchar * str)
{
	SV * sv;
	if (!str) return &PL_sv_undef;
	/* sv_setpv ((SV*)$arg, $var); */
	sv = newSVpv (str, 0);
	SvUTF8_on (sv);
	return sv;
}


=back

=head2 64 bit integers

On 32 bit machines and even on some 64 bit machines, perl's IV/UV data type can
only hold 32 bit values.  The following functions therefore convert 64 bit
integers to and from Perl strings if normal IV/UV conversion does not suffice.

=over

=item gint64 SvGInt64 (SV *sv)

Converts the string in I<sv> to a signed 64 bit integer.  If appropriate, uses
C<SvIV> instead.

=cut

#ifdef _MSC_VER
# include <stdlib.h>
#endif

#if GLIB_CHECK_VERSION (2, 12, 0)
# define PORTABLE_STRTOLL(str, end, base) g_ascii_strtoll (str, end, base)
#elif defined(_MSC_VER)
# if _MSC_VER >= 1300
#  define PORTABLE_STRTOLL(str, end, base) _strtoi64 (str, end, base)
# else
#  define PORTABLE_STRTOLL(str, end, base) _atoi64 (str)
# endif
#else
# define PORTABLE_STRTOLL(str, end, base) strtoll (str, end, base)
#endif

#if defined(_MSC_VER) || defined(__MSVCRT__)
# define PORTABLE_LL_FORMAT "%I64d"
#else
# define PORTABLE_LL_FORMAT "%lld"
#endif

gint64
SvGInt64 (SV *sv)
{
#ifdef USE_64_BIT_ALL
	return SvIV (sv);
#else
	return PORTABLE_STRTOLL (SvPV_nolen (sv), NULL, 10);
#endif
}

=item SV * newSVGInt64 (gint64 value)

Creates a PV from the signed 64 bit integer in I<value>.  If appropriate, uses
C<newSViv> instead.

=cut

SV *
newSVGInt64 (gint64 value)
{
#ifdef USE_64_BIT_ALL
	return newSViv (value);
#else
	char string[25];
	STRLEN length;
	SV *sv;

	/* newSVpvf doesn't seem to work correctly.
	sv = newSVpvf (PORTABLE_LL_FORMAT, value); */
	length = sprintf(string, PORTABLE_LL_FORMAT, value);
	sv = newSVpv (string, length);

	return sv;
#endif
}

=item guint64 SvGUInt64 (SV *sv)

Converts the string in I<sv> to an unsigned 64 bit integer.  If appropriate,
uses C<SvUV> instead.

=cut

#if GLIB_CHECK_VERSION (2, 2, 0)
# define PORTABLE_STRTOULL(str, end, base) g_ascii_strtoull (str, end, base)
#elif defined(_MSC_VER) && _MSC_VER >= 1300
# define PORTABLE_STRTOULL(str, end, base) _strtoui64 (str, end, base)
#else
# define PORTABLE_STRTOULL(str, end, base) strtoull (str, end, base)
#endif

#if defined(_MSC_VER) || defined(__MSVCRT__)
# define PORTABLE_ULL_FORMAT "%I64u"
#else
# define PORTABLE_ULL_FORMAT "%llu"
#endif

guint64
SvGUInt64 (SV *sv)
{
#ifdef USE_64_BIT_ALL
	return SvUV (sv);
#else
	return PORTABLE_STRTOULL (SvPV_nolen (sv), NULL, 10);
#endif
}

=item SV * newSVGUInt64 (guint64 value)

Creates a PV from the unsigned 64 bit integer in I<value>.  If appropriate,
uses C<newSVuv> instead.

=cut

SV *
newSVGUInt64 (guint64 value)
{
#ifdef USE_64_BIT_ALL
	return newSVuv (value);
#else
	char string[25];
	STRLEN length;
	SV *sv;

	/* newSVpvf doesn't seem to work correctly.
	sv = newSVpvf (PORTABLE_ULL_FORMAT, value); */
	length = sprintf(string, PORTABLE_ULL_FORMAT, value);
	sv = newSVpv (string, length);

	return sv;
#endif
}




/**************************************************************************/
/*
 * support for pure-perl GObject subclasses.
 *
 * this includes
 *   * creating new object properties
 *   * creating new signals
 *   * overriding the class closures (that is, default handlers) of
 *     existing signals
 *
 * it looks like a huge quivering mass of scary-looking, visually dense
 * code, but it's really simple at the core; the verbosity comes from
 * lots of boilerplate translations and such.
 */

/* TODO/FIXME: utf8 safe??? */
/* muppetman: no, it's not utf8-safe, as it treats the string like ascii.
 *            we implicitly assume in many places that package names will
 *            be ascii; in practice this is the case, but it *is* possible
 *            to get non-ascii package names. */
static char *
sanitize_package_name (const char * pkg_name)
{
	char * s;
	char * ctype_name;

	ctype_name = g_strdup (pkg_name);
	for (s = ctype_name; *s != '\0' ; s++)
		if (*s == ':')
			*s = '_';
	return ctype_name;
}
			
static void
gperl_signal_class_closure_marshal (GClosure *closure,
				    GValue *return_value,
				    guint n_param_values,
				    const GValue *param_values,
				    gpointer invocation_hint,
				    gpointer marshal_data)
{
	GSignalInvocationHint *hint = (GSignalInvocationHint *)invocation_hint;
	GSignalQuery query;
	gchar * tmp;
	SV * method_name;
	STRLEN i;
	HV *stash;
	SV **slot;
	/* see GClosure.xs and gperl_marshal.h for an explanation.  we can't
	 * use that code because this is a different style of closure, but we
	 * need to emulate it very closely. */
#ifdef PERL_IMPLICIT_CONTEXT
	PERL_SET_CONTEXT (marshal_data);
#else
	PERL_UNUSED_VAR (marshal_data);
#endif
	PERL_UNUSED_VAR (closure);

#ifdef NOISY
	warn ("gperl_signal_class_closure_marshal");
#endif
	g_return_if_fail(invocation_hint != NULL);

	g_signal_query (hint->signal_id, &query);

	/* construct method name for this class closure */
	method_name = newSVpvf ("do_%s", query.signal_name);

	/* convert dashes to underscores.  g_signal_name converts all the
	 * underscores in the signal name to dashes, but dashes are not
	 * valid in subroutine names. */
	for (tmp = SvPV_nolen (method_name); *tmp != '\0'; tmp++)
		if (*tmp == '-') *tmp = '_';

	stash = gperl_object_stash_from_type (query.itype);
	assert (stash);
	tmp = SvPV (method_name, i);
	slot = hv_fetch (stash, tmp, i, 0);

	/* does the function exist? then call it. */
	if (slot && GvCV (*slot)) {
		SV * save_errsv;
		gboolean want_return_value;
		int flags;
		dSP;

		ENTER;
		SAVETMPS;

		PUSHMARK (SP);

		g_assert (n_param_values != 0);

		/* watch very carefully the reference counts on the scalar
		 * object references, or else we can get indestructible
		 * objects. */
		EXTEND (SP, (int)n_param_values);
		for (i = 0; i < n_param_values; i++)
			SAVED_STACK_PUSHs (sv_2mortal (gperl_sv_from_value
						((GValue*) &param_values[i])));

		PUTBACK;

		/* now call it */
		/* note: keep this as closely sync'ed as possible with the
		 * definition of GPERL_CLOSURE_MARSHAL_CALL. */
		save_errsv = sv_2mortal (newSVsv (ERRSV));
		want_return_value = return_value && G_VALUE_TYPE (return_value);
		flags = G_EVAL | (want_return_value ? G_SCALAR : G_VOID|G_DISCARD);
		call_method (SvPV_nolen (method_name), flags);
		SPAGAIN;
		if (SvTRUE (ERRSV)) {
			gperl_run_exception_handlers ();

		} else if (want_return_value) {
			gperl_value_from_sv (return_value, POPs);
			PUTBACK;
		}
		SvSetSV (ERRSV, save_errsv);

		FREETMPS;
		LEAVE;
	}

	SvREFCNT_dec (method_name);
}

/**
 * gperl_signal_class_closure_get:
 *
 * Returns the GClosure used for the class closure of signals.  When
 * called, it will invoke the method do_signalname (for the signal
 * "signalname").
 *
 * Returns: the closure.
 */
GClosure *
gperl_signal_class_closure_get(void)
{
	/* FIXME does this need a lock? */
	static GClosure *closure;

	if (closure == NULL) {
		closure = g_closure_new_simple (sizeof (GClosure), NULL);
		/* this is not a GPerlClosure, but the same caveats apply.
		 * see GClosure.xs and gperl_marshal.h. */
#ifndef PERL_IMPLICIT_CONTEXT
		g_closure_set_marshal (closure,
		                       gperl_signal_class_closure_marshal);
#else
		g_closure_set_meta_marshal
				(closure, aTHX,
				 gperl_signal_class_closure_marshal);
#endif

		g_closure_ref (closure);
		g_closure_sink (closure);
	}
	return closure;
}

typedef struct {
	GClosure           * class_closure;
	GSignalFlags         flags;
	GSignalAccumulator   accumulator;
	GPerlCallback      * accu_data;
	GType                return_type;
	GType              * param_types;
	guint                n_params;
} SignalParams;

static SignalParams *
signal_params_new (void)
{
	SignalParams * s = g_new0 (SignalParams, 1);
	s->flags = G_SIGNAL_RUN_FIRST;
	s->return_type = G_TYPE_NONE;
	return s;
}

static void
signal_params_free (SignalParams * s)
{
	if (s) g_free (s->param_types);
	/* the closure will have been sunken and reffed by the signal. */
	/* we are leaking the accumulator.  i don't know any other way. */
	g_free (s);
}

static gboolean
gperl_real_signal_accumulator (GSignalInvocationHint *ihint,
                               GValue *return_accu,
                               const GValue *handler_return,
                               gpointer data)
{
	GPerlCallback * callback = (GPerlCallback *)data;
	SV * sv;
	int n;
	gboolean retval;
	dGPERL_CALLBACK_MARSHAL_SP;

	GPERL_CALLBACK_MARSHAL_INIT (callback);

/*	warn ("gperl_real_signal_accumulator"); */

	/* invoke the callback, with custom marshalling */
	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	PUSHs (sv_2mortal (newSVGSignalInvocationHint (ihint)));
	SAVED_STACK_PUSHs (sv_2mortal (gperl_sv_from_value (return_accu)));
	SAVED_STACK_PUSHs (sv_2mortal (gperl_sv_from_value (handler_return)));

	if (callback->data)
		XPUSHs (callback->data);

	PUTBACK;

	n = call_sv (callback->func, G_EVAL|G_ARRAY);

	if (SvTRUE (ERRSV)) {
		warn ("### WOAH!  unhandled exception in a signal accumulator!\n"
		      "### this is really uncool, and for now i'm not even going to\n"
		      "### try to recover.");
		croak (Nullch);
	}

	if (n != 2) {
		warn ("###\n"
		      "### signal accumulator functions must return two values on the perl stack:\n"
		      "### the (possibly) modified return_acc\n"
		      "### and a boolean value, true if emission should continue\n"
		      "###\n"
		      "### your sub returned %d value%s\n"
		      "###\n"
		      "### there's no reasonable way to recover from this.\n"
		      "### you must fix this code",
		      n, n==1?"":"s");
		croak (Nullch);
	}

	SPAGAIN;

	/*
	 * pop the results off the stack... don't forget that they come back
	 * in reverse order.  (seems so obvious, but, well... i feel dumb.)
	 */
	sv = POPs;
	gperl_value_from_sv (return_accu, sv);

	sv = POPs;
	retval = SvTRUE (sv);

	PUTBACK;
	FREETMPS;
	LEAVE;

	return retval;
}

/*
parse a hash describing a new signal into a SignalParams struct.

all keys are allowed to default.

we look for:

  flags => GSignalFlags, if not present, assumed to be run-first
  param_types => reference to a list of package names,
                 if not present, assumed to be empty (no parameters)
  class_closure => reference to a subroutine to call as the class closure.
                   may also be a string interpreted as the name of a
                   subroutine to call, but you should be very very very
                   careful about that.
                   if not present, the library will attempt to call the
                   method named "do_signal_name" for the signal "signal_name"
                   (uses underscores).
  return_type => package name for return value.  if undefined or not present,
                 the signal expects no return value.  if defined, the signal
                 is expected to return a value; flags must be set such that
                 the signal does not run only first (at least use 'run-last').
  accumulator => quoting the Glib manual: "The signal accumulator is a
                 special callback function that can be used to collect
                 return values of the various callbacks that are called
                 during a signal emission."

 */
static SignalParams *
parse_signal_hash (GType instance_type,
                   const gchar * signal_name,
                   HV * hv)
{
	SignalParams * s = signal_params_new ();
	SV ** svp;

	PERL_UNUSED_VAR (instance_type);
	PERL_UNUSED_VAR (signal_name);

	svp = hv_fetch (hv, "flags", 5, FALSE);
	if (svp && gperl_sv_is_defined (*svp))
		s->flags = SvGSignalFlags (*svp);

	svp = hv_fetch (hv, "param_types", 11, FALSE);
	if (svp && gperl_sv_is_array_ref (*svp)) {
		guint i;
		AV * av = (AV*) SvRV (*svp);
		s->n_params = av_len (av) + 1;
		s->param_types = g_new (GType, s->n_params);
		for (i = 0 ; i < s->n_params ; i++) {
			svp = av_fetch (av, i, 0);
			if (!svp) croak ("how did this happen?");
			s->param_types[i] =
				gperl_type_from_package (SvPV_nolen (*svp));
			if (!s->param_types[i])
				croak ("unknown or unregistered param type %s",
				       SvPV_nolen (*svp));
		}
	}

	svp = hv_fetch (hv, "class_closure", 13, FALSE);
	if (svp && *svp) {
		if (gperl_sv_is_defined (*svp))
			s->class_closure =
				gperl_closure_new (*svp, NULL, FALSE);
		/* else the class closure is NULL */
	} else {
		s->class_closure = gperl_signal_class_closure_get ();
	}

	svp = hv_fetch (hv, "return_type", 11, FALSE);
	if (svp && gperl_sv_is_defined (*svp)) {
		s->return_type = gperl_type_from_package (SvPV_nolen (*svp));
		if (!s->return_type)
			croak ("unknown or unregistered return type %s",
			       SvPV_nolen (*svp));
	}

	svp = hv_fetch (hv, "accumulator", 11, FALSE);
	if (svp && *svp) {
		SV * func = *svp;
		svp = hv_fetch (hv, "accu_data", 9, FALSE);
		s->accumulator = gperl_real_signal_accumulator;
		s->accu_data = gperl_callback_new (func, svp ? *svp : NULL,
		                                   0, NULL, 0);
	}

	return s;
}


static void
add_signals (GType instance_type, HV * signals, AV * interfaces)
{
	HE * he;

	hv_iterinit (signals);
	while (NULL != (he = hv_iternext (signals))) {
		I32 keylen;
		char * signal_name;
		guint signal_id;
		SV * value;

		/* the key is the signal name */
		signal_name = hv_iterkey (he, &keylen);

		/* if, at this point, the signal is already defined in the
		 * ancestry or the interfaces we just added to instance_type,
		 * we can only override the installed closure.  trying to
		 * create a new signal with the same name is an error.
		 *
		 * unfortunately, we cannot simply use instance_type to do the
		 * lookup because g_signal_lookup would complain about it since
		 * it hasn't been fully loaded yet.  see
		 * <https://bugzilla.gnome.org/show_bug.cgi?id=691096>.
		 *
		 * FIXME: the "if (signal_id)" check in the hash ref block
		 * below could be removed since g_signal_newv also checks this.
		 * consequently, this lookup code could be moved into the class
		 * closure block below. */
		signal_id = g_signal_lookup (signal_name,
		                             g_type_parent (instance_type));
		if (!signal_id && interfaces) {
			int i;
			for (i = 0; i <= av_len (interfaces); i++) {
				GType interface_type;
				SV ** svp = av_fetch (interfaces, i, FALSE);
				if (!svp || !gperl_sv_is_defined (*svp))
					continue;
				interface_type = gperl_object_type_from_package (SvPV_nolen (*svp));
				signal_id = g_signal_lookup (signal_name, interface_type);
				if (signal_id)
					break;
			}
		}

		/* parse the key's value... */
		value = hv_iterval (signals, he);
		if (gperl_sv_is_hash_ref (value)) {
			/*
			 * value is a hash describing a new signal.
			 */
			SignalParams * s;

			if (signal_id) {
				GSignalQuery q;
				g_signal_query (signal_id, &q);
				croak ("signal %s already exists in %s",
				       signal_name, g_type_name (q.itype));
			}

			s = parse_signal_hash (instance_type,
			                       signal_name,
			                       (HV*) SvRV (value));
			signal_id = g_signal_newv (signal_name,
			                           instance_type,
			                           s->flags,
			                           s->class_closure,
			                           s->accumulator,
						   s->accu_data,
						   NULL, /* c_marshaller */
			                           s->return_type,
			                           s->n_params,
			                           s->param_types);
			signal_params_free (s);
			if (signal_id == 0)
				croak ("failed to create signal %s",
				       signal_name);

		} else if ((SvPOK (value) && SvLEN (value) > 0) ||
		           gperl_sv_is_code_ref (value)) {
			/*
			 * a subroutine reference or method name to override
			 * the class closure for this signal.
			 */
			GClosure * closure;
			if (!signal_id)
				croak ("can't override class closure for "
				       "unknown signal %s", signal_name);
			closure = gperl_closure_new (value, NULL, FALSE);
			g_signal_override_class_closure (signal_id,
			                                 instance_type,
			                                 closure);

		} else {
			croak ("value for signal key '%s' must be either a "
			       "subroutine (the class closure override) or "
			       "a reference to a hash describing the signal"
			       " to create",
			       signal_name);
		}
	}
}

typedef struct {
	SV * getter;
	SV * setter;
} PropHandler;

static void
prop_handler_free (PropHandler * p)
{
	if (p->getter) SvREFCNT_dec (p->getter);
	if (p->setter) SvREFCNT_dec (p->setter);
	g_free (p);
}

static GHashTable *
find_handlers_for_type (GType type,
                        gboolean create)
{
	GHashTable * handlers;
	static GHashTable * allhandlers = NULL;
	if (NULL == allhandlers)
		allhandlers = g_hash_table_new_full (g_direct_hash, 
						     g_direct_equal,
						     NULL,
						     (GDestroyNotify)
							g_hash_table_destroy);

	handlers = g_hash_table_lookup (allhandlers, (gpointer)type);
	if (!handlers && create) {
		handlers = g_hash_table_new_full (g_direct_hash,
		                                  g_direct_equal,
		                                  NULL,
		                                  (GDestroyNotify)
		                                         prop_handler_free);
		g_hash_table_insert (allhandlers, (gpointer)type, handlers);
	}

	return handlers;
}

static void
prop_handler_install (GType instance_type,
                      guint prop_id,
                      SV * setter,
		      SV * getter)
{
	GHashTable * handlers;
	PropHandler * thishandler;

	handlers = find_handlers_for_type (instance_type, setter || getter);
	if (!handlers)
		return;

	thishandler = g_hash_table_lookup (handlers,
	                                   GUINT_TO_POINTER (prop_id));
	if (!thishandler) {
		thishandler = g_new (PropHandler, 1);
		g_hash_table_insert (handlers,
				     GUINT_TO_POINTER (prop_id),
				     thishandler);
	} else {
		if (thishandler->setter)
			SvREFCNT_dec (thishandler->setter);
		if (thishandler->getter)
			SvREFCNT_dec (thishandler->getter);
	}
	thishandler->setter = setter ? newSVsv (setter) : NULL;
	thishandler->getter = getter ? newSVsv (getter) : NULL;
}

static void
prop_handler_lookup (GType instance_type,
                     guint prop_id,
		     SV ** setter,
		     SV ** getter)
{
	GHashTable * handlers;
	PropHandler * thishandler;

	handlers = find_handlers_for_type (instance_type, setter || getter);
	if (handlers &&
	    (NULL != (thishandler =
	                    g_hash_table_lookup (handlers,
	                                         GUINT_TO_POINTER (prop_id)))))
	{
		if (setter) *setter = thishandler->setter;
		if (getter) *getter = thishandler->getter;
	} else {
		if (setter) *setter = NULL;
		if (getter) *getter = NULL;
	}
}

static void
add_properties (GType instance_type, GObjectClass * oclass, AV * properties)
{
	int propid;

	for (propid = 0; propid <= av_len (properties); propid++) {
		SV * sv = *av_fetch (properties, propid, 1);
		GParamSpec * pspec = NULL;
		if (sv_derived_from (sv, "Glib::ParamSpec"))
			pspec = SvGParamSpec (sv);
		else if (gperl_sv_is_hash_ref (sv)) {
			HV * hv = (HV*) SvRV (sv);
			SV ** svp;
			SV * setter = NULL;
			SV * getter = NULL;
			svp = hv_fetch (hv, "pspec", 5, FALSE);
			if (!svp)
				croak ("Param description hash at index %d "
				       "for %s does not contain key pspec",
				       propid,
				       gperl_object_package_from_type
				       			(instance_type));
			pspec = SvGParamSpec (*svp);

			svp = hv_fetch (hv, "get", 3, FALSE);
			if (svp) getter = *svp;

			svp = hv_fetch (hv, "set", 3, FALSE);
			if (svp) setter = *svp;

			prop_handler_install (instance_type,
			                      propid+1, setter, getter);

		} else {
			croak ("item %d (%s) in property list for %s is "
			       "neither a Glib::ParamSpec nor a param "
			       "description hash",
			       propid, 
			       gperl_format_variable_for_output (sv),
			       gperl_object_package_from_type (instance_type));
		}
		g_object_class_install_property (oclass, propid + 1, pspec);
	}
}

/*
 * look for a function named _INSTALL_OVERRIDES in each package of the
 * ancestry of type, and call it if it exists.  these are done from root
 * down to type, so that later classes may override what ancestors installed.
 * the package name corresponding to type is passed to each one, so the
 * (typically xs) implementations can find the right object class.
 */
static void
install_overrides (GType type)
{
	GSList * types = NULL, * i;
	GType t;
	const char * name = NULL;

	for (t = type ; t != 0 ; t = g_type_parent (t))
		types = g_slist_prepend (types, (gpointer) t);

	for (i = types ; i != NULL ; i = i->next) {
		HV * stash;
		SV ** slot;
		t = (GType) i->data;
		stash = gperl_object_stash_from_type (t);
		slot = hv_fetch (stash, "_INSTALL_OVERRIDES",
		                 sizeof ("_INSTALL_OVERRIDES") - 1,
		                 FALSE);
		if (slot && GvCV (*slot)) {
			dSP;
			ENTER;
			SAVETMPS;
			PUSHMARK (SP);
			if (!name)
				name = gperl_object_package_from_type (type);
			XPUSHs (sv_2mortal (newSVpv (name, 0)));
			PUTBACK;
			call_sv ((SV *)GvCV (*slot), G_VOID|G_DISCARD);
			FREETMPS;
			LEAVE;
		}
	}

	g_slist_free (types);
}

static void
add_interfaces (GType instance_type, AV * interfaces)
{
	int i;
	SV * class_name =
		newSVpv (gperl_object_package_from_type (instance_type), 0);

	for (i = 0; i <= av_len (interfaces); i++) {
		GType interface_type;

		SV ** svp = av_fetch (interfaces, i, FALSE);
		if (!svp || !gperl_sv_is_defined (*svp))
			croak ("encountered undefined interface name");

		interface_type = gperl_object_type_from_package (SvPV_nolen (*svp));
		if (!interface_type) {
			croak ("encountered unregistered interface %s",
			       SvPV_nolen (*svp));
		}

		/* call the interface's setup function on this class. */
		{
			dSP;
			ENTER;
			PUSHMARK (SP);
			EXTEND (SP, 2);
			PUSHs (*svp); /* interface type */
			PUSHs (class_name); /* target type */
			PUTBACK;
			/* this will fail if _ADD_INTERFACE is not defined. */
			call_method ("_ADD_INTERFACE", G_VOID|G_DISCARD);
			LEAVE;
		}
		gperl_prepend_isa (SvPV_nolen (class_name), SvPV_nolen (*svp));
	}

	SvREFCNT_dec (class_name);
}


static void
gperl_type_get_property (GObject * object,
		 guint property_id,
		 GValue * value,
		 GParamSpec * pspec)
{
	HV *stash;
	SV **slot;
	SV * getter;

	prop_handler_lookup (pspec->owner_type, property_id, NULL, &getter);
	if (getter) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK (SP);
		PUSHs (sv_2mortal (gperl_new_object (object, FALSE)));
		PUTBACK;
		call_sv (getter, G_SCALAR);
		SPAGAIN;
		gperl_value_from_sv (value, POPs);
		PUTBACK;
		FREETMPS;
		LEAVE;
		return;
	}

	stash = gperl_object_stash_from_type (pspec->owner_type);
	assert (stash);
	slot = hv_fetch (stash, "GET_PROPERTY", sizeof ("GET_PROPERTY") - 1, 0);

	/* does the function exist? then call it. */
	if (slot && GvCV (*slot)) {
		  dSP;

		  ENTER;
		  SAVETMPS;

		  PUSHMARK (SP);
		  XPUSHs (sv_2mortal (gperl_new_object (object, FALSE)));
		  XPUSHs (sv_2mortal (newSVGParamSpec (pspec)));
		  PUTBACK;

		  if (1 != call_sv ((SV *)GvCV (*slot), G_SCALAR))
			  croak ("%s->GET_PROPERTY didn't return exactly one value", HvNAME (stash));

		  SPAGAIN;

		  gperl_value_from_sv (value, POPs);

		  PUTBACK;
		  FREETMPS;
		  LEAVE;

	} else {
		/* no GET_PROPERTY; look in the wrapper hash. */
		SV * val = _gperl_fetch_wrapper_key
				(object, g_param_spec_get_name (pspec), FALSE);
		if (val)
			gperl_value_from_sv (value, val);
		else {
			/* no value in the wrapper hash.  get the pspec's
			 * default, if it has one. */
			g_param_value_set_default (pspec, value);
		}
	}
}

static void
gperl_type_set_property (GObject * object,
                         guint property_id,
                         const GValue * value,
                         GParamSpec * pspec)
{
	HV  * stash;
	SV ** slot;
	SV  * setter;

	prop_handler_lookup (pspec->owner_type, property_id, &setter, NULL);
	if (setter) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK (SP);
		PUSHs (sv_2mortal (gperl_new_object (object, FALSE)));
		SAVED_STACK_XPUSHs (sv_2mortal (gperl_sv_from_value (value)));
		PUTBACK;
		call_sv (setter, G_VOID|G_DISCARD);
		SPAGAIN;
		FREETMPS;
		LEAVE;
		return;
	}

	stash = gperl_object_stash_from_type (pspec->owner_type);
	assert (stash);
	slot = hv_fetch (stash, "SET_PROPERTY", sizeof ("SET_PROPERTY") - 1, 0);

	/* does the function exist? then call it. */
	if (slot && GvCV (*slot)) {
		  dSP;

		  ENTER;
		  SAVETMPS;

		  PUSHMARK (SP);
		  XPUSHs (sv_2mortal (gperl_new_object (object, FALSE)));
		  XPUSHs (sv_2mortal (newSVGParamSpec (pspec)));
		  SAVED_STACK_XPUSHs (sv_2mortal (gperl_sv_from_value (value)));
		  PUTBACK;

		  call_sv ((SV *)GvCV (*slot), G_VOID|G_DISCARD);

		  FREETMPS;
		  LEAVE;

	} else {
		/* no SET_PROPERTY.  fall back to setting the value into
		 * a key with the pspec's name in the wrapper hash. */
		SV * val = _gperl_fetch_wrapper_key
				(object, g_param_spec_get_name (pspec), TRUE);
		if (val) {
			SV * newval = sv_2mortal (gperl_sv_from_value (value));
			SvSetMagicSV (val, newval);
		} else {
			/* XXX couldn't create the key.  what to do? */
		}
	}
}

static void
gperl_type_finalize (GObject * instance)
{
	int do_nonperl = 1;
	GObjectClass *class;

	/* BIG BUG:
	 * we walk down the class hierarchy and call all
	 * FINALIZE_INSTANCE functions for perl.
	 * We also call the first non-perl finalize function.
	 * This does NOT work when we have gobject -> perl -> non-perl -> perl.
	 * In this case we should probably remove the perl SV so that later
	 * invocations will not try to call into perl.
	  (i.e. check wrapper_sv, steal wrapper_sv, finalize)
	 */

        class = G_OBJECT_GET_CLASS (instance);

	do {
		/* call finalize for each perl class and the topmost non-perl class */
		if (class->finalize == gperl_type_finalize) {
			if (!PL_in_clean_objs) {
				HV *stash = gperl_object_stash_from_type (G_TYPE_FROM_CLASS (class));
				SV **slot = hv_fetch (stash, "FINALIZE_INSTANCE", sizeof ("FINALIZE_INSTANCE") - 1, 0);

				instance->ref_count += 2; /* HACK: temporarily revive the object. */

				/* does the function exist? then call it. */
				if (slot && GvCV (*slot)) {
					  dSP;

					  ENTER;
					  SAVETMPS;

					  PUSHMARK (SP);
					  XPUSHs (sv_2mortal (gperl_new_object (instance, FALSE)));
					  PUTBACK;

					  call_sv ((SV *)GvCV (*slot), G_VOID|G_DISCARD);

					  FREETMPS;
					  LEAVE;
				}

				instance->ref_count -= 2; /* HACK END */
			}
		} else if (do_nonperl) {
			class->finalize (instance);
			do_nonperl = 0;
		}

		class = g_type_class_peek_parent (class);
	} while (class);
}

static void
gperl_type_instance_init (GObject * instance, gpointer g_class)
{
	/*
	 * for new objects, this may be the place where the initial
	 * perl object is created.  we won't worry about the owner
	 * semantics here, but since initializers are called from the
	 * inside out, we will need to worry about making sure we get
	 * blessed into the right class!
	 */
	SV *obj;
	HV *stash = gperl_object_stash_from_type (G_OBJECT_TYPE (instance));
	SV **slot;
	g_assert (stash != NULL);

	PERL_UNUSED_VAR (g_class);

	/* we need to always create a wrapper, regardless of whether there is
	 * an INIT_INSTANCE sub.  otherwise, the fallback mechanism in
	 * GType.xs' SET_PROPERTY handler will not have an HV to store the
	 * properties in.
	 *
	 * we also need to ensure that the wrapper we create is not immediately
	 * destroyed when we return from gperl_type_instance_init.  otherwise,
	 * instances of classes derived from GInitiallyUnowned might be
	 * destroyed prematurely when code in INIT_INSTANCE manages to sink the
	 * initial, floating reference.  example: in a container subclass'
	 * INIT_INSTANCE, adding a child and then calling the child's
	 * get_parent() method.  so we mortalize the wrapper before the
	 * SAVETMPS/FREETMPS pair below.  this should ensure that the wrapper
	 * survives long enough so that it is still intact when the call to the
	 * Perl constructor returns.
	 *
	 * if we always sank floating references, or if we forbade doing things
	 * as described in the example, we could simply free the SV before we
	 * return from gperl_type_instance_init.  this would result in more
	 * predictable reference counting. */
	obj = sv_2mortal (gperl_new_object (instance, FALSE));

	/* we need to re-bless the wrapper because classes change
	 * during construction of an object. */
	sv_bless (obj, stash);

	/* get the INIT_INSTANCE sub from this package. */
	slot = hv_fetch (stash, "INIT_INSTANCE", sizeof ("INIT_INSTANCE") - 1, 0);

#ifdef NOISY
	warn ("gperl_type_instance_init	 %s (%p) => %s\n",
	      G_OBJECT_TYPE_NAME (instance), instance, SvPV_nolen (obj));
#endif

	/* does the function exist? then call it. */
	if (slot && GvCV (*slot)) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK (SP);
		XPUSHs (obj);
		PUTBACK;
		call_sv ((SV *)GvCV (*slot), G_VOID|G_DISCARD);
		FREETMPS;
		LEAVE;
	}
}

static GQuark gperl_type_reg_quark (void) G_GNUC_CONST;
static GQuark
gperl_type_reg_quark (void)
{
	static GQuark q = 0;
	if (!q)
		q = g_quark_from_static_string ("__gperl_type_reg");
	return q;
}

typedef struct {
	GType instance_type;
	AV *interfaces;
	AV *properties;
	HV *signals;
} GPerlClassData;

static void
gperl_type_class_init (GObjectClass * class, GPerlClassData * class_data)
{
	class->finalize     = gperl_type_finalize;
	class->get_property = gperl_type_get_property;
	class->set_property = gperl_type_set_property;

	if (class_data->properties)
		add_properties (class_data->instance_type, class,
		                class_data->properties);
	if (class_data->signals)
		add_signals (class_data->instance_type,
		             class_data->signals, class_data->interfaces);
}

static void
gperl_type_base_init (gpointer class)
{
	/*
	 * tricksey little hobbitses...
	 * 
	 * we use the same function pointer for all perl-derived types'
	 * base_init functions.  since we get the class structure and 
	 * nothing else, we have no way of knowing which class is actually
	 * being booted.  thus, we resort to trickery.
	 * 
	 * we know that class initialization class class_init for your new
	 * type, then goes inside out calling the base_inits for the types
	 * in your ancestry.  that means we'll get into this function once
	 * for each type in a particular class instance's lineage.
	 * 
	 * so, we keep a private hash of class structures we have seen
	 * before, containing a list of the types remaining to be initialized.
	 * each time we get in here, we find the first perl-derived type
	 * (as marked by Glib::Type::register as something which will use
	 * this function), and look for the INIT_BASE function in that type's
	 * package.  we pop items from the list so that we don't use them
	 * twice.  when we've hit the end of the list, we forget that class
	 * instance to save memory; this is safe because we should never
	 * get back in here for that instance anyway.
	 * 
	 * remember that we must pass to the method the package corresponding
	 * to the bottom of the hierarchy, so that client code knows what
	 * class we are actually initializing.  otherwise, INIT_BASE methods
	 * implemented in XS would find the wrong GTypeClass and mangle things
	 * rather badly.
	 * 
	 * many thanks to Brett Kosinski for devising this evil^Wclever scheme.
	 */
#if GLIB_CHECK_VERSION (2, 32, 0)
	/* GRecMutex in static storage do not need initialization */
	static GRecMutex base_init_lock;
#else
	static GStaticRecMutex base_init_lock = G_STATIC_REC_MUTEX_INIT;
#endif /* 2.32 */
	static GHashTable * seen = NULL;
	GSList * types;
	GType t;

#if GLIB_CHECK_VERSION (2, 32, 0)
	g_rec_mutex_lock (&base_init_lock);
#else
	g_static_rec_mutex_lock (&base_init_lock);
#endif /* 2.32 */

	if (!seen)
		seen = g_hash_table_new (g_direct_hash, g_direct_equal);

	types = g_hash_table_lookup (seen, class);

	if (!types) {
		/* haven't seen this class instance before */
		t = G_TYPE_FROM_CLASS (class);
		do {
			types = g_slist_prepend (types, (gpointer) t);
		} while (0 != (t = g_type_parent (t)));
	}

	g_assert (types);

	/* start at the head of the list of types and find the next 
	 * perl-created type. */
	while (types != NULL &&
	       !g_type_get_qdata ((GType)types->data,
	                          gperl_type_reg_quark())) {
		types = g_slist_delete_link (types, types);
	}

	t = types ? (GType) types->data : 0;

	/* and shift this one off so we don't use it again. */
	types = g_slist_delete_link (types, types);

	/* clean up now, while we're thinking about it */
	if (types)
		g_hash_table_replace (seen, class, types);
	else
		g_hash_table_remove (seen, class);

	if (t) {
		const char * package;
		HV * stash;
		SV ** slot;

		package = gperl_package_from_type (t);
		g_assert (package != NULL);

		stash = gv_stashpv (package, FALSE);
		g_assert (stash != NULL);

		slot = hv_fetch (stash, "INIT_BASE", sizeof ("INIT_BASE")-1, 0);

		if (slot && GvCV (*slot)) {
			dSP;
			ENTER;
			SAVETMPS;
			PUSHMARK (SP);
			/* remember, use the bottommost package name! */
			XPUSHs (sv_2mortal (newSVpv
				(g_type_name (G_TYPE_FROM_CLASS (class)), 0)));
			PUTBACK;
			call_sv ((SV*) GvCV (*slot), G_VOID|G_DISCARD);
			FREETMPS;
			LEAVE;
		}
	}

#if GLIB_CHECK_VERSION (2, 32, 0)
	g_rec_mutex_unlock (&base_init_lock);
#else
	g_static_rec_mutex_unlock (&base_init_lock);
#endif /* 2.32 */
}

/* make sure we close the open list to keep from freaking out pod readers... */

=back

=cut

MODULE = Glib::Type	PACKAGE = Glib::Type	PREFIX = g_type_

=for object Glib::Type Utilities for dealing with the GLib Type system

=for flags Glib::SignalFlags
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

This package defines several utilities for dealing with the GLib type system
from Perl.  Because of some fundamental differences in how the GLib and Perl
type systems work, a fair amount of the binding magic leaks out, and you can
find most of that in the C<Glib::Type::register*> functions, which register
new types with the GLib type system.

Most of the rest of the functions provide introspection functionality, such as
listing properties and values and other cool stuff that is used mainly by
Glib's reference documentation generator (see L<Glib::GenPod>).

=cut

BOOT:
	gperl_register_fundamental (G_TYPE_ENUM, "Glib::Enum");
	gperl_register_fundamental (G_TYPE_FLAGS, "Glib::Flags");
	gperl_register_fundamental (G_TYPE_CHAR, "Glib::Char");
	gperl_register_fundamental (G_TYPE_UCHAR, "Glib::UChar");
	gperl_register_fundamental (G_TYPE_INT, "Glib::Int");
	gperl_register_fundamental (G_TYPE_UINT, "Glib::UInt");
	gperl_register_fundamental (G_TYPE_LONG, "Glib::Long");
	gperl_register_fundamental (G_TYPE_ULONG, "Glib::ULong");
	gperl_register_fundamental (G_TYPE_INT64, "Glib::Int64");
	gperl_register_fundamental (G_TYPE_UINT64, "Glib::UInt64");
	gperl_register_fundamental (G_TYPE_FLOAT, "Glib::Float");
	gperl_register_fundamental (G_TYPE_DOUBLE, "Glib::Double");
	gperl_register_fundamental (G_TYPE_BOOLEAN, "Glib::Boolean");
#if GLIB_CHECK_VERSION (2, 10, 0)
	gperl_register_fundamental (G_TYPE_GTYPE, "Glib::GType");
#endif
	gperl_register_boxed (GPERL_TYPE_SV, "Glib::Scalar", NULL);

	/* i love nasty ugly hacks for backwards compat... Glib::UInt used
	 * to be misspelled as Glib::Uint.  by registering both names to the
	 * same gtype, we get the mappings for two packages to one gtype, but
	 * only one mapping (the last and correct one) from type to package.
	 */
	gperl_register_fundamental_alias (G_TYPE_UINT, "Glib::Uint");

	/* register custom GTypes that do not have a better home. */
	gperl_register_fundamental (GPERL_TYPE_SPAWN_FLAGS, "Glib::SpawnFlags");


=for apidoc
=for arg parent_class (package) type from which to derive
=for arg new_class (package) name of new type
=for arg ... arguments for creation
Register a new type with the GLib type system.

This is a traffic-cop function.  If I<$parent_type> derives from Glib::Object,
this passes the arguments through to C<register_object>.  If I<$parent_type>
is Glib::Flags or Glib::Enum, this strips I<$parent_type> and passes the
remaining args on to C<register_enum> or C<register_flags>.  See those
functions' documentation for more information.
=cut
void
g_type_register (class, const char * parent_class, new_class, ...)
    PREINIT:
	GType parent_type, base_type;
	char * sym;
	int n;
	SV ** oldargs;
    CODE:
	/*
	 * we originally had just Glib::Type::register, and it only did
	 * GObjects.  the name implies that it can do anything, so it
	 * should be able to.  to make the code managable we broke the
	 * actual work into separate functions, and do make the documentation
	 * intelligible, we made those helpers public.  this one, then,
	 * exists to retain backward compatibility, and acts as a traffic
	 * cop, farming out the work to the right helper function.
	 * 
	 * i had written this traffic cop in Glib.pm, but getting the pod
	 * to show up in Glib/Type.pod would've required a good amount of
	 * tear-up in Glib::ParseXSDoc.  So, here it is as an xsub.
	 */

	parent_type = gperl_type_from_package (parent_class);
	if (!parent_type)
		croak ("package %s is not registered with the GLib type system",
		       parent_class);

	base_type = G_TYPE_FUNDAMENTAL (parent_type);
	switch (base_type) {
	    case G_TYPE_OBJECT: sym = "Glib::Type::register_object"; break;
	    case G_TYPE_ENUM:   sym = "Glib::Type::register_enum";   break;
	    case G_TYPE_FLAGS:  sym = "Glib::Type::register_flags";  break;

	    default:
		croak ("sorry, don't know how to derive from a %s in Perl",
		       g_type_name (base_type));
	}
	/*
	 * because we need to strip an arg from the stack for register_enum
	 * and register_flags, we can't just call_* right here.
	 */
	oldargs = & ST (0);
	n = items - 3;
	{
		gint i;
		ENTER;
		SAVETMPS;
		PUSHMARK (SP);
		EXTEND (SP, 3+n);
		PUSHs (oldargs[0]);
		if (base_type == G_TYPE_OBJECT)
			PUSHs (oldargs[1]);
		PUSHs (oldargs[2]);
		for (i = 0 ; i < n ; i++)
			PUSHs (oldargs[3+i]);
		PUTBACK;
		call_method (sym, G_VOID);
		SPAGAIN;
		FREETMPS;
		LEAVE;
	}
	


=for apidoc

=arg parent_package () name of the parent package, which must be a derivative of Glib::Object.

=arg new_package usually __PACKAGE__.

=for arg ... (list) key/value pairs controlling how the class is created.

Register I<new_package> as an officially GLib-sanctioned derivative of
the (GObject derivative) I<parent_package>.  This automatically sets up
an @ISA entry for you, and creates a new GObjectClass under the hood.

The I<...> parameters are key/value pairs, currently supporting:

=over

=item signals => HASHREF

The C<signals> key contains a hash, keyed by signal names, which describes
how to set up the signals for I<new_package>.

If the value is a code reference, the named signal must exist somewhere in
I<parent_package> or its ancestry; the code reference will be used to 
override the class closure for that signal.  This is the officially sanctioned
way to override virtual methods on Glib::Objects.  The value may be a string
rather than a code reference, in which case the sub with that name in 
I<new_package> will be used.  (The function should not be inherited.)

If the value is a hash reference, the key will be the name of a new signal
created with the properties defined in the hash.  All of the properties
are optional, with defaults provided:

=over

=item class_closure => subroutine or undef

Use this code reference (or sub name) as the class closure (that is, the 
default handler for the signal).  If not specified, "do_I<signal_name>",
in the current package, is used.

=item return_type => package name or undef

Return type for the signal.  If not specified, then the signal has void return.

=item param_types => ARRAYREF

Reference to a list of parameter types (package names), I<omitting the instance
and user data>.  Callbacks connected to this signal will receive the instance
object as the first argument, followed by arguments with the types listed here,
and finally by any user data that was supplied when the callback was connected.
Not specifying this key is equivalent to supplying an empty list, which
actually means instance and maybe data.

=item flags => Glib::SignalFlags

Flags describing this signal's properties. See the GObject C API reference'
description of GSignalFlags for a complete description.

=item accumulator => subroutine or undef

The signal accumulator is a special callback that can be used to collect return
values of the various callbacks that are called during a signal emission.
Generally, you can omit this parameter; custom accumulators are used to do
things like stopping signal propagation by return value or creating a list of
returns, etc.  See L<Glib::Object::Subclass/SIGNALS> for details.

=back

=item properties => ARRAYREF

Array of Glib::ParamSpec objects, each describing an object property to add
to the new type.  These properties are available for use by all code that
can access the object, regardless of implementation language.  See
L<Glib::ParamSpec>.  This list may be empty; if it is not, the functions
C<GET_PROPERTY> and C<SET_PROPERTY> in I<$new_package> will be called to
get and set the values.  Note that an object property is just a mechanism
for getting and setting a value -- it implies no storage.  As a convenience,
however, Glib::Object provides fallbacks for GET_PROPERTY and SET_PROPERTY
which use the property nicknames as hash keys in the object variable for
storage.

Additionally, you may specify ParamSpecs as a describing hash instead of
as an object; this form allows you to supply explicit getter and setter
methods which override GET_PROPERY and SET_PROPERTY.  The getter and setter
are both optional in the hash form.  For example:

   Glib::Type->register_object ('Glib::Object', 'Foo',
      properties => [
         # specified normally
         Glib::ParamSpec->string (...),
         # specified explicitly
         {
            pspec => Glib::ParamSpec->int (...),
            set => sub {
               my ($object, $newval) = @_;
               ...
            },
            get => sub {
               my ($object) = @_;
               ...
               return $val;
            },
         },
      ]
   );

You can mix the two declaration styles as you like.  If you have
individual C<get_foo> / C<set_foo> methods with the operative code for
a property then the C<get>/C<set> form is a handy way to go straight
to that.

=item interfaces => ARRAYREF

Array of interface package names that the new object implements.  Interfaces
are the GObject way of doing multiple inheritance, thus, in Perl, the package
names will be prepended to @ISA and certain inheritable and overrideable
ALLCAPS methods will automatically be called whenever needed.  Which methods
exactly depends on the interface -- Gtk2::CellEditable for example uses
START_EDITING, EDITING_DONE, and REMOVE_WIDGET.

=back

=cut
void
g_type_register_object (class, parent_package, new_package, ...);
	char * parent_package
	char * new_package
    PREINIT:
	int i;
	GTypeInfo type_info;
	GPerlClassData class_data;
	GTypeQuery query;
	GType parent_type, new_type;
	char * new_type_name;
    CODE:
	/* start with a clean slate */
	memset (&type_info, 0, sizeof (GTypeInfo));
	memset (&class_data, 0, sizeof (GPerlClassData));
	type_info.base_init = (GBaseInitFunc) gperl_type_base_init;
	type_info.class_init = (GClassInitFunc) gperl_type_class_init;
	type_info.instance_init = (GInstanceInitFunc) gperl_type_instance_init;
	type_info.class_data = &class_data;

	/* yeah, i could just call gperl_object_type_from_package directly,
	 * but i want the error messages to be more informative. */
	parent_type = gperl_type_from_package (parent_package);
	if (!parent_type)
		croak ("package %s has not been registered with GPerl",
		       parent_package);
	if (!g_type_is_a (parent_type, G_TYPE_OBJECT))
		croak ("%s (%s) is not a descendent of Glib::Object (GObject)",
		       parent_package, g_type_name (parent_type));

	/* ask the type system for the missing values */
	g_type_query (parent_type, &query);
	type_info.class_size = query.class_size;
	type_info.instance_size = query.instance_size;

	/* and now register with the gtype system */
	/* mangle the name to remove illegal characters */
	new_type_name = sanitize_package_name (new_package);
	new_type = g_type_register_static (parent_type, new_type_name,
	                                   &type_info, 0);
#ifdef NOISY
	warn ("registered %s, son of %s nee %s(%d), as %s(%d)",
	      new_package, parent_package,
	      g_type_name (parent_type), parent_type,
	      new_type_name, new_type);
#endif
	g_free (new_type_name);

	/* and with the bindings */
	gperl_register_object (new_type, new_package);

	/* mark this type as "one of ours". */
	g_type_set_qdata (new_type, gperl_type_reg_quark (), (gpointer) TRUE);

	/* put it into the class data so that add_signals and add_properties
	 * can use it. */
	class_data.instance_type = new_type;

	/* now look for things we should initialize, e.g. signals and
	 * properties and interfaces.  put the corresponding data into the
	 * class_data struct.  the interfaces will be handled directly further
	 * below, while the properties and signals will be handled in the
	 * class_init function so that they have access to the class instance.
	 * this mimics the way things are supposed to be done in C: register
	 * interfaces in the get_type function, and register properties and
	 * signals in the class_init function. */
	for (i = 3 ; i < items ; i += 2) {
		char * key = SvPV_nolen (ST (i));
		if (strEQ (key, "signals")) {
			if (gperl_sv_is_hash_ref (ST (i+1)))
				class_data.signals = (HV*)SvRV (ST (i+1));
			else
				croak ("signals must be a hash of signalname => signalspec pairs");
		} else if (strEQ (key, "properties")) {
			if (gperl_sv_is_array_ref (ST (i+1)))
				class_data.properties = (AV*)SvRV (ST (i+1));
			else
				croak ("properties must be an array of GParamSpecs");
		} else if (strEQ (key, "interfaces")) {
			if (gperl_sv_is_array_ref (ST (i+1)))
				class_data.interfaces = (AV*)SvRV (ST (i+1));
			else
				croak ("interfaces must be an array of package names");
		}
	}

	/* add the interfaces to the type now before we create its class and
	 * enter the class_init function. */
	if (class_data.interfaces)
		add_interfaces (new_type, class_data.interfaces);

	/* instantiate the class right now.  perl doesn't let classes go
	 * away once they've been defined, so we'll just leak this ref and
	 * let the GObjectClass live as long as the program.  in fact,
	 * because we don't really have class_init handlers like C, we
	 * really don't want the class to die and be reinstantiated, because
	 * some of the setup (namely all the class setup we just did and
	 * the override installation coming up) will never happen
	 * again.
	 * this statement will cause an arbitrary amount of stuff to happen.
	 */
	g_type_class_ref (new_type); /* leak */
	
	/* vfuncs cause a bit of a problem, because the normal mechanisms of
	 * GObject don't give us a predefined way to handle them.  here we
	 * provide a way to override them in each child class as it is
	 * derived. */
	install_overrides (new_type);

	/* fin */


=for apidoc
=for arg name package name for new enum type
=for arg ... new enum's values; see description.
=for signature Glib::Type->register_enum ($name, ...)
Register and initialize a new Glib::Enum type with the provided "values".
This creates a type properly registered GLib so that it can be used for
property and signal parameter or return types created with
C<< Glib::Type->register >> or C<Glib::Object::Subclass>.

The list of values is used to create the "nicknames" that are used in general
Perl code; the actual numeric values used at the C level are automatically
assigned, starting with 1.  If you need to specify a particular numeric value
for a nick, use an array reference containing the nickname and the numeric
value, instead.  You may mix and match the two styles.

  Glib::Type->register_enum ('MyFoo::Bar',
          'value-one',            # assigned 1
          'value-two',            # assigned 2
          ['value-three' => 15 ], # explicit 15
          ['value-four' => 35 ],  # explicit 35
          'value-five',           # assigned 5
  );

If you use the array-ref form, beware: the code performs no validation
for unique values.
=cut
void
g_type_register_enum (class, name, ...)
	const char * name
    PREINIT:
	int           i = 0;
	char       *  ctype_name;
	SV         *  sv;
	SV         ** av2sv;
	GType         type;
	GEnumValue *  values = NULL;
    CODE:
	if (items-2 < 1)
		croak ("Usage: Glib::Type->register_enums (new_package, LIST)\n"
		       "   no values supplied");
	/*
	 * we create a value table on the fly, and we can't free it without
	 * causing problems.  the value table is stored in the type
	 * registration information, which conceivably may be called more
	 * than once per program (which is why we don't use a class_finalize
	 * to destroy it).  unfortunately, there doesn't appear to be a
	 * g_enum_register_dynamic().
	 * this means we will also leak the nickname strings, which must
	 * be duplicated to keep them alive (perl will reuse those strings).
	 *
	 * note also that we don't clean up very well when things go wrong.
	 * we build up the structure as we go, and an exception in the middle
	 * will leak everything done up to that point.  we could clean it up,
	 * but it will make things uglier than they already are, and if
	 * your script can't register the enums properly, it probably won't
	 * live much longer.
	 */
	values = g_new0 (GEnumValue, items-1); /* leak (see above) */
	for (i = 0; i < items-2; i++)
	{
		sv = (SV*)ST (i+2);
		/* default to the i based numbering */
		values[i].value = i + 1;
		if (gperl_sv_is_array_ref (sv))
		{
			/* [ name => value ] syntax */
			AV * av = (AV*)SvRV(sv);
			/* value_name */
			av2sv = av_fetch (av, 0, 0);
			if (av2sv && gperl_sv_is_defined (*av2sv))
				values[i].value_name = SvPV_nolen (*av2sv);
			else
				croak ("invalid enum name and value pair, no name provided");
			/* custom value */
			av2sv = av_fetch (av, 1, 0);
			if (av2sv && gperl_sv_is_defined (*av2sv))
				values[i].value = SvIV (*av2sv);
		}
		else if (gperl_sv_is_defined (sv))
		{
			/* name syntax */
			values[i].value_name = SvPV_nolen (sv);
		}
		else
			croak ("invalid type flag name");

		/* make sure that the nickname stays alive as long as the
		 * type is registered. */
		values[i].value_name = g_strdup (values[i].value_name);

		/* let the nick and name match.  there are few uses for the
		 * name, anyway. */
		values[i].value_nick = values[i].value_name;
	}
	ctype_name = sanitize_package_name (name);
	type = g_enum_register_static (ctype_name, values);
	gperl_register_fundamental (type, name);
	g_free (ctype_name);


=for apidoc
=for arg name package name of new flags type
=for arg ... flag values, see discussion.
=for signature Glib::Type->register_flags ($name, ...)
Register and initialize a new Glib::Flags type with the provided "values".
This creates a type properly registered GLib so that it can be used for
property and signal parameter or return types created with
C<< Glib::Type->register >> or C<Glib::Object::Subclass>.

The list of values is used to create the "nicknames" that are used in general
Perl code; the actual numeric values used at the C level are automatically
assigned, of the form 1<<i, starting with i = 0.  If you need to specify a
particular numeric value for a nick, use an array reference containing the
nickname and the numeric value, instead.  You may mix and match the two styles.

  Glib::Type->register_flags ('MyFoo::Baz',
           'value-one',               # assigned 1<<0
           'value-two',               # assigned 1<<1
           ['value-three' => 1<<10 ], # explicit 1<<10
           ['value-four' => 0x0f ],   # explicit 0x0f
           'value-five',              # assigned 1<<4
  );

If you use the array-ref form, beware: the code performs no validation
for unique values.
=cut
void
g_type_register_flags (class, name, ...)
	const char * name
    PREINIT:
	int           i = 0;
	char       *  ctype_name;
	SV         *  sv;
	SV         ** av2sv;
	GType          type;
	GFlagsValue *  values = NULL;
    CODE:
	if (items-2 < 1)
		croak ("Usage: Glib::Type->register_flags (new_package, LIST)\n"
		       "   no values supplied");
	/* see the notes about memory management in register_enums -- they
	 * all apply here.  we can't combine the implementations because
	 * GEnumValue and GFlagsValue are not typedefed together. */
	values = g_new0 (GFlagsValue, items-1);
	for (i = 0; i < items-2; i++)
	{
		sv = (SV*)ST (i+2);
		/* default to the i based numbering */
		values[i].value = 1 << i;
		if (gperl_sv_is_array_ref (sv))
		{
			/* [ name => value ] syntax */
			AV * av = (AV*)SvRV(sv);
			/* value_name */
			av2sv = av_fetch (av, 0, 0);
			if (av2sv && gperl_sv_is_defined (*av2sv))
				values[i].value_name = SvPV_nolen (*av2sv);
			else
				croak ("invalid flag name and value pair, no name provided");
			/* custom value */
			av2sv = av_fetch (av, 1, 0);
			if (av2sv && gperl_sv_is_defined (*av2sv))
				values[i].value = SvIV (*av2sv);
		}
		else if (gperl_sv_is_defined (sv))
		{
			/* name syntax */
			values[i].value_name = SvPV_nolen (sv);
		}
		else
			croak ("invalid type flag name");

		/* make sure that the nickname stays alive as long as the
		 * type is registered. */
		values[i].value_name = g_strdup (values[i].value_name);

		/* let the nick and name match.  there are few uses for the
		 * name, anyway. */
		values[i].value_nick = values[i].value_name;
	}
	ctype_name = sanitize_package_name (name);
	type = g_flags_register_static (ctype_name, values);
	gperl_register_fundamental (type, name);
	g_free (ctype_name);



=for apidoc

List the ancestry of I<package>, as seen by the GLib type system.  The
important difference is that GLib's type system implements only single
inheritance, whereas Perl's @ISA allows multiple inheritance.

This returns the package names of the ancestral types in reverse order, with
the root of the tree at the end of the list.

See also L<list_interfaces ()|/"list = Glib::Type-E<gt>B<list_interfaces> ($package)">.

=cut
void
list_ancestors (class, package)
	gchar * package
    PREINIT:
	GType        package_gtype;
	GType        parent_gtype;
	const char * pkg;
    PPCODE:
	package_gtype = gperl_type_from_package (package);
	XPUSHs (sv_2mortal (newSVpv (package, 0)));
	if (!package_gtype)
		croak ("%s is not registered with either GPerl or GLib",
		       package);
	parent_gtype = g_type_parent (package_gtype);
	while (parent_gtype)
	{
		pkg = gperl_package_from_type (parent_gtype);
		if (!pkg)
			croak("problem looking up parent package name, "
			      "gtype %lu", parent_gtype);
		XPUSHs (sv_2mortal (newSVpv (pkg, 0)));
		parent_gtype = g_type_parent (parent_gtype);
	}


=for apidoc

List the GInterfaces implemented by the type associated with I<package>.
The interfaces are returned as package names.

=cut
void
list_interfaces (class, package)
	gchar * package
    PREINIT:
	int     i;
	GType   package_gtype;
	GType * interfaces;
    PPCODE:
	package_gtype = gperl_type_from_package (package);
	if (!package_gtype)
		croak ("%s is not registered with either GPerl or GLib",
		       package);
	interfaces = g_type_interfaces (package_gtype, NULL);
	if (!interfaces)
		XSRETURN_EMPTY;
	for (i = 0; interfaces[i] != 0; i++) {
		const char * name = gperl_package_from_type (interfaces[i]);
		if (!name) {
			/* this is usually a sign that the bindings are
			 * missing something.  let's print a warning to make
			 * this easier to find. */
			name = g_type_name (interfaces[i]);
			warn ("GInterface %s is not registered with GPerl",
			      name);
		}
		XPUSHs (sv_2mortal (newSVpv (name, 0)));
	}
	g_free (interfaces);


=for apidoc

List the signals associated with I<package>.  This lists only the signals
for I<package>, not any of its parents.  The signals are returned as a list
of anonymous hashes which mirror the GSignalQuery structure defined in the
C API reference.

=over

=item - signal_id

Numeric id of a signal.  It's rare that you'll need this in Gtk2-Perl.

=item - signal_name

Name of the signal, such as what you'd pass to C<signal_connect>.

=item - itype

The I<i>nstance I<type> for which this signal is defined.

=item - signal_flags

GSignalFlags describing this signal.

=item - return_type

The return type expected from handlers for this signal.  If undef or not
present, then no return is expected.  The type name is mapped to the 
corresponding Perl package name if it is known, otherwise you get the
raw C name straight from GLib.

=item - param_types

The types of the parameters passed to any callbacks connected to the emission
of this signal.  The list does not include the instance, which is always
first, and the user data from C<signal_connect>, which is always last (unless
the signal was connected with "swap", which swaps the instance and the data,
but you get the point).

=back

=cut
void
list_signals (class, package)
	gchar * package
    PREINIT:
	guint          i, num;
	guint        * sigids;
	GType          package_type;
	GSignalQuery   siginfo;
	GObjectClass * oclass = NULL;
    PPCODE:
	package_type = gperl_type_from_package (package);
	if (!package_type)
		croak ("%s is not registered with either GPerl or GLib",
		       package);

	if (!G_TYPE_IS_INSTANTIATABLE(package_type) &&
	    !G_TYPE_IS_INTERFACE (package_type))
		XSRETURN_EMPTY;
	if (G_TYPE_IS_CLASSED (package_type)) {
		/* ref the class to ensure that the signals get created. */
		oclass = g_type_class_ref (package_type);
		if (!oclass)
			XSRETURN_EMPTY;
	}
	sigids = g_signal_list_ids (package_type, &num);
	if (!num)
		XSRETURN_EMPTY;
	EXTEND(SP, (int) num);
	for (i = 0; i < num; i++) {
		g_signal_query (sigids[i], &siginfo);
		PUSHs (sv_2mortal (newSVGSignalQuery (&siginfo)));
	}
	if (oclass)
		g_type_class_unref (oclass);


=for apidoc

List the legal values for the GEnum or GFlags type I<$package>.  If I<$package>
is not a package name registered with the bindings, this name is passed on to
g_type_from_name() to see if it's a registered flags or enum type that just
hasn't been registered with the bindings by C<gperl_register_fundamental()>
(see Glib::xsapi).  If I<$package> is not the name of an enum or flags type,
this function will croak.

Returns the values as a list of hashes, one hash for each value, containing
the value, name and nickname, eg. for Glib::SignalFlags

    { value => 8,
      name  => 'G_SIGNAL_NO_RECURSE',
      nick  => 'no-recurse'
    }

=cut
void
list_values (class, const char * package)
    PREINIT:
	GType type;
    PPCODE:
	type = gperl_fundamental_type_from_package (package);
	if (!type)
		type = g_type_from_name (package);
	if (!type)
		croak ("%s is not registered with either GPerl or GLib",
		       package);
	/*
	 * GFlagsValue and GEnumValue are nearly the same, but differ in
	 * that GFlagsValue is a guint for the value, but GEnumValue is gint
	 * (and some enums do indeed use negatives, eg. GtkResponseType).
	 */
	if (G_TYPE_IS_ENUM (type)) {
		GEnumValue * v = gperl_type_enum_get_values (type);
		for ( ; v && v->value_nick && v->value_name ; v++) {
			HV * hv = newHV ();
			gperl_hv_take_sv_s (hv, "value", newSViv (v->value));
			gperl_hv_take_sv_s (hv, "nick", newSVpv (v->value_nick, 0));
			gperl_hv_take_sv_s (hv, "name", newSVpv (v->value_name, 0));
			XPUSHs (sv_2mortal (newRV_noinc ((SV*)hv)));
		}
	} else if (G_TYPE_IS_FLAGS (type)) {
		GFlagsValue * v = gperl_type_flags_get_values (type);
		for ( ; v && v->value_nick && v->value_name ; v++) {
			HV * hv = newHV ();
			gperl_hv_take_sv_s (hv, "value", newSVuv (v->value));
			gperl_hv_take_sv_s (hv, "nick", newSVpv (v->value_nick, 0));
			gperl_hv_take_sv_s (hv, "name", newSVpv (v->value_name, 0));
			XPUSHs (sv_2mortal (newRV_noinc ((SV*)hv)));
		}
	} else {
		croak ("%s is neither enum nor flags type", package);
	}


=for apidoc

Convert a C type name to the corresponding Perl package name.  If no package
is registered to that type, returns I<$cname>. 

=cut
const char *
package_from_cname (class, const char * cname)
    PREINIT:
	GType gtype;
    CODE:
	gtype = g_type_from_name (cname);
	if (!gtype) {
		croak ("%s is not registered with the GLib type system",
		       cname);
		RETVAL = cname;
	} else {
		RETVAL = gperl_package_from_type (gtype);
		if (!RETVAL)
			RETVAL = cname;
	}
    OUTPUT:
	RETVAL

MODULE = Glib::Type	PACKAGE = Glib::Flags

=for object Glib::Flags methods and overloaded operators for flags

=for position DESCRIPTION

=head1 DESCRIPTION

Glib maps flag and enum values to the nicknames strings provided by the
underlying C libraries.  Representing flags this way in Perl is an interesting
problem, which Glib solves by using some cool overloaded operators. 

The functions described here actually do the work of those overloaded
operators.  See the description of the flags operators in the "This Is
Now That" section of L<Glib> for more info.

=cut

=for apidoc
Create a new flags object with given bits.  This is for use from a
subclass, it's not possible to create a C<Glib::Flags> object as such.
For example,

    my $f1 = Glib::ParamFlags->new ('readable');
    my $f2 = Glib::ParamFlags->new (['readable','writable']);

An object like this can then be used with the overloaded operators.
=cut
SV *
new (const char *class, SV *a)
    PREINIT:
	GType gtype;
    CODE:
	gtype = gperl_fundamental_type_from_package (class);
	if (! gtype || ! g_type_is_a (gtype, G_TYPE_FLAGS)) {
		croak ("package %s is not registered with the GLib type system "
		       "as a flags type",
		       class);
	}
	if (gtype == G_TYPE_FLAGS) {
		croak ("cannot create Glib::Flags (only subclasses)");
	}
	RETVAL = gperl_convert_back_flags
			(gtype, gperl_convert_flags (gtype, a));
    OUTPUT:
	RETVAL

=for apidoc
=for signature bool = $f->bool
=for arg ... (__hide__)
Return 1 if any bits are set in $f, or 0 if none are set.  This is the
overload for $f in boolean context (like C<if>, etc).  You can call it
as a method to get a true/false directly too.
=cut
int
bool (SV *f, ...)
    PROTOTYPE: $;@
    CODE:
	RETVAL = !!gperl_convert_flags (
		     gperl_fundamental_type_from_obj (f),
		     f
		   );
    OUTPUT:
	RETVAL

=for apidoc
=for signature aref = $f->as_arrayref
=for arg ... (__hide__)
Return the bits of $f as a reference to an array of strings, like
['flagbit1','flagbit2'].  This is the overload function for C<@{}>,
ie. arrayizing $f.  You can call it directly as a method too.

Note that @$f gives the bits as a list, but as_arrayref gives an arrayref.
If an arrayref is what you want then the method style
somefunc()->as_arrayref can be more readable than [@{somefunc()}].
=cut
SV *
as_arrayref (SV *f, ...)
    PROTOTYPE: $;@
    CODE:
{
	/* overload @{} calls here with the usual three args "a,b,swap", but
	 * "b" and "swap" have no meaning.  Using "..." to ignore them lets
	 * users call method-style with no args "$f->as_arrayref" too.
	 */
	GType gtype;
	gint f_;

	gtype = gperl_fundamental_type_from_obj (f);
	f_ = gperl_convert_flags (gtype, f);

	RETVAL = flags_as_arrayref (gtype, f_);
}
    OUTPUT:
	RETVAL

int
eq (SV *a, SV *b, int swap)
    ALIAS:
	ne = 1
	ge = 2

    CODE:
{
	GType gtype;
	gint a_, b_;

	gtype = gperl_fundamental_type_from_obj (a);
	a_ = gperl_convert_flags (gtype, swap ? b : a);
	b_ = gperl_convert_flags (gtype, swap ? a : b);

	RETVAL = FALSE;
	switch (ix) {
	  case 0: RETVAL = a_ == b_; break;
	  case 1: RETVAL = a_ != b_; break;
	  case 2: RETVAL = (a_ & b_) == b_; break;
	}
}
    OUTPUT:
	RETVAL

SV *
union (SV *a, SV *b, SV *swap)
    ALIAS:
	sub = 1
	intersect = 2
	xor = 3
	all = 4
    CODE:
{
	GType gtype;
	gint a_, b_;

	gtype = gperl_fundamental_type_from_obj (a);
	a_ = gperl_convert_flags (gtype, SvTRUE (swap) ? b : a);
	b_ = gperl_convert_flags (gtype, SvTRUE (swap) ? a : b);

	switch (ix) {
	  case 0: a_ |= b_; break;
	  case 1: a_ &=~b_; break;
	  case 2: a_ &= b_; break;
	  case 3: a_ ^= b_; break;
	}

	RETVAL = gperl_convert_back_flags (gtype, a_);
}
    OUTPUT:
	RETVAL

