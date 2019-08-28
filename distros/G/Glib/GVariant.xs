/*
 * Copyright (C) 2014 by the gtk2-perl team (see the file AUTHORS for the full
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
 */

#include "gperl.h"

/* --- GVariant --------------------------------------------------------------*/

/* --- basic wrappers --- */

static SV *
variant_to_sv (GVariant * variant, gboolean own)
{
	SV * sv;
	SV * rv;
	HV * stash;

	if (!variant)
		return &PL_sv_undef;

	sv = newSV (0);
	_gperl_attach_mg (sv, variant);

	if (own) {
#if GLIB_CHECK_VERSION (2, 30, 0)
		g_variant_take_ref (variant);
#elif GLIB_CHECK_VERSION (2, 26, 0)
		if (g_variant_is_floating (variant)) {
			g_variant_ref_sink (variant);
		}
#else
		/* In this case, we have no way of finding out whether the
		 * variant has a floating ref, so we just always ref_sink even
		 * if this might cause a leak in some cases. */
		g_variant_ref_sink (variant);
#endif
	} else {
		g_variant_ref (variant);
	}

	rv = newRV_noinc (sv);
	stash = gv_stashpv ("Glib::Variant", TRUE);
	sv_bless (rv, stash);

	return rv;
}

static GVariant *
sv_to_variant (SV * sv)
{
	MAGIC * mg;
	if (!gperl_sv_is_ref (sv) || !(mg = _gperl_find_mg (SvRV (sv))))
		return NULL;
	return (GVariant *) mg->mg_ptr;
}

/* --- GValue wrappers --- */

static SV *
wrap_variant (const GValue * value)
{
	return variant_to_sv (g_value_get_variant (value), FALSE);
}

static void
unwrap_variant (GValue * value, SV * sv)
{
	g_value_set_variant (value, sv_to_variant (sv));
}

static GPerlValueWrapperClass variant_wrapper_class = { wrap_variant, unwrap_variant };

/* --- typemap glue --- */

SV *
newSVGVariant (GVariant * variant)
{
	return variant_to_sv (variant, FALSE);
}

SV *
newSVGVariant_noinc (GVariant * variant)
{
	return variant_to_sv (variant, TRUE);
}

GVariant *
SvGVariant (SV * sv)
{
	return sv_to_variant (sv);
}

/* --- GVariantType --------------------------------------------------------- */

/* --- boxed wrappers ---*/

static GPerlBoxedWrapperClass default_boxed_wrapper_class;
static GPerlBoxedWrapperClass variant_type_wrapper_class;

static gpointer
unwrap_variant_type (GType gtype, const char * package, SV * sv)
{
	if (!gperl_sv_is_ref (sv)) {
		GVariantType * vtype;
		vtype = g_variant_type_new (SvPV_nolen (sv));
		sv = default_boxed_wrapper_class.wrap (gtype, package, vtype, TRUE);
		/* fall through */
	}
	return default_boxed_wrapper_class.unwrap (gtype, package, sv);
}

/* --- typemap glue --- */

SV *
newSVGVariantType (const GVariantType * type)
{
	if (!type)
		return &PL_sv_undef;
	return gperl_new_boxed ((gpointer) type, G_TYPE_VARIANT_TYPE, FALSE);
}

SV *
newSVGVariantType_own (const GVariantType * type)
{
	return gperl_new_boxed ((gpointer) type, G_TYPE_VARIANT_TYPE, TRUE);
}

const GVariantType *
SvGVariantType (SV * sv)
{
	if (!gperl_sv_is_defined (sv))
		return NULL;
	return gperl_get_boxed_check (sv, G_TYPE_VARIANT_TYPE);
}

/* --- GVariantDict ----------------------------------------------------------*/

#if GLIB_CHECK_VERSION (2, 40, 0)

/* --- typemap glue --- */

SV *
newSVGVariantDict (GVariantDict * dict)
{
	return gperl_new_boxed (dict, G_TYPE_VARIANT_DICT, FALSE);
}

