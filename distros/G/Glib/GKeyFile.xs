/*
 * Copyright (C) 2005,2013 by the gtk2-perl team (see the file AUTHORS for
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
 */

#include "gperl.h"
#include "gperl-gtypes.h"

SV *
newSVGKeyFileFlags (GKeyFileFlags flags)
{
	return gperl_convert_back_flags (GPERL_TYPE_KEY_FILE_FLAGS, flags);
}

GKeyFileFlags
SvGKeyFileFlags (SV * sv)
{
	return gperl_convert_flags (GPERL_TYPE_KEY_FILE_FLAGS, sv);
}

SV *
newSVGKeyFile (GKeyFile * key_file)
{
	HV * key = newHV ();
	SV * sv;
	HV * stash;

	/* tie the key_file to our hash using some magic */
	_gperl_attach_mg ((SV*) key, key_file);

	/* wrap it, bless it, ship it. */
	sv = newRV_noinc ((SV*) key);

	stash = gv_stashpv ("Glib::KeyFile", TRUE);
	sv_bless (sv, stash);

	return sv;
}

GKeyFile *
SvGKeyFile (SV * sv)
{
	MAGIC * mg;
	if (!gperl_sv_is_ref (sv) || !(mg = _gperl_find_mg (SvRV (sv))))
		return NULL;
	return (GKeyFile *) mg->mg_ptr;
}

MODULE = Glib::KeyFile	PACKAGE = Glib::KeyFile	PREFIX = g_key_file_

=for object Glib::KeyFile Parser for .ini-like files
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  use Glib;

  $data .= $_ while (<DATA>);

  $f = Glib::KeyFile->new;
  $f->load_from_data($data);
  if ($f->has_group('Main') && $f->has_key('Main', 'someotherkey')) {
      $val = $f->get_integer('Main', 'someotherkey');
      print $val . "\n";
  }
  0;
  __DATA__
  # a comment
  [MainSection]
  somekey=somevalue
  someotherkey=42
  someboolkey=true
  listkey=1;1;2;3;5;8;13;21
  localekey=Good Morning
  localekey[it]=Buon giorno
  localekey[es]=Buenas dias
  localekey[fr]=Bonjour

=for position DESCRIPTION

=head1 DESCRIPTION

B<Glib::KeyFile> lets you parse, edit or create files containing groups of
key-value pairs, which we call key files for lack of a better name. Several
freedesktop.org specifications use key files now, e.g the Desktop Entry
Specification and the Icon Theme Specification.

The syntax of key files is described in detail in the Desktop Entry
Specification, here is a quick summary: Key files consists of groups of
key-value pairs, interspersed with comments.

=cut

BOOT:
	gperl_register_fundamental (GPERL_TYPE_KEY_FILE_FLAGS,
				    "Glib::KeyFileFlags");

void
DESTROY (GKeyFile * key_file)
    CODE:
    	g_key_file_free (key_file);

GKeyFile*
g_key_file_new (class)
    C_ARGS:
    	/* void */

# unneded
#void      g_key_file_free                   (GKeyFile             *key_file);

=for apidoc
Sets the list separator character.
=cut
void
g_key_file_set_list_separator (key_file, separator)
	GKeyFile * key_file
	gchar separator

=for enum Glib::KeyFileFlags
=cut

