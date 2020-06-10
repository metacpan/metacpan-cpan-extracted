/*
 * Copyright (c) 2005-2009, 2013 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gperl.h"
#include "gperl-gtypes.h"

/* ------------------------------------------------------------------------- */

/* This hash table is used to store option groups that have been handed to
 * GOptionContext.
 */
static GHashTable *transferred_groups = NULL;

static GOptionGroup *
gperl_option_group_transfer (GOptionGroup *group)
{
	if (!transferred_groups)
		transferred_groups =
			g_hash_table_new (g_direct_hash, g_direct_equal);

	g_hash_table_insert (transferred_groups, group, group);

	return group;
}

/* ------------------------------------------------------------------------- */

/* Define custom types for GOptionContext, GOptionGroup, GOptionFlags, and
 * GOptionArg since glib doesn't provide them.
 */

static gpointer
no_copy_for_you (gpointer boxed)
{
	croak ("copying Glib::OptionContext and Glib::OptionGroup isn't supported");
	return boxed;
}

/* glib assumes ownership of option groups it gets, and there's no copy
 * function.  So we need a custom free function here that checks if the group
 * was transferred to glib already before freeing it.
 */
static void
gperl_option_group_free (GOptionGroup *group)
{
        G_GNUC_BEGIN_IGNORE_DEPRECATIONS
	if (!g_hash_table_lookup (transferred_groups, group))
		g_option_group_free (group);
        G_GNUC_END_IGNORE_DEPRECATIONS
}

GType
gperl_option_context_get_type (void)
{
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static ("GOptionContext",
		      (GBoxedCopyFunc) no_copy_for_you,
		      (GBoxedFreeFunc) g_option_context_free);
	return t;
}

GType
gperl_option_group_get_type (void)
{
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static ("GOptionGroup",
		      (GBoxedCopyFunc) no_copy_for_you,
		      (GBoxedFreeFunc) gperl_option_group_free);
	return t;
}

/* ------------------------------------------------------------------------- */

#if 0
static SV *
newSVGOptionFlags (GOptionFlags flags)
{
	return gperl_convert_back_flags (GPERL_TYPE_OPTION_FLAGS, flags);
}
#endif

static GOptionFlags
SvGOptionFlags (SV *sv)
{
	return gperl_convert_flags (GPERL_TYPE_OPTION_FLAGS, sv);
}

/* ------------------------------------------------------------------------- */

#if 0
static SV *
newSVGOptionArg (GOptionArg arg)
{
	return gperl_convert_back_enum (GPERL_TYPE_OPTION_ARG, arg);
}
#endif

static GOptionArg
SvGOptionArg (SV *sv)
{
	return gperl_convert_enum (GPERL_TYPE_OPTION_ARG, sv);
}

/* ------------------------------------------------------------------------- */

typedef struct {
	GOptionArg arg;
	gpointer   arg_data;
} GPerlArgInfo;

static GPerlArgInfo *
gperl_arg_info_new (GOptionArg arg, gpointer arg_data)
{
	GPerlArgInfo *info = g_new0 (GPerlArgInfo, 1);
	info->arg = arg;
	info->arg_data = arg_data;
	return info;
}

static void
gperl_arg_info_destroy (GPerlArgInfo *info)
{
	g_free (info->arg_data); /* NULL-safe */
	g_free (info);
}

typedef struct {
	GHashTable *scalar_to_info;
	GSList *allocated_strings;
} GPerlArgInfoTable;

static GPerlArgInfoTable *
gperl_arg_info_table_new (void)
{
	GPerlArgInfoTable *table = g_new0 (GPerlArgInfoTable, 1);
	table->scalar_to_info =
		g_hash_table_new_full (g_direct_hash,
				       g_direct_equal,
				       NULL,
		      (GDestroyNotify) gperl_arg_info_destroy);
	table->allocated_strings = NULL;
	return table;
}

static void
free_element (gpointer element, gpointer user_data)
{
	PERL_UNUSED_VAR (user_data);
	g_free (element);
}

static void
gperl_arg_info_table_destroy (GPerlArgInfoTable *table)
{
	g_hash_table_destroy (table->scalar_to_info);

	/* These are NULL-safe. */
	g_slist_foreach (table->allocated_strings, free_element, NULL);
	g_slist_free (table->allocated_strings);

	g_free (table);
}