SV *
newSVGVariantDict_own (GVariantDict * dict)
{
	return gperl_new_boxed (dict, G_TYPE_VARIANT_DICT, TRUE);
}

GVariantDict *
SvGVariantDict (SV * sv)
{
	if (!gperl_sv_is_defined (sv))
		return NULL;
	return gperl_get_boxed_check (sv, G_TYPE_VARIANT_DICT);
}

#endif

/* -------------------------------------------------------------------------- */

/* --- helpers ---*/

static void
sv_to_variant_array (SV * sv, GVariant *** array_p, gsize * n_p)
{
	AV * av;
	gsize i;
	if (!gperl_sv_is_array_ref (sv))
		croak ("Expected an array reference for 'children'");
	av = (AV *) SvRV (sv);
	*n_p = av_len (av) + 1;
	*array_p = g_new0 (GVariant *, *n_p);
	for (i = 0; i < *n_p; i++) {
		SV ** svp = av_fetch (av, i, 0);
		if (svp)
			(*array_p)[i] = SvGVariant (*svp);
	}
}

static void
sv_to_variant_type_array (SV * sv, const GVariantType *** array_p, gint * n_p)
{
	AV * av;
	gint i;
	if (!gperl_sv_is_array_ref (sv))
		croak ("Expected an array reference for 'items'");
	av = (AV *) SvRV (sv);
	*n_p = av_len (av) + 1;
	*array_p = g_new0 (const GVariantType *, *n_p);
	for (i = 0; i < *n_p; i++) {
		SV ** svp = av_fetch (av, i, 0);
		if (svp)
			(*array_p)[i] = SvGVariantType (*svp);
	}
}

/* -------------------------------------------------------------------------- */

MODULE = Glib::Variant	PACKAGE = Glib::Variant	PREFIX = g_variant_

=for object Glib::Variant strongly typed value datatype
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  my $v = Glib::Variant->new ('as', ['GTK+', 'Perl']);
  my $aref = $v->get ('as');

=for position DESCRIPTION

=head1 DESCRIPTION

There are two sets of APIs for creating and dealing with C<Glib::Variant>s: the
low-level API described below under L</METHODS>, and the convenience API
described in this section.

=head2 CONVENIENCE API

=over

=item variant = Glib::Variant->new ($format_string, $value)

=item (variant1, ...) = Glib::Variant->new ($format_string, $value1, ...)

Constructs a variant from C<$format_string> and C<$value>.  Also supports
constructing multiple variants when the format string is a concatenation of
multiple types.

=item value = $variant->get ($format_string)

Deconstructs C<$variant> according to C<$format_string>.

=back

The following symbols are currently supported in format strings:

  +------------------------------+---------------------------------+
  |            Symbol            |             Meaning             |
  +------------------------------+---------------------------------+
  | b, y, n, q, i, u, x, t, h, d | Boolean, byte and numeric types |
  | s, o, g                      | String types                    |
  | v                            | Variant types                   |
  | a                            | Arrays                          |
  | m                            | Maybe types                     |
  | ()                           | Tuples                          |
  | {}                           | Dictionary entries              |
  +------------------------------+---------------------------------+

Note that if a format string specifies an array, a tuple or a dictionary entry
("a", "()" or "{}"), then array references are expected by C<new> and produced
by C<get>.  For arrays of dictionary entries ("a{}"), hash references are also
supported by C<new> and handled as you would expect.

For a complete specification, see the documentation at

=over

=item L<https://developer.gnome.org/glib/stable/glib-GVariantType.html>

=item L<https://developer.gnome.org/glib/stable/glib-GVariant.html>

=item L<https://developer.gnome.org/glib/stable/gvariant-format-strings.html>

=item L<https://developer.gnome.org/glib/stable/gvariant-text.html>

=back

=cut

=for see_also Glib::VariantType
=cut

=for see_also Glib::VariantDict
=cut

