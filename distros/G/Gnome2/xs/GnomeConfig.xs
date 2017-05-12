/*
 * Copyright (C) 2003, 2013 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"

/* ------------------------------------------------------------------------- */

static void *
SvGnomeConfigIterator (SV *object)
{
	MAGIC *mg;

	if (!object || !SvOK (object) || !SvROK (object) || !(mg = mg_find (SvRV (object), PERL_MAGIC_ext)))
		return NULL;

	return (void *) mg->mg_ptr;
}

static SV *
newSVGnomeConfigIterator (const char *app_id)
{
	SV *object = (SV *) newHV ();

	sv_magic (object, 0, PERL_MAGIC_ext, (const char *) app_id, 0);

	return sv_bless (newRV_noinc (object),
	                 gv_stashpv ("Gnome2::Config::Iterator", 1));
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::Config	PACKAGE = Gnome2::Config	PREFIX = gnome_config_

char *
get_string (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::get_translated_string = 1
	Gnome2::Config::Private::get_string = 2
	Gnome2::Config::Private::get_translated_string = 3
    CODE:
	switch (ix) {
		case 0: RETVAL = gnome_config_get_string (path); break;
		case 1: RETVAL = gnome_config_get_translated_string (path); break;
		case 2: RETVAL = gnome_config_private_get_string (path); break;
		case 3: RETVAL = gnome_config_private_get_translated_string (path); break;
		default: RETVAL = NULL;
	}
    OUTPUT:
	RETVAL
    CLEANUP:
	g_free (RETVAL);

=for apidoc

Returns a boolean indicating whether the default was used and the actual value.

=cut
void
get_string_with_default (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::get_translated_string_with_default = 1
	Gnome2::Config::Private::get_string_with_default = 2
	Gnome2::Config::Private::get_translated_string_with_default = 3
    PREINIT:
	char *retval = NULL;
	gboolean def;
    PPCODE:
	switch (ix) {
		case 0: retval = gnome_config_get_string_with_default (path, &def); break;
		case 1: retval = gnome_config_get_translated_string_with_default (path, &def); break;
		case 2: retval = gnome_config_private_get_string_with_default (path, &def); break;
		case 3: retval = gnome_config_private_get_translated_string_with_default (path, &def); break;
	}

	EXTEND (sp, 1);
	PUSHs (sv_2mortal (newSVuv (def)));
	if (retval != NULL)
		XPUSHs (sv_2mortal (newSVpv (retval, 0)));

	g_free (retval);

int
get_int (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::Private::get_int = 1
    CODE:
	switch (ix) {
		case 0: RETVAL = gnome_config_get_int (path); break;
		case 1: RETVAL = gnome_config_private_get_int (path); break;
		default: RETVAL = 0;
	}
    OUTPUT:
	RETVAL

=for apidoc

Returns a boolean indicating whether the default was used and the actual value.

=cut
void
get_int_with_default (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::Private::get_int_with_default = 1
    PREINIT:
	int retval = 0;
	gboolean def;
    PPCODE:
	switch (ix) {
		case 0: retval = gnome_config_get_int_with_default (path, &def); break;
		case 1: retval = gnome_config_private_get_int_with_default (path, &def); break;
	}

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVuv (def)));
	PUSHs (sv_2mortal (newSViv (retval)));

gdouble
get_float (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::Private::get_float = 1
    CODE:
	switch (ix) {
		case 0: RETVAL = gnome_config_get_float (path); break;
		case 1: RETVAL = gnome_config_private_get_float (path); break;
		default: RETVAL = 0.0;
	}
    OUTPUT:
	RETVAL

=for apidoc

Returns a boolean indicating whether the default was used and the actual value.

=cut
void
get_float_with_default (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::Private::get_float_with_default = 1
    PREINIT:
	gdouble retval = 0.0;
	gboolean def;
    PPCODE:
	switch (ix) {
		case 0: retval = gnome_config_get_float_with_default (path, &def); break;
		case 1: retval = gnome_config_private_get_float_with_default (path, &def); break;
	}

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVuv (def)));
	PUSHs (sv_2mortal (newSVnv (retval)));

gboolean
get_bool (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::Private::get_bool = 1
    CODE:
	switch (ix) {
		case 0: RETVAL = gnome_config_get_bool (path); break;
		case 1: RETVAL = gnome_config_private_get_bool (path); break;
		default: RETVAL = FALSE;
	}
    OUTPUT:
	RETVAL

=for apidoc

Returns a boolean indicating whether the default was used and the actual value.

=cut
void
get_bool_with_default (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::Private::get_bool_with_default = 1
    PREINIT:
	gboolean retval = FALSE;
	gboolean def = FALSE;
    PPCODE:
	switch (ix) {
		case 0: retval = gnome_config_get_bool_with_default (path, &def); break;
		case 1: retval = gnome_config_private_get_bool_with_default (path, &def); break;
	}

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVuv (def)));
	PUSHs (sv_2mortal (newSVuv (retval)));

SV *
get_vector (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::Private::get_vector = 1
    PREINIT:
	char **argv = NULL;
	int argc, i;
	AV *array = newAV ();
    CODE:
	switch (ix) {
		case 0: gnome_config_get_vector (path, &argc, &argv); break;
		case 1: gnome_config_private_get_vector (path, &argc, &argv); break;
	}

	if (argv != NULL) {
		for (i = 0; i < argc; i++)
			av_push (array, newSVpv (argv[i], 0));

		g_free (argv);
	}

	RETVAL = newRV_noinc ((SV *) array);
    OUTPUT:
	RETVAL

=for apidoc

Returns a boolean indicating whether the default was used and the actual value.

=cut
void
get_vector_with_default (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::Private::get_vector_with_default = 1
    PREINIT:
	gboolean def;
	char **argv = NULL;
	int argc, i;
	AV *array = newAV ();
    PPCODE:
	switch (ix) {
		case 0: gnome_config_get_vector_with_default (path, &argc, &argv, &def); break;
		case 1: gnome_config_private_get_vector_with_default (path, &argc, &argv, &def); break;
	}

	if (argv != NULL) {
		for (i = 0; i < argc; i++)
			av_push (array, newSVpv (argv[i], 0));

		g_free (argv);
	}

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVuv (def)));
	PUSHs (sv_2mortal (newRV_noinc ((SV *) array)));

# --------------------------------------------------------------------------- #

void
set_string (class, path, value)
	const char *path
	const char *value
    ALIAS:
	Gnome2::Config::set_translated_string = 1
	Gnome2::Config::Private::set_string = 2
	Gnome2::Config::Private::set_translated_string = 3
    CODE:
	switch (ix) {
		case 0: gnome_config_set_string (path, value); break;
		case 1: gnome_config_set_translated_string (path, value); break;
		case 2: gnome_config_private_set_string (path, value); break;
		case 3: gnome_config_private_set_translated_string (path, value); break;
	}

void
set_int (class, path, value)
	const char *path
	int value
    ALIAS:
	Gnome2::Config::Private::set_int = 1
    CODE:
	switch (ix) {
		case 0: gnome_config_set_int (path, value); break;
		case 1: gnome_config_private_set_int (path, value); break;
	}

void
set_float (class, path, value)
	const char *path
	gdouble value
    ALIAS:
	Gnome2::Config::Private::set_float = 1
    CODE:
	switch (ix) {
		case 0: gnome_config_set_float (path, value); break;
		case 1: gnome_config_private_set_float (path, value); break;
	}

void
set_bool (class, path, value)
	const char *path
	gboolean value
    ALIAS:
	Gnome2::Config::Private::set_bool = 1
    CODE:
	switch (ix) {
		case 0: gnome_config_set_bool (path, value); break;
		case 1: gnome_config_private_set_bool (path, value); break;
	}

void
set_vector (class, path, value)
	const char *path
	SV *value
    ALIAS:
	Gnome2::Config::Private::set_vector = 1
    PREINIT:
	char **argv;
	int length, i;
	AV *array;
	SV **string;
    CODE:
	if (! (SvOK (value) && SvROK (value) && SvTYPE (SvRV (value)) == SVt_PVAV))
		croak ("the vector parameter must be a reference to an array");

	array = (AV *) SvRV (value);
	length = av_len (array);

	argv = g_new0 (char *, length + 1);

	for (i = 0; i <= length; i++) {
		string = av_fetch (array, i, 0);
		if (string)
			argv[i] = SvPV_nolen (*string);
	}

	switch (ix) {
		case 0: gnome_config_set_vector (path, length + 1, (const char **) argv); break;
		case 1: gnome_config_private_set_vector (path, length + 1, (const char **) argv); break;
	}

# --------------------------------------------------------------------------- #

gboolean
has_section (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::Private::has_section = 1
	Gnome2::Config::sync_file = 2
	Gnome2::Config::Private::sync_file = 3
    CODE:
	switch (ix) {
		case 0: RETVAL = gnome_config_has_section (path); break;
		case 1: RETVAL = gnome_config_private_has_section (path); break;
		case 2: RETVAL = gnome_config_sync_file ((char *) path); break;
		case 3: RETVAL = gnome_config_private_sync_file ((char *) path); break;
		default: RETVAL = FALSE;
	}
    OUTPUT:
	RETVAL

void
drop_file (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::Private::drop_file = 1
	Gnome2::Config::clean_file = 2
	Gnome2::Config::Private::clean_file = 3
	Gnome2::Config::clean_section = 4
	Gnome2::Config::Private::clean_section = 5
	Gnome2::Config::clean_key = 6
	Gnome2::Config::Private::clean_key = 7
    CODE:
	switch (ix) {
		case 0: gnome_config_drop_file (path); break;
		case 1: gnome_config_private_drop_file (path); break;
		case 2: gnome_config_clean_file (path); break;
		case 3: gnome_config_private_clean_file (path); break;
		case 4: gnome_config_clean_section (path); break;
		case 5: gnome_config_private_clean_section (path); break;
		case 6: gnome_config_clean_key (path); break;
		case 7: gnome_config_private_clean_key (path); break;
	}

gchar *
get_real_path (class, path)
	gchar *path
    ALIAS:
	Gnome2::Config::Private::get_real_path = 1
    CODE:
	switch (ix) {
		case 0: RETVAL = gnome_config_get_real_path (path); break;
		case 1: RETVAL = gnome_config_private_get_real_path (path); break;
		default: RETVAL = NULL;
	}
    OUTPUT:
	RETVAL
    CLEANUP:
	g_free (RETVAL);

##  void gnome_config_drop_all (void) 
void
gnome_config_drop_all (class)
    C_ARGS:
	/* void */

##  gboolean gnome_config_sync (void) 
gboolean
gnome_config_sync (class)
    C_ARGS:
	/* void */

##  void gnome_config_push_prefix (const char *path) 
void
gnome_config_push_prefix (class, path)
	const char *path
    C_ARGS:
	path

##  void gnome_config_pop_prefix (void) 
void
gnome_config_pop_prefix (class)
    C_ARGS:
	/* void */

# --------------------------------------------------------------------------- #

SV *
gnome_config_init_iterator (class, path)
	const char *path
    ALIAS:
	Gnome2::Config::init_iterator_sections = 1
	Gnome2::Config::Private::init_iterator = 2
	Gnome2::Config::Private::init_iterator_sections = 3
    PREINIT:
	void *pointer = NULL;
    CODE:
	switch (ix) {
		case 0: pointer = gnome_config_init_iterator (path); break;
		case 1: pointer = gnome_config_init_iterator_sections (path); break;
		case 2: pointer = gnome_config_private_init_iterator (path); break;
		case 3: pointer = gnome_config_private_init_iterator_sections (path); break;
	}

	if (pointer)
		RETVAL = newSVGnomeConfigIterator (pointer);
	else
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

MODULE = Gnome2::Config	PACKAGE = Gnome2::Config::Iterator	PREFIX = gnome_config_iterator_

=for apidoc

Returns the new GnomeConfigIterator, the key, and the value.

=cut
void
gnome_config_iterator_next (handle)
	SV *handle
    PREINIT:
	void *new = NULL, *old = NULL;
	char *key = NULL, *value = NULL;
    PPCODE:
	old = SvGnomeConfigIterator (handle);
	new = gnome_config_iterator_next (old, &key, &value);

	if (new && key && value) {
		EXTEND (sp, 3);

		PUSHs (sv_2mortal (newSVGnomeConfigIterator (new)));
		PUSHs (sv_2mortal (newSVpv (key, 0)));
		PUSHs (sv_2mortal (newSVpv (value, 0)));

		g_free (key);
		g_free (value);
	}
	else
		XSRETURN_EMPTY;

void
DESTROY (handle)
	SV *handle
    CODE:
	sv_unmagic (SvRV (handle), PERL_MAGIC_ext);

# --------------------------------------------------------------------------- #

###  void gnome_config_make_vector (const char *string, int *argcp, char ***argvp) 
#void
#gnome_config_make_vector (string, argcp, argvp)
#	const char *string
#	int *argcp
#	char ***argvp

###  char *gnome_config_assemble_vector (int argc, const char *const argv []) 
#char *
#gnome_config_assemble_vector (argc, )
#	int argc
#	const char *const argv []