/* ------------------------------------------------------------------------- */

#define INSTALL_POINTER(type)						\
{									\
	type *pointer = g_new0 (type, 1);				\
	g_hash_table_insert (scalar_to_info, 				\
			     ref,					\
			     gperl_arg_info_new (entry->arg, pointer));	\
	entry->arg_data = pointer;					\
}

static void
handle_arg_data (GOptionEntry *entry, SV *ref, GHashTable *scalar_to_info)
{
	if (!gperl_sv_is_ref (ref))
		croak ("encountered non-reference variable for the arg_value "
		       "field");

	switch (entry->arg) {
	    case G_OPTION_ARG_NONE:
		INSTALL_POINTER (gboolean);
		break;

	    case G_OPTION_ARG_STRING:
	    case G_OPTION_ARG_FILENAME:
	        INSTALL_POINTER (gchar *);
		break;

	    case G_OPTION_ARG_INT:
	        INSTALL_POINTER (gint);
		break;

	    case G_OPTION_ARG_CALLBACK:
		croak ("unhandled arg type G_OPTION_ARG_CALLBACK encountered");
		break;

	    case G_OPTION_ARG_STRING_ARRAY:
	    case G_OPTION_ARG_FILENAME_ARRAY:
	        INSTALL_POINTER (gchar **);
		break;

#if GLIB_CHECK_VERSION (2, 12, 0)
	    case G_OPTION_ARG_DOUBLE:
	        INSTALL_POINTER (gdouble);
		break;

	    case G_OPTION_ARG_INT64:
	        INSTALL_POINTER (gint64);
		break;
#endif
	}
}

static gchar *
copy_string (gchar *src, GPerlArgInfoTable *table)
{
	gchar *result;
	if (!src)
		return NULL;
	result = g_strdup (src);
	table->allocated_strings =
		g_slist_prepend (table->allocated_strings, result);
	return result;
}

static GOptionEntry *
sv_to_option_entry (SV *sv, GPerlArgInfoTable *table)
{
	SV *long_name = NULL,
	   *short_name = NULL,
	   *flags = NULL,
	   *description = NULL,
	   *arg_description = NULL,
	   *arg_type = NULL,
	   *arg_value = NULL;
	GOptionEntry *entry;

	if (!gperl_sv_is_hash_ref (sv) && !gperl_sv_is_array_ref (sv))
		croak ("an option entry must be either a hash or an array "
		       "reference");

	if (gperl_sv_is_hash_ref (sv)) {
		HV *hv = (HV *) SvRV (sv);
		SV **value;

		value = hv_fetch (hv, "long_name", 9, 0);
		if (value) long_name = *value;

		value = hv_fetch (hv, "short_name", 10, 0);
		if (value) short_name = *value;

		value = hv_fetch (hv, "flags", 5, 0);
		if (value) flags = *value;

		value = hv_fetch (hv, "description", 11, 0);
		if (value) description = *value;

		value = hv_fetch (hv, "arg_description", 15, 0);
		if (value) arg_description = *value;

		value = hv_fetch (hv, "arg_type", 8, 0);
		if (value) arg_type = *value;

		value = hv_fetch (hv, "arg_value", 9, 0);
		if (value) arg_value = *value;
	} else {
		AV *av = (AV *) SvRV (sv);
		SV **value;

		if (4 != av_len (av) + 1)
			croak ("an option entry array reference must contain "
			       "four values: long_name, short_name, arg_type, "
			       "and arg_value");

		value = av_fetch (av, 0, 0);
		if (value) long_name = *value;

		value = av_fetch (av, 1, 0);
		if (value) short_name = *value;

		value = av_fetch (av, 2, 0);
		if (value) arg_type = *value;

		value = av_fetch (av, 3, 0);
		if (value) arg_value = *value;
	}

	if (!gperl_sv_is_defined (long_name) ||
	    !gperl_sv_is_defined (arg_type) ||
	    !gperl_sv_is_defined (arg_value))
		croak ("in an option entry, the fields long_name, arg_type, and "
		       "arg_value must be specified");

	entry = gperl_alloc_temp (sizeof (GOptionEntry));

	entry->long_name       = copy_string (SvGChar (long_name), table);
	entry->arg             = SvGOptionArg (arg_type);
	entry->arg_data        = NULL;
	handle_arg_data (entry, arg_value, table->scalar_to_info);

	entry->short_name      = gperl_sv_is_defined (short_name)
	                       ? (SvGChar (short_name))[0]
	                       : 0;
	entry->flags           = gperl_sv_is_defined (flags)
	                       ? SvGOptionFlags (flags)
                               : 0;
	entry->description     = gperl_sv_is_defined (description)
	                       ? copy_string (SvGChar (description), table)
	                       : NULL;
	entry->arg_description = gperl_sv_is_defined (arg_description)
	                       ? copy_string (SvGChar (arg_description), table)
	                       : NULL;

	return entry;
}