BOOT:
	gperl_register_fundamental_full (G_TYPE_VARIANT, "Glib::Variant",
	                                 &variant_wrapper_class);
	default_boxed_wrapper_class = variant_type_wrapper_class =
		* gperl_default_boxed_wrapper_class ();
	variant_type_wrapper_class.unwrap = unwrap_variant_type;
	gperl_register_boxed (G_TYPE_VARIANT_TYPE, "Glib::VariantType",
	                      &variant_type_wrapper_class);
#if GLIB_CHECK_VERSION (2, 40, 0)
	gperl_register_boxed (G_TYPE_VARIANT_DICT, "Glib::VariantDict", NULL);
#endif

const GVariantType * g_variant_get_type (GVariant *value);

const gchar * g_variant_get_type_string (GVariant *value);

gboolean g_variant_is_of_type (GVariant *value, const GVariantType *type);

gboolean g_variant_is_container (GVariant *value);

char g_variant_classify (GVariant *value);

GVariant_noinc * g_variant_new_boolean (class, gboolean value);
    C_ARGS:
	value

GVariant_noinc * g_variant_new_byte (class, guchar value);
    C_ARGS:
	value

GVariant_noinc * g_variant_new_int16 (class, gint16 value);
    C_ARGS:
	value

GVariant_noinc * g_variant_new_uint16 (class, guint16 value);
    C_ARGS:
	value

GVariant_noinc * g_variant_new_int32 (class, gint32 value);
    C_ARGS:
	value

GVariant_noinc * g_variant_new_uint32 (class, guint32 value);
    C_ARGS:
	value

GVariant_noinc * g_variant_new_int64 (class, gint64 value);
    C_ARGS:
	value

GVariant_noinc * g_variant_new_uint64 (class, guint64 value);
    C_ARGS:
	value

GVariant_noinc * g_variant_new_handle (class, gint32 value);
    C_ARGS:
	value

GVariant_noinc * g_variant_new_double (class, gdouble value);
    C_ARGS:
	value

# GVariant * g_variant_new_take_string (gchar *string);
GVariant_noinc * g_variant_new_string (class, const gchar *string);
    C_ARGS:
	string

# FIXME:
# GLIB_AVAILABLE_IN_2_38
# GVariant * g_variant_new_printf (const gchar *format_string, ...) G_GNUC_PRINTF (1, 2);

GVariant_noinc * g_variant_new_object_path (class, const gchar *object_path);
    C_ARGS:
	object_path

gboolean g_variant_is_object_path (const gchar *string);

GVariant_noinc * g_variant_new_signature (class, const gchar *signature);
    C_ARGS:
	signature

gboolean g_variant_is_signature (const gchar *string);

GVariant_noinc * g_variant_new_variant (class, GVariant *value);
    C_ARGS:
	value

# FIXME:
# GVariant * g_variant_new_strv (const gchar * const *strv, gssize length);

# FIXME:
# GLIB_AVAILABLE_IN_2_30
# GVariant * g_variant_new_objv (const gchar * const *strv, gssize length);

#if GLIB_CHECK_VERSION (2, 26, 0)

GVariant_noinc * g_variant_new_bytestring (class, const char_byte * string);
    C_ARGS:
	string

# FIXME:
# GVariant * g_variant_new_bytestring_array (const gchar * const *strv, gssize length);

#endif

# FIXME:
# GLIB_AVAILABLE_IN_2_32
# GVariant * g_variant_new_fixed_array (const GVariantType *element_type, gconstpointer elements, gsize n_elements, gsize element_size);

# FIXME:
# GLIB_AVAILABLE_IN_2_36
# GVariant * g_variant_new_from_bytes (const GVariantType *type, GBytes *bytes, gboolean trusted);

# FIXME:
# GVariant * g_variant_new_from_data (const GVariantType *type, gconstpointer data, gsize size, gboolean trusted, GDestroyNotify notify, gpointer user_data);

gboolean g_variant_get_boolean (GVariant *value);

guchar g_variant_get_byte (GVariant *value);

gint16 g_variant_get_int16 (GVariant *value);

guint16 g_variant_get_uint16 (GVariant *value);

gint32 g_variant_get_int32 (GVariant *value);

