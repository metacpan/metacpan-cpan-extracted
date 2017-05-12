/*
 * Copyright (c) 2003, 2004 by Emmanuele Bassi (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 * Boston, MA  02111-1307  USA.
 */

#include "gconfperl.h"

#ifdef GCONFPERL_TYPE_GCONF_ERROR
/* error codes taken from gconf-error.h */
static const GEnumValue _gconfperl_gconf_error_values[] = {
  { GCONF_ERROR_SUCCESS, "GCONF_ERROR_SUCCESS", "success" },
  { GCONF_ERROR_FAILED, "GCONF_ERROR_FAILED", "failed" },
  { GCONF_ERROR_NO_SERVER, "GCONF_ERROR_NO_SERVER", "no-server" },
  { GCONF_ERROR_NO_PERMISSION, "GCONF_ERROR_NO_PERMISSION", "no-permission" },
  { GCONF_ERROR_BAD_ADDRESS, "GCONF_ERROR_BAD_ADDRESS", "bad-address" },
  { GCONF_ERROR_BAD_KEY, "GCONF_ERROR_BAD_KEY", "bad-key" },
  { GCONF_ERROR_PARSE_ERROR, "GCONF_ERROR_PARSE_ERROR", "parse-error" },
  { GCONF_ERROR_CORRUPT, "GCONF_ERROR_CORRUPT", "corrupt" },
  { GCONF_ERROR_TYPE_MISMATCH, "GCONF_ERROR_TYPE_MISMATCH", "type-mismatch" },
  { GCONF_ERROR_IS_DIR, "GCONF_ERROR_IS_DIR", "is-dir" },
  { GCONF_ERROR_IS_KEY, "GCONF_ERROR_IS_KEY", "is-key" },
  { GCONF_ERROR_OVERRIDDEN, "GCONF_ERROR_OVERRIDDEN", "overridden" },
  { GCONF_ERROR_OAF_ERROR, "GCONF_ERROR_OAF_ERROR", "oaf-error" },
  { GCONF_ERROR_LOCAL_ENGINE, "GCONF_ERROR_LOCAL_ENGINE", "local-engine" },
  { GCONF_ERROR_LOCK_FAILED, "GCONF_ERROR_LOCK_FAILED", "lock-failed" },
  { GCONF_ERROR_NO_WRITABLE_DATABASE, "GCONF_ERROR_NO_WRITABLE_DATABASE", "no-writable-database" },
  { GCONF_ERROR_IN_SHUTDOWN, "GCONF_ERROR_IN_SHUTDOWN", "in-shutdown" },
  { 0, NULL, NULL },
};

GType
gconfperl_gconf_error_get_type (void)
{
  static GType type = 0;

  if (! type)
    type = g_enum_register_static ("GConfPerlError", _gconfperl_gconf_error_values);
  
  return type;
}
#endif

MODULE = Gnome2::GConf	PACKAGE = Gnome2::GConf PREFIX = gconf_

=for object Gnome2::GConf::version

=cut


BOOT:
#include "register.xsh"
#include "boot.xsh"
	gperl_register_error_domain (GCONF_ERROR,
			             GCONFPERL_TYPE_GCONF_ERROR,
				     "Gnome2::GConf::Error");


=for apidoc
=for signature (MAJOR, MINOR, MICRO) = Gnome2::GConf->GET_VERSION_INFO
Fetch as a list the version of libgconf for which Gnome2::GConf was
built.
=cut
void
GET_VERSION_INFO (class)
    PPCODE:
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (GCONF_MAJOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GCONF_MINOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (GCONF_MICRO_VERSION)));
	PERL_UNUSED_VAR (ax);

gboolean
CHECK_VERSION (class, major, minor, micro)
	int major
	int minor
	int micro
    CODE:
	RETVAL = GCONF_CHECK_VERSION (major, minor, micro);
    OUTPUT:
	RETVAL

## gconf.h

=for object Gnome2::GConf::main
=cut

=for apidoc
=for signature boolean = Gnome2::GConf->valid_key ($key)
=for signature (boolean, string) = Gnome2::GConf->valid_key ($key)

In scalar context, it returns a boolean value.
In array context, it returns a boolean value and a string containing a
user-readable explanation of the problem.
=cut
void
gconf_valid_key (class, key)
	const gchar * key
    C_ARGS:
        key
    PREINIT:
	gchar *why_invalid = NULL;
	gboolean is_valid;
    PPCODE:
	is_valid = gconf_valid_key (key, &why_invalid);
	if (GIMME_V == G_ARRAY) {
		EXTEND (SP, 2);
		PUSHs (sv_2mortal (newSViv (is_valid)));
		PUSHs (sv_2mortal (newSVpv (why_invalid, 0)));
		g_free (why_invalid); /* leaks otherwise */
	}
	else {
		XPUSHs (sv_2mortal (newSViv (is_valid)));
	}

=for apidoc
Return TRUE if the path $below would be somewhere below the directory $above.
=cut
gboolean
gconf_key_is_below (class, above, below)
	const gchar * above
	const gchar * below
    C_ARGS:
    	above, below

=for apidoc
Returns a concatenation of $dir and $key.
=cut
gchar*
gconf_concat_dir_and_key (class, dir, key)
	const gchar * dir
	const gchar * key
    C_ARGS:
    	dir, key

=for apidoc
Returns a different string every time (at least, the chances of getting a
duplicate are like one in a zillion). The key is a legal gconf key name (a
single element of one).
=cut
gchar*
gconf_unique_key (class)
    C_ARGS:
    	/* void */