static GOptionEntry *
sv_to_option_entries (SV *sv, GPerlArgInfoTable *table)
{
	GOptionEntry *entries;
	AV *av;
	int length, i;
	SV **value;

	if (!gperl_sv_is_array_ref (sv))
		croak ("option entries must be an array reference containing hash references");

	av = (AV *) SvRV (sv);
	length = av_len (av) + 1;

	/* Allocating length + 1 entries here because the list is supposed to
	 * be NULL-terminated. */
	entries = gperl_alloc_temp (sizeof (GOptionEntry) * (length + 1));

	for (i = 0; i < length; i++) {
		value = av_fetch (av, i, 0);
		if (value && gperl_sv_is_defined (*value))
			entries[i] = *(sv_to_option_entry (*value, table));
	}

	return entries;
}

/* ------------------------------------------------------------------------- */

static gchar **
strings_from_sv (SV *sv)
{
	AV *av;
	gint n_strings, i;
	gchar **result;

	if (!gperl_sv_is_array_ref (sv))
		return NULL;

	av = (AV *) SvRV (sv);
	n_strings = av_len (av) + 1;
	if (n_strings <= 0)
		return NULL;

	/* NULL-terminated */
	result = gperl_alloc_temp (sizeof (gchar *) * (n_strings + 1));
	for (i = 0; i < n_strings; i++) {
		SV **string_sv = av_fetch (av, i, 0);
		result[i] = string_sv ? SvGChar (*string_sv) : NULL;
	}

	return result;
}

static gchar **
filenames_from_sv (SV *sv)
{
	AV *av;
	gint n_filenames, i;
	gchar **result;

	if (!gperl_sv_is_array_ref (sv))
		return NULL;

	av = (AV *) SvRV (sv);
	n_filenames = av_len (av) + 1;
	if (n_filenames <= 0)
		return NULL;

	/* NULL-terminated */
	result = gperl_alloc_temp (sizeof (gchar *) * (n_filenames + 1));
	for (i = 0; i < n_filenames; i++) {
		SV **string_sv = av_fetch (av, i, 0);
		result[i] = string_sv ? SvPV_nolen (*string_sv) : NULL;
	}

	return result;
}

#define INITIALIZE_POINTER(type, converter)			\
{								\
	SV *sv = SvRV (ref);					\
	if (gperl_sv_is_defined (sv))				\
		*((type *) info->arg_data) = converter (sv);	\
}

static void
initialize_scalar (gpointer key,
		   gpointer value,
		   gpointer data)
{
	SV *ref = key;
	GPerlArgInfo *info = value;
	PERL_UNUSED_VAR (data);

	switch (info->arg) {
	    case G_OPTION_ARG_NONE:
		INITIALIZE_POINTER (gboolean, sv_2bool);
		break;

	    case G_OPTION_ARG_STRING:
		INITIALIZE_POINTER (gchar *, SvGChar);
		break;

	    case G_OPTION_ARG_INT:
		INITIALIZE_POINTER (gint, SvIV);
		break;

	    case G_OPTION_ARG_CALLBACK:
		croak ("unhandled arg type G_OPTION_ARG_CALLBACK encountered");
		break;

	    case G_OPTION_ARG_FILENAME:
		/* FIXME: Is this the correct converter? */
		INITIALIZE_POINTER (gchar *, SvPV_nolen);
		break;

	    case G_OPTION_ARG_STRING_ARRAY:
		INITIALIZE_POINTER (gchar **, strings_from_sv);
		break;

	    case G_OPTION_ARG_FILENAME_ARRAY:
		INITIALIZE_POINTER (gchar **, filenames_from_sv);
		break;

#if GLIB_CHECK_VERSION (2, 12, 0)
	    case G_OPTION_ARG_DOUBLE:
		INITIALIZE_POINTER (gdouble, SvNV);
		break;

	    case G_OPTION_ARG_INT64:
		INITIALIZE_POINTER (gint64, SvGInt64);
		break;
#endif
	}
}