guint32 g_variant_get_uint32 (GVariant *value);

gint64 g_variant_get_int64 (GVariant *value);

guint64 g_variant_get_uint64 (GVariant *value);

gint32 g_variant_get_handle (GVariant *value);

gdouble g_variant_get_double (GVariant *value);

GVariant_noinc * g_variant_get_variant (GVariant *value);

# gchar * g_variant_dup_string (GVariant *value, gsize *length);
const gchar * g_variant_get_string (GVariant *value);
    C_ARGS:
	value, NULL

# FIXME:
# gchar ** g_variant_dup_strv (GVariant *value, gsize *length);
# const gchar ** g_variant_get_strv (GVariant *value, gsize *length);

# FIXME:
# GLIB_AVAILABLE_IN_2_30
# gchar ** g_variant_dup_objv (GVariant *value, gsize *length);
# const gchar ** g_variant_get_objv (GVariant *value, gsize *length);

#if GLIB_CHECK_VERSION (2, 26, 0)

# gchar * g_variant_dup_bytestring (GVariant *value, gsize *length);
const char * g_variant_get_bytestring (GVariant *value);

# FIXME:
# gchar ** g_variant_dup_bytestring_array (GVariant *value, gsize *length);
# const gchar ** g_variant_get_bytestring_array (GVariant *value, gsize *length);

#endif

GVariant_noinc * g_variant_new_maybe (class, const GVariantType *child_type, GVariant *child);
    C_ARGS:
	child_type, child

GVariant * g_variant_new_array (class, const GVariantType *child_type, SV *children);
    PREINIT:
	GVariant ** children_c;
	gsize n_children;
    CODE:
	sv_to_variant_array (children, &children_c, &n_children);
	RETVAL = g_variant_new_array (child_type, children_c, n_children);
	g_free (children_c);
    OUTPUT:
	RETVAL

GVariant * g_variant_new_tuple (class, SV *children);
    PREINIT:
	GVariant ** children_c;
	gsize n_children;
    CODE:
	sv_to_variant_array (children, &children_c, &n_children);
	RETVAL = g_variant_new_tuple (children_c, n_children);
	g_free (children_c);
    OUTPUT:
	RETVAL

GVariant_noinc * g_variant_new_dict_entry (class, GVariant *key, GVariant *value);
    C_ARGS:
	key, value

GVariant_noinc * g_variant_get_maybe (GVariant *value);

gsize g_variant_n_children (GVariant *value);

# void g_variant_get_child (GVariant *value, gsize index_, const gchar *format_string, ...);

GVariant_noinc * g_variant_get_child_value (GVariant *value, gsize index_);

#if GLIB_CHECK_VERSION (2, 28, 0)

# gboolean g_variant_lookup (GVariant *dictionary, const gchar *key, const gchar *format_string, ...);
GVariant_noinc * g_variant_lookup_value (GVariant *dictionary, const gchar *key, const GVariantType *expected_type);

#endif

# FIXME:
# gconstpointer g_variant_get_fixed_array (GVariant *value, gsize *n_elements, gsize element_size);

gsize g_variant_get_size (GVariant *value);

# FIXME:
# gconstpointer g_variant_get_data (GVariant *value);
# GLIB_AVAILABLE_IN_2_36
# GBytes * g_variant_get_data_as_bytes (GVariant *value);
# void g_variant_store (GVariant *value, gpointer data);

# GString * g_variant_print_string (GVariant *value, GString *string, gboolean type_annotate);
gchar_own * g_variant_print (GVariant *value, gboolean type_annotate);

guint g_variant_hash (const GVariant * value);

gboolean g_variant_equal (const GVariant * one, const GVariant * two);

#if GLIB_CHECK_VERSION (2, 26, 0)

gint g_variant_compare (const GVariant * one, const GVariant * two);

#endif

GVariant_noinc * g_variant_get_normal_form (GVariant *value);

gboolean g_variant_is_normal_form (GVariant *value);

GVariant_noinc * g_variant_byteswap (GVariant *value);