=for apidoc __gerror__
Parses a key file.
=cut
gboolean
g_key_file_load_from_file (key_file, file, flags)
	GKeyFile * key_file
	const gchar * file
	GKeyFileFlags flags
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = g_key_file_load_from_file (key_file, file, flags, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc __gerror__
Parses a string containing a key file structure.
=cut
gboolean
g_key_file_load_from_data (key_file, buf, flags)
	GKeyFile * key_file
	SV * buf
	GKeyFileFlags flags
    PREINIT:
	STRLEN length;
	GError *err = NULL;
	const gchar *data = (const gchar *) SvPV (buf, length);
    CODE:
	RETVAL = g_key_file_load_from_data (key_file, data, length, flags, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

#if GLIB_CHECK_VERSION (2, 14, 0)

=for apidoc __gerror__
=signature boolean = $key_file->load_from_dirs ($file, $flags, @search_dirs)
=signature (boolean, scalar) = $key_file->load_from_dirs ($file, $flags, @search_dirs)

Parses a key file, searching for it inside the specified directories.
In scalar context, it returns a boolean value (true on success, false otherwise);
in array context, it returns a boolean value and the full path of the file.
=cut
void
g_key_file_load_from_dirs (key_file, file, flags, ...)
	GKeyFile *key_file
	const gchar *file
	GKeyFileFlags flags
    PREINIT:
	int n_dirs, i;
	gchar **search_dirs;
	gchar *full_path = NULL;
	GError *error = NULL;
	gboolean retval;
    PPCODE:
	n_dirs = items - 3;
	search_dirs = g_new0 (gchar*, n_dirs + 1);
	for (i = 0; i < n_dirs; i++) {
		search_dirs[i] = SvGChar (ST (3 + i));
	}
	search_dirs[n_dirs] = NULL;

	retval = g_key_file_load_from_dirs (
			key_file,
			file,
			(const gchar **) search_dirs,
			&full_path,
			flags,
			&error);

	if (error)
		gperl_croak_gerror (NULL, error);

	PUSHs (sv_2mortal (newSVuv (retval)));
	if (GIMME_V == G_ARRAY && full_path)
		XPUSHs (sv_2mortal (newSVGChar (full_path)));

	if (full_path)
		g_free (full_path);

	g_free (search_dirs);

#endif

=for apidoc __gerror__
=signature boolean = $key_file->load_from_data_dirs ($file, $flags)
=signature (boolean, scalar) = $key_file->load_from_data_dirs ($file, $flags)

Parses a key file, searching for it inside the data directories.
In scalar context, it returns a boolean value (true on success, false otherwise);
in array context, it returns a boolean value and the full path of the file.
=cut
void
g_key_file_load_from_data_dirs (key_file, file, flags)
	GKeyFile * key_file
	const gchar * file
	GKeyFileFlags flags
    PREINIT:
    	GError *err = NULL;
	gchar *full_path = NULL;
	gboolean retval;
    PPCODE:
    	retval = g_key_file_load_from_data_dirs (key_file,
			file,
			GIMME_V == G_ARRAY ? &full_path : NULL,
			flags,
			&err);
	if (err)
		gperl_croak_gerror (NULL, err);
	PUSHs (sv_2mortal (newSViv (retval)));
	if (GIMME_V == G_ARRAY && full_path)
		XPUSHs (sv_2mortal (newSVGChar (full_path)));
	if (full_path) g_free (full_path);

=for apidoc __gerror__
Returns the key file as a string.
=cut
gchar_own *
g_key_file_to_data (key_file)
	GKeyFile * key_file
    PREINIT:
    	GError *err = NULL;
	gsize len;
    CODE:
    	RETVAL = g_key_file_to_data (key_file, &len, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc
Returns the first group inside a key file.
=cut
gchar_own *
g_key_file_get_start_group (key_file)
	GKeyFile * key_file

=for apidoc
=signature list = $key_file->get_groups
Returns the list of groups inside the key_file.
=cut
void
g_key_file_get_groups (key_file)
	GKeyFile * key_file
    PREINIT:
    	gchar **groups;
	gsize len, i;
    PPCODE:
    	groups = g_key_file_get_groups (key_file, &len);
	if (len != 0) {
		EXTEND(SP, (long) len);
		for (i = 0; i < len; i++)
			PUSHs (sv_2mortal (newSVGChar (groups[i])));
	}
	g_strfreev (groups); /* otherwise, we leak */

=for apidoc __gerror__
=signature list = $key_file->get_keys ($group_name)
Returns the list of keys inside a group of the key file.
=cut
void
g_key_file_get_keys (key_file, group_name)
	GKeyFile * key_file
	const gchar * group_name
    PREINIT:
    	GError *err = NULL;
    	gchar **keys;
	gsize len, i;
    PPCODE:
    	keys = g_key_file_get_keys (key_file, group_name, &len, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
	if (len != 0) {
		for (i = 0; i < len; i++)
			if (keys[i])
				XPUSHs (sv_2mortal (newSVGChar (keys[i])));
	}
	g_strfreev (keys); /* otherwise, we leak */

=for apidoc
Checks whether $group_name is present in $key_file.
=cut
gboolean
g_key_file_has_group (key_file, group_name)
	GKeyFile * key_file
	const gchar * group_name


=for apidoc __gerror__
Checks whether $group_name has $key in it.
=cut
gboolean
g_key_file_has_key (key_file, group_name, key)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = g_key_file_has_key (key_file, group_name, key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc __gerror__
Retrieves the literal value of $key inside $group_name.
=cut
gchar_own *
g_key_file_get_value (key_file, group_name, key)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = g_key_file_get_value (key_file, group_name, key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc
Sets the literal value of $key inside $group_name.
If $key cannot be found, it is created.
If $group_name cannot be found, it is created.
=cut
void
g_key_file_set_value (key_file, group_name, key, value)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
	const gchar * value

=for apidoc Glib::KeyFile::set_boolean
=arg value (gboolean)
Sets a boolean value to $key inside $group_name.
If $key is not found, it is created.
=cut

=for apidoc Glib::KeyFile::set_integer
=arg value (gint)
Sets an integer value to $key inside $group_name.
If $key is not found, it is created.
=cut

=for apidoc Glib::KeyFile::set_string
=arg value (gchar*)
Sets a string value to $key inside $group_name.  The string will be escaped if
it contains special characters.
If $key is not found, it is created.
=cut

void
g_key_file_set_boolean (key_file, group_name, key, value)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
	SV * value
    ALIAS:
    	Glib::KeyFile::set_integer = 1
	Glib::KeyFile::set_string  = 2
    CODE:
    	switch (ix) {
		case 0:
			g_key_file_set_boolean (key_file,
					group_name, key,
					SvTRUE (value));
			break;
		case 1:
			g_key_file_set_integer (key_file,
					group_name, key,
					SvIV (value));
			break;
		case 2:
			g_key_file_set_string (key_file,
					group_name, key,
					SvGChar (value));
			break;
	}

#if GLIB_CHECK_VERSION (2, 12, 0)

=for apidoc
Sets a double value to $key inside $group_name.
If $key is not found, it is created.
=cut
void g_key_file_set_double (GKeyFile *key_file, const gchar *group_name, const gchar *key, gdouble value);

#endif

=for apidoc Glib::KeyFile::get_boolean __gerror__
=signature boolean = $key_file->get_boolean ($group_name, $key)
Retrieves a boolean value from $key inside $group_name.
=cut

=for apidoc Glib::KeyFile::get_integer __gerror__
=signature integer = $key_file->get_integer ($group_name, $key)
Retrieves an integer value from $key inside $group_name.
=cut

=for apidoc Glib::KeyFile::get_string __gerror__
=signature string = $key_file->get_string ($group_name, $key)
Retrieves a string value from $key inside $group_name.
=cut

SV *
g_key_file_get_boolean (key_file, group_name, key)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
    ALIAS:
    	Glib::KeyFile::get_integer = 1
	Glib::KeyFile::get_string  = 2
    PREINIT:
    	GError *err = NULL;
    CODE:
    	switch (ix) {
		case 0:
		{
			gboolean retval;
			retval = g_key_file_get_boolean (key_file,
					group_name, key,
					&err);
			if (err)
				gperl_croak_gerror (NULL, err);
			RETVAL = boolSV (retval);
			break;
		}
		case 1:
		{
			gint retval;
			retval = g_key_file_get_integer (key_file,
					group_name, key,
					&err);
			if (err)
				gperl_croak_gerror (NULL, err);
			RETVAL = newSViv (retval);
			break;
		}
		case 2:
		{
			gchar *retval;
			retval = g_key_file_get_string (key_file,
					group_name, key,
					&err);
			if (err)
				gperl_croak_gerror (NULL, err);
			RETVAL = newSVGChar (retval);
			g_free (retval); /* leaks otherwise */
			break;
		}
		default:
			RETVAL = NULL;
			g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

#if GLIB_CHECK_VERSION (2, 12, 0)

=for apidoc __gerror__
Retrieves a double value from $key inside $group_name.
=cut
gdouble
g_key_file_get_double (key_file, group_name, key)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
    PREINIT:
    	GError *err = NULL;
    CODE:
	RETVAL = g_key_file_get_double (key_file,
			group_name, key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
	RETVAL

#endif

=for apidoc __gerror__
Returns the value associated with $key under $group_name translated in the
given $locale if available.  If $locale is undef then the current locale is
assumed.
=cut
gchar_own *
g_key_file_get_locale_string (key_file, group_name, key, locale=NULL)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
	const gchar_ornull * locale
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = g_key_file_get_locale_string (key_file,
			group_name, key,
			locale,
			&err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

void
g_key_file_set_locale_string (key_file, group_name, key, locale, string)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
	const gchar * locale
	const gchar * string

=for apidoc __gerror__
=cut
void
g_key_file_get_locale_string_list (key_file, group_name, key, locale);
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
	const gchar * locale
    PREINIT:
	gchar **retlist;
    	GError *err = NULL;
	gsize retlen, i;
    PPCODE:
	retlist = g_key_file_get_locale_string_list (key_file,
			group_name, key,
			locale,
			&retlen,
			&err);
	if (err)
		gperl_croak_gerror (NULL, err);
	for (i = 0; i < retlen; i++)
		XPUSHs (sv_2mortal (newSVGChar (retlist[i])));
	g_strfreev (retlist);

=for apidoc
Associates a list of string values for $key and $locale under $group_name.
If the translation for $key cannot be found then it is created.
=cut
void
g_key_file_set_locale_string_list (key_file, group_name, key, locale, ...)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
	const gchar * locale
    PREINIT:
    	gchar **list;
	gsize list_len;
	int i;
    CODE:
	list_len = (gsize) (items - 3);
	list = g_new0 (gchar *, list_len);
	for (i = 4; i < items; i++)
		list[i - 4] = SvPV_nolen (ST (i));
	g_key_file_set_locale_string_list (key_file,
			group_name, key,
			locale,
			(const gchar * const *) list, list_len);
	g_free (list);

=for apidoc Glib::KeyFile::get_string_list __gerror__
=signature list = $key_file->get_string_list ($group_name, $key)
Retrieves a list of strings from $key inside $group_name.
=cut

=for apidoc Glib::KeyFile::get_integer_list __gerror__
=signature list = $key_file->get_integer_list ($group_name, $key)
Retrieves a list of integers from $key inside $group_name.
=cut

=for apidoc Glib::KeyFile::get_boolean_list __gerror__
=signature list = $key_file->get_boolean_list ($group_name, $key)
Retrieves a list of booleans from $key inside $group_name.
=cut

void
g_key_file_get_string_list (key_file, group_name, key)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
    ALIAS:
    	Glib::KeyFile::get_boolean_list = 1
	Glib::KeyFile::get_integer_list = 2
    PREINIT:
    	GError *err = NULL;
	gsize retlen, i;
    PPCODE:
    	switch (ix) {
#define CROAK_ON_GERROR(error)	if (error) gperl_croak_gerror (NULL, error)
		case 0:
		{
			gchar **retlist;
			retlist = g_key_file_get_string_list (key_file,
					group_name, key,
					&retlen,
					&err);
			CROAK_ON_GERROR (err);
			EXTEND (sp, (long) retlen);
			for (i = 0; i < retlen; i++)
				PUSHs (sv_2mortal (newSVGChar (retlist[i])));
			g_strfreev (retlist);
			break;
		}
		case 1:
		{
			gboolean *retlist;
			retlist = g_key_file_get_boolean_list (key_file,
					group_name, key,
					&retlen,
					&err);
			CROAK_ON_GERROR (err);
			EXTEND (sp, (long) retlen);
			for (i = 0; i < retlen; i++)
				PUSHs (sv_2mortal (boolSV (retlist[i])));
			g_free (retlist);
			break;
		}
		case 2:
		{
			gint *retlist;
			retlist = g_key_file_get_integer_list (key_file,
					group_name, key,
					&retlen,
					&err);
			CROAK_ON_GERROR (err);
			EXTEND (sp, (long) retlen);
			for (i = 0; i < retlen; i++)
				PUSHs (sv_2mortal (newSViv (retlist[i])));
			g_free (retlist);
		}
	}

#if GLIB_CHECK_VERSION (2, 12, 0)

=for apidoc __gerror__
=signature list = $key_file->get_double_list ($group_name, $key)
Retrieves a list of doubles from $key inside $group_name.
=cut
void
g_key_file_get_double_list (key_file, group_name, key)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
    PREINIT:
    	GError *err = NULL;
	gsize retlen, i;
	gdouble *retlist;
    PPCODE:
	retlist = g_key_file_get_double_list (key_file,
			group_name, key,
			&retlen,
			&err);
	if (err)
		gperl_croak_gerror (NULL, err);
	EXTEND (sp, (long) retlen);
	for (i = 0; i < retlen; i++)
		PUSHs (sv_2mortal (newSVnv (retlist[i])));
	g_free (retlist);

#endif

=for apidoc Glib::KeyFile::set_string_list
=for arg ... list of strings
Sets a list of strings in $key inside $group_name.  The strings will be escaped
if contain special characters.  If $key cannot be found then it is created.  If
$group_name cannot be found then it is created.
=cut

=for apidoc Glib::KeyFile::set_boolean_list
=for arg ... list of booleans
Sets a list of booleans in $key inside $group_name.  If $key cannot be found
then it is created.  If $group_name cannot be found then it is created.
=cut

=for apidoc Glib::KeyFile::set_integer_list
=for arg ... list of integers
Sets a list of doubles in $key inside $group_name.  If $key cannot be found
then it is created.  If $group_name cannot be found then it is created.
=cut

void
g_key_file_set_string_list (key_file, group_name, key, ...)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
    ALIAS:
    	Glib::KeyFile::set_boolean_list = 1
	Glib::KeyFile::set_integer_list = 2
    PREINIT:
	gsize list_len;
	int i;
    CODE:
    	switch (ix) {
		case 0:
		{
			gchar **list;
			list_len = (gsize) (items - 3);
			list = g_new0 (gchar *, list_len);
			for (i = 3; i < items; i++)
				list[i - 3] = SvPV_nolen (ST (i));
			g_key_file_set_string_list (key_file,
					group_name, key,
					(const gchar * const *) list, list_len);
			g_free (list);
			break;
		}
		case 1:
		{
			gboolean *list;
			list_len = (gsize) (items - 3);
			list = g_new0 (gboolean, list_len);
			for (i = 3; i < items; i++)
				list[i - 3] = SvTRUE (ST (i));
			g_key_file_set_boolean_list (key_file,
					group_name, key,
					list, list_len);
			g_free (list);
			break;
		}
		case 2:
		{
			gint *list;
			list_len = (gsize) (items - 3);
			list = g_new0 (gint, list_len);
			for (i = 3; i < items; i++)
				list[i - 3] = SvIV (ST (i));
			g_key_file_set_integer_list (key_file,
					group_name, key,
					list, list_len);
			g_free (list);
			break;
		}
	}

#if GLIB_CHECK_VERSION (2, 12, 0)

=for apidoc
=for arg ... list of doubles
Sets a list of doubles in $key inside $group_name.  If $key cannot be found
then it is created.  If $group_name cannot be found then it is created.
=cut
void
g_key_file_set_double_list (key_file, group_name, key, ...)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
    PREINIT:
	gsize list_len;
	int i;
	gdouble *list;
    CODE:
	list_len = (gsize) (items - 3);
	list = g_new0 (gdouble, list_len);
	for (i = 3; i < items; i++)
		list[i - 3] = SvNV (ST (i));
	g_key_file_set_double_list (key_file,
			group_name, key,
			list, list_len);
	g_free (list);

#endif

=for apidoc __gerror__
Places a comment above $key from $group_name.  If $key is undef then $comment
will be written above $group_name.  If both $key and $group_name are undef,
then $comment will be written above the first group in the file.
=cut
void
g_key_file_set_comment (key_file, group_name, key, comment)
	GKeyFile * key_file
	const gchar_ornull * group_name
	const gchar_ornull * key
	const gchar * comment
    PREINIT:
    	GError *err = NULL;
    CODE:
    	g_key_file_set_comment (key_file, group_name, key, comment, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc __gerror__
Retreives a comment above $key from $group_name.  If $key is undef then
$comment will be read from above $group_name.  If both $key and $group_name
are undef, then $comment will be read from above the first group in the file.
=cut
gchar_own *
g_key_file_get_comment (key_file, group_name=NULL, key=NULL)
	GKeyFile * key_file
	const gchar_ornull * group_name
	const gchar_ornull * key
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = g_key_file_get_comment (key_file, group_name, key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc __gerror__
Removes a comment from a group in a key file.  If $key is undef, the comment
will be removed from above $group_name.  If both $key and $group_name are
undef, the comment will be removed from the top of the key file.
=cut
void
g_key_file_remove_comment (key_file, group_name=NULL, key=NULL)
	GKeyFile * key_file
	const gchar_ornull * group_name
	const gchar_ornull * key
    PREINIT:
    	GError *err = NULL;
    CODE:
    	g_key_file_remove_comment (key_file, group_name, key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc __gerror__
Removes a key from $group_name.
=cut
void
g_key_file_remove_key (key_file, group_name, key)
	GKeyFile * key_file
	const gchar * group_name
	const gchar * key
    PREINIT:
    	GError *err = NULL;
    CODE:
    	g_key_file_remove_key (key_file, group_name, key, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc __gerror__
Removes a group from a key file.
=cut
void
g_key_file_remove_group (key_file, group_name)
	GKeyFile * key_file
	const gchar * group_name
    PREINIT:
    	GError *err = NULL;
    CODE:
    	g_key_file_remove_group (key_file, group_name, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