static gboolean
initialize_scalars (GOptionContext *context,
		    GOptionGroup *group,
		    gpointer data,
		    GError **error)
{
	GPerlArgInfoTable *table = data;
	PERL_UNUSED_VAR (context);
	PERL_UNUSED_VAR (group);
	PERL_UNUSED_VAR (error);
	g_hash_table_foreach (table->scalar_to_info, initialize_scalar, NULL);
	return TRUE;
}

/* ------------------------------------------------------------------------- */

static SV *
sv_from_strings (gchar **strings)
{
	AV *av;
	gint i;

	if (!strings)
		return &PL_sv_undef;

	av = newAV ();
	for (i = 0; strings[i] != NULL; i++) {
		av_push (av, newSVGChar (strings[i]));
	}

	return newRV_noinc ((SV *) av);
}

static SV *
sv_from_filenames (gchar **filenames)
{
	AV *av;
	gint i;

	if (!filenames)
		return &PL_sv_undef;

	av = newAV ();
	for (i = 0; filenames[i] != NULL; i++) {
		/* FIXME: Is this the correct converter? */
		av_push (av, newSVpv (filenames[i], 0));
	}

	return newRV_noinc ((SV *) av);
}

#define READ_POINTER(type) (*((type *) info->arg_data))

static void
fill_in_scalar (gpointer key,
	        gpointer value,
		gpointer data)
{
	SV *ref = key;
	GPerlArgInfo *info = value;
	SV *sv = SvRV (ref);
	PERL_UNUSED_VAR (data);

	switch (info->arg) {
	    case G_OPTION_ARG_NONE:
		sv_setsv (sv, boolSV (READ_POINTER (gboolean)));
		break;

	    case G_OPTION_ARG_STRING:
		sv_setpv (sv, READ_POINTER (gchar *));
		SvUTF8_on (sv);
		break;

	    case G_OPTION_ARG_INT:
	        sv_setiv (sv, READ_POINTER (gint));
		break;

	    case G_OPTION_ARG_CALLBACK:
		croak ("unhandled arg type G_OPTION_ARG_CALLBACK encountered");
		break;

	    case G_OPTION_ARG_FILENAME:
		/* FIXME: Is this the correct converter? */
		sv_setpv (sv, READ_POINTER (gchar *));
		break;

	    case G_OPTION_ARG_STRING_ARRAY:
		sv_setsv (sv, sv_from_strings (READ_POINTER (gchar **)));
		break;

	    case G_OPTION_ARG_FILENAME_ARRAY:
		sv_setsv (sv, sv_from_filenames (READ_POINTER (gchar **)));
		break;

#if GLIB_CHECK_VERSION (2, 12, 0)
	    case G_OPTION_ARG_DOUBLE:
	        sv_setnv (sv, READ_POINTER (gdouble));
		break;

	    case G_OPTION_ARG_INT64:
		sv_setsv (sv, newSVGInt64 (READ_POINTER (gint64)));
		break;
#endif
	}
}

static gboolean
fill_in_scalars (GOptionContext *context,
		 GOptionGroup *group,
		 gpointer data,
		 GError **error)
{
	GPerlArgInfoTable *table = data;
	PERL_UNUSED_VAR (context);
	PERL_UNUSED_VAR (group);
	PERL_UNUSED_VAR (error);
	g_hash_table_foreach (table->scalar_to_info, fill_in_scalar, NULL);
	return TRUE;
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
gperl_translate_func_create (SV *func, SV *data)
{
	GType param_types [1];
	param_types[0] = G_TYPE_STRING;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_STRING);
}

static const gchar *
gperl_translate_func (const gchar *str, gpointer data)
{
	GPerlCallback *callback = (GPerlCallback *) data;
	GValue value = {0,};
	const gchar *retval;

	/* FIXME: This leaks but I've no idea how to make sure the string
         * survives. */
	g_value_init (&value, callback->return_type);
	gperl_callback_invoke (callback, &value, str);
	retval = g_value_dup_string (&value);
	g_value_unset (&value);

	return retval;
}