# FIXME:
# GLIB_AVAILABLE_IN_2_36
# GVariant * g_variant_new_from_bytes (const GVariantType *type, GBytes *bytes, gboolean trusted);

# FIXME:
# GVariant * g_variant_new_from_data (const GVariantType *type, gconstpointer data, gsize size, gboolean trusted, GDestroyNotify notify, gpointer user_data);

void
DESTROY (GVariant * variant)
    CODE:
	g_variant_unref (variant);

# --------------------------------------------------------------------------- #

# GVariantIter * g_variant_iter_new (GVariant *value);
# gsize g_variant_iter_init (GVariantIter *iter, GVariant *value);
# GVariantIter * g_variant_iter_copy (GVariantIter *iter);
# gsize g_variant_iter_n_children (GVariantIter *iter);
# void g_variant_iter_free (GVariantIter *iter);
# GVariant * g_variant_iter_next_value (GVariantIter *iter);
# gboolean g_variant_iter_next (GVariantIter *iter, const gchar *format_string, ...);
# gboolean g_variant_iter_loop (GVariantIter *iter, const gchar *format_string, ...);

# --------------------------------------------------------------------------- #

# GVariantBuilder * g_variant_builder_new (const GVariantType *type);
# void g_variant_builder_unref (GVariantBuilder *builder);
# GVariantBuilder * g_variant_builder_ref (GVariantBuilder *builder);
# void g_variant_builder_init (GVariantBuilder *builder, const GVariantType *type);
# GVariant * g_variant_builder_end (GVariantBuilder *builder);
# void g_variant_builder_clear (GVariantBuilder *builder);
# void g_variant_builder_open (GVariantBuilder *builder, const GVariantType *type);
# void g_variant_builder_close (GVariantBuilder *builder);
# void g_variant_builder_add_value (GVariantBuilder *builder, GVariant *value);
# void g_variant_builder_add (GVariantBuilder *builder, const gchar *format_string, ...);
# void g_variant_builder_add_parsed (GVariantBuilder *builder, const gchar *format, ...);

# --------------------------------------------------------------------------- #

# These are re-created in lib/Glib.pm.
# GVariant * g_variant_new (const gchar *format_string, ...);
# GVariant * g_variant_new_va (const gchar *format_string, const gchar **endptr, va_list *app);
# void g_variant_get (GVariant *value, const gchar *format_string, ...);
# void g_variant_get_va (GVariant *value, const gchar *format_string, const gchar **endptr, va_list *app);
# GLIB_AVAILABLE_IN_2_34
# gboolean g_variant_check_format_string (GVariant *value, const gchar *format_string, gboolean copy_only);

# --------------------------------------------------------------------------- #

=for apidoc __function__ __gerror__
=cut
GVariant_noinc *
g_variant_parse (const GVariantType *type, const gchar *text)
    PREINIT:
	GError *error = NULL;
    CODE:
	RETVAL = g_variant_parse (type, text, NULL, NULL, &error);
	if (error)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

# GVariant * g_variant_new_parsed (const gchar *format, ...);
# GVariant * g_variant_new_parsed_va (const gchar *format, va_list *app);
# GLIB_AVAILABLE_IN_2_40
# gchar * g_variant_parse_error_print_context (GError *error, const gchar *source_str);

# --------------------------------------------------------------------------- #

MODULE = Glib::Variant	PACKAGE = Glib::VariantType	PREFIX = g_variant_type_

=for object Glib::VariantType Utilities for dealing with the GVariant type system
=cut

=for see_also Glib::Variant
=cut

=for apidoc __function__
=cut
gboolean g_variant_type_string_is_valid (const gchar *type_string);

=for apidoc
=for signature (type_string, rest) = Glib::VariantType::string_scan ($string)
Scans the start of C<$string> for a complete type string and extracts it.  If
no type string can be found, an exception is thrown.
=cut
# gboolean g_variant_type_string_scan (const gchar *string, const gchar *limit, const gchar **endptr);
void
g_variant_type_string_scan (const char *string)
    PREINIT:
	const char *limit = NULL;
	const char *endptr = NULL;
    PPCODE:
	if (!g_variant_type_string_scan (string, limit, &endptr))
		croak ("Could not find type string at the start of '%s'",
		       string);
	PUSHs (sv_2mortal (newSVpvn (string, endptr-string)));
        if (endptr && *endptr)
        	XPUSHs (sv_2mortal (newSVpv (endptr, 0)));

GVariantType_own * g_variant_type_new (class, const gchar *type_string);
    C_ARGS:
	type_string

# const gchar * g_variant_type_peek_string (const GVariantType *type);
# gchar * g_variant_type_dup_string (const GVariantType  *type);
SV * g_variant_type_get_string (const GVariantType *type)
    PREINIT:
	const char * string;
    CODE:
	string = g_variant_type_peek_string (type);
	RETVAL = newSVpv (string, g_variant_type_get_string_length (type));
    OUTPUT:
	RETVAL

gboolean g_variant_type_is_definite (const GVariantType *type);

gboolean g_variant_type_is_container (const GVariantType *type);

gboolean g_variant_type_is_basic (const GVariantType *type);

gboolean g_variant_type_is_maybe (const GVariantType *type);

gboolean g_variant_type_is_array (const GVariantType *type);

gboolean g_variant_type_is_tuple (const GVariantType *type);

gboolean g_variant_type_is_dict_entry (const GVariantType *type);

gboolean g_variant_type_is_variant (const GVariantType *type);

guint g_variant_type_hash (const GVariantType *type);

gboolean g_variant_type_equal (const GVariantType *type1, const GVariantType *type2);

gboolean g_variant_type_is_subtype_of (const GVariantType *type, const GVariantType *supertype);

const GVariantType * g_variant_type_element (const GVariantType *type);

const GVariantType * g_variant_type_first (const GVariantType *type);

const GVariantType * g_variant_type_next (const GVariantType *type);

gsize g_variant_type_n_items (const GVariantType *type);

const GVariantType * g_variant_type_key (const GVariantType *type);

const GVariantType * g_variant_type_value (const GVariantType *type);

GVariantType_own * g_variant_type_new_array (class, const GVariantType *element);
    C_ARGS:
	element

GVariantType_own * g_variant_type_new_maybe (class, const GVariantType *element);
    C_ARGS:
	element

GVariantType_own * g_variant_type_new_tuple (class, SV *items);
    PREINIT:
	const GVariantType ** items_c;
	gint n_items;
    CODE:
	sv_to_variant_type_array (items, &items_c, &n_items);
	RETVAL = g_variant_type_new_tuple (items_c, n_items);
	g_free (items_c);
    OUTPUT:
	RETVAL

GVariantType_own * g_variant_type_new_dict_entry (class, const GVariantType *key, const GVariantType *value);
    C_ARGS:
	key, value

# --------------------------------------------------------------------------- #

#if GLIB_CHECK_VERSION (2, 40, 0)

MODULE = Glib::Variant	PACKAGE = Glib::VariantDict	PREFIX = g_variant_dict_

=for object Glib::VariantDict Utilities for dealing with the GVariantDict mutable interface to GVariant dictionaries
=cut

=for see_also Glib::Variant
=cut

GVariantDict_own * g_variant_dict_new (class, GVariant *from_asv);
    C_ARGS:
	from_asv

# gboolean g_variant_dict_lookup (GVariantDict *dict, const gchar *key, const gchar *format_string, ...);
GVariant_noinc * g_variant_dict_lookup_value (GVariantDict *dict, const gchar *key, const GVariantType *expected_type);

gboolean g_variant_dict_contains (GVariantDict *dict, const gchar *key);

# void g_variant_dict_insert (GVariantDict *dict, const gchar *key, const gchar *format_string, ...);
void g_variant_dict_insert_value (GVariantDict *dict, const gchar *key, GVariant *value);

gboolean g_variant_dict_remove (GVariantDict *dict, const gchar *key);

GVariant_noinc * g_variant_dict_end (GVariantDict *dict);

#endif