/* ------------------------------------------------------------------------- */

MODULE = Glib::Option	PACKAGE = Glib::OptionContext	PREFIX = g_option_context_

BOOT:
	gperl_register_boxed (GPERL_TYPE_OPTION_CONTEXT, "Glib::OptionContext", NULL);
	gperl_register_boxed (GPERL_TYPE_OPTION_GROUP, "Glib::OptionGroup", NULL);
	gperl_register_fundamental (GPERL_TYPE_OPTION_ARG, "Glib::OptionArg");
	gperl_register_fundamental (GPERL_TYPE_OPTION_FLAGS, "Glib::OptionFlags");

=for object Glib::OptionContext defines options accepted by the commandline option parser

=cut

=for object Glib::OptionGroup group of options for command line option parsing

=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  my ($verbose, $source, $filenames) = ('', undef, []);

  my $entries = [
    { long_name => 'verbose',
      short_name => 'v',
      arg_type => 'none',
      arg_value => \$verbose,
      description => 'be verbose' },

    { long_name => 'source',
      short_name => 's',
      arg_type => 'string',
      arg_value => \$source,
      description => 'set the source',
      arg_description => 'source' },

    [ 'filenames', 'f', 'filename-array', \$filenames ],
  ];

  my $context = Glib::OptionContext->new ('- urgsify your life');
  $context->add_main_entries ($entries, 'C');
  $context->parse ();

  # $verbose, $source, and $filenames are now updated according to the
  # command line options given

=cut

##  GOptionContext * g_option_context_new (const gchar *parameter_string);
GOptionContext_own *
g_option_context_new (class, parameter_string);
	const gchar *parameter_string
    C_ARGS:
	parameter_string

void g_option_context_set_help_enabled (GOptionContext *context, gboolean help_enabled);

gboolean g_option_context_get_help_enabled (GOptionContext *context);

void g_option_context_set_ignore_unknown_options (GOptionContext *context, gboolean ignore_unknown);

gboolean g_option_context_get_ignore_unknown_options (GOptionContext *context);

# void g_option_context_add_main_entries (GOptionContext *context, const GOptionEntry *entries, const gchar *translation_domain);
=for signature
=arg entries reference to an array of option entries
=cut
void
g_option_context_add_main_entries (GOptionContext *context, SV *entries, const gchar *translation_domain)
    PREINIT:
	GPerlArgInfoTable *table;
	GOptionGroup *group;
	GOptionEntry *real_entries;
    CODE:
	table = gperl_arg_info_table_new ();
	group = g_option_group_new (NULL, NULL, NULL,
				    table,
		   (GDestroyNotify) gperl_arg_info_table_destroy);
	g_option_group_set_parse_hooks (group, initialize_scalars,
	                                fill_in_scalars);

	real_entries = sv_to_option_entries (entries, table);
	if (real_entries)
		g_option_group_add_entries (group, real_entries);
	g_option_group_set_translation_domain (group, translation_domain);

	/* context assumes ownership of group */
	g_option_context_set_main_group (context, group);

##  gboolean g_option_context_parse (GOptionContext *context, gint *argc, gchar ***argv, GError **error);
=for apidoc __gerror__
This method works directly on I<@ARGV>.
=cut
gboolean
g_option_context_parse (context)
	GOptionContext *context
    PREINIT:
	GPerlArgv *pargv;
	GError *error = NULL;
    CODE:
	pargv = gperl_argv_new ();
	RETVAL = g_option_context_parse (context, &pargv->argc, &pargv->argv, &error);

	if (error) {
		gperl_argv_free (pargv);
		gperl_croak_gerror (NULL, error);
	}

	gperl_argv_update (pargv);
	gperl_argv_free (pargv);
    OUTPUT:
	RETVAL

# Groups that belong to a context will be destroyed when that context goes
# away, so we need to mark the group to ensure it doesn't get freed by our
# boxed wrappers.

##  void g_option_context_add_group (GOptionContext *context, GOptionGroup *group);
void
g_option_context_add_group (context, group)
	GOptionContext *context
	GOptionGroup *group
    C_ARGS:
	context, gperl_option_group_transfer (group)

##  void g_option_context_set_main_group (GOptionContext *context, GOptionGroup *group);
void
g_option_context_set_main_group (context, group);
	GOptionContext *context
	GOptionGroup *group
    C_ARGS:
	context, gperl_option_group_transfer (group)

GOptionGroup * g_option_context_get_main_group (GOptionContext *context);

# --------------------------------------------------------------------------- #

MODULE = Glib::Option	PACKAGE = Glib::OptionGroup	PREFIX = g_option_group_

=for enum Glib::OptionFlags
=cut

=for enum Glib::OptionArg
=cut

##  GOptionGroup * g_option_group_new (const gchar *name, const gchar *description, const gchar *help_description, gpointer user_data, GDestroyNotify destroy);
##  void g_option_group_add_entries (GOptionGroup *group, const GOptionEntry *entries);
##  void g_option_group_set_parse_hooks (GOptionGroup *group, GOptionParseFunc pre_parse_func, GOptionParseFunc post_parse_func);
##  void g_option_group_set_error_hook (GOptionGroup *group, GOptionErrorFunc error_func);
=for apidoc
=for signature optiongroup = Glib::OptionGroup->new (key => value, ...)
=for arg ... (__hide__)

Creates a new option group from the given key-value pairs.  The valid keys are
name, description, help_description, and entries.  The first three specify
strings while the last one, entries, specifies an array reference of option
entries.  Example:

  my $group = Glib::OptionGroup->new (
                name => 'urgs',
                description => 'Urgs Urgs Urgs',
                help_description => 'Help with Urgs',
                entries => \@entries);

An option entry is a hash reference like this:

  { long_name => 'verbose',
    short_name => 'v',
    flags => [qw/reverse hidden in-main/],
    arg_type => 'none',
    arg_value => \$verbose,
    description => 'verbose desc.',
    arg_description => 'verbose arg desc.' }

Of those keys only long_name, arg_type, and arg_value are required.  So this is
a valid option entry too:

  { long_name => 'package-names',
    arg_type => 'string-array',
    arg_value => \$package_names }

For convenience, option entries can also be specified as array references
containing long_name, short_name, arg_type, and arg_value:

  [ 'filenames', 'f', 'filename-array', \$filenames ]

If you don't want an option to have a short name, specify undef for it:

  [ 'filenames', undef, 'filename-array', \$filenames ]

=cut
GOptionGroup_own *
g_option_group_new (class, ...)
    PREINIT:
	int i;
	gchar *name = NULL;
	gchar *description = NULL;
	gchar *help_description = NULL;
	SV *entries = NULL;
	GPerlArgInfoTable *table;
	GOptionEntry *real_entries = NULL;
    CODE:
	if ((items - 1) % 2 != 0)
		croak ("even number of arguments expected: key => value, ...");

	for (i = 1; i < items; i += 2) {
		char *key = SvPV_nolen (ST (i));
		SV *value = ST (i + 1);

		if (strEQ (key, "name"))
			name = SvGChar (value);
		else if (strEQ (key, "description"))
			description = SvGChar (value);
		else if (strEQ (key, "help_description"))
			help_description = SvGChar (value);
		else if (strEQ (key, "entries"))
			entries = value;
		else
			warn ("unknown key `%s´ encountered; ignoring", key);
	}

	table = gperl_arg_info_table_new ();
	if (entries)
		real_entries = sv_to_option_entries (entries, table);

	RETVAL = g_option_group_new (name,
				     description,
				     help_description,
				     table,
		    (GDestroyNotify) gperl_arg_info_table_destroy);

	g_option_group_set_parse_hooks (RETVAL, initialize_scalars, fill_in_scalars);

	if (real_entries)
		g_option_group_add_entries (RETVAL, real_entries);
    OUTPUT:
	RETVAL

##  void g_option_group_set_translate_func (GOptionGroup *group, GTranslateFunc func, gpointer data, GDestroyNotify destroy_notify);
void
g_option_group_set_translate_func (group, func, data=NULL);
	GOptionGroup *group
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = gperl_translate_func_create (func, data);
	g_option_group_set_translate_func (group,
	                                   gperl_translate_func,
	                                   callback,
	                                   (GDestroyNotify)
	                                     gperl_callback_destroy);

void g_option_group_set_translation_domain (GOptionGroup *group, const gchar *domain);
