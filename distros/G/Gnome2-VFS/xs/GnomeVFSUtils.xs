/*
 * Copyright (C) 2003-2005 by the gtk2-perl team
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * $Id$
 */

#include "vfs2perl.h"

/* ------------------------------------------------------------------------- */

static char **
SvGnomeVFSCharArray (SV *ref)
{
	char **result = NULL;

	if (SvOK (ref)) {
		if (SvRV (ref) && SvTYPE (SvRV (ref)) == SVt_PVAV) {
			AV *array = (AV *) SvRV (ref);
			SV **string;

			int i, length = av_len (array);
			result = g_new0 (char *, length + 2);

			for (i = 0; i <= length; i++)
				if ((string = av_fetch (array, i, 0)) && SvOK (*string))
					result[i] = SvPV_nolen (*string);

			result[length + 1] = NULL;
		}
		else
			croak ("the environment parameter must be an array reference");
	}

	return result;
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::VFS::Utils	PACKAGE = Gnome2::VFS	PREFIX = gnome_vfs_

=for object Gnome2::VFS::main

=cut

##  char *gnome_vfs_format_file_size_for_display (GnomeVFSFileSize size) 
char_own *
gnome_vfs_format_file_size_for_display (class, size)
	GnomeVFSFileSize size
    C_ARGS:
	size

#if VFS_CHECK_VERSION (2, 2, 0)

##  char *gnome_vfs_escape_string (const char *string) 
char_own *
gnome_vfs_escape_string (class, string)
	const char *string
    C_ARGS:
	string

#endif

##  char *gnome_vfs_escape_path_string (const char *path) 
char_own *
gnome_vfs_escape_path_string (class, path)
	const char *path
    C_ARGS:
	path

##  char *gnome_vfs_escape_host_and_path_string (const char *path) 
char_own *
gnome_vfs_escape_host_and_path_string (class, path)
	const char *path
    C_ARGS:
	path

##  char *gnome_vfs_escape_slashes (const char *string) 
char_own *
gnome_vfs_escape_slashes (class, string)
	const char *string
    C_ARGS:
	string

##  char *gnome_vfs_escape_set (const char *string, const char *match_set) 
char_own *
gnome_vfs_escape_set (class, string, match_set)
	const char *string
	const char *match_set
    C_ARGS:
	string, match_set

##  char *gnome_vfs_unescape_string (const char *escaped_string, const char *illegal_characters) 
gchar_own *
gnome_vfs_unescape_string (class, escaped_string, illegal_characters=NULL)
	const char *escaped_string
	const char *illegal_characters
    C_ARGS:
	escaped_string, illegal_characters

##  char *gnome_vfs_make_uri_canonical (const char *uri) 
char_own *
gnome_vfs_make_uri_canonical (class, uri)
	const char *uri
    C_ARGS:
	uri

##  char *gnome_vfs_make_path_name_canonical (const char *path) 
char_own *
gnome_vfs_make_path_name_canonical (class, path)
	const char *path
    C_ARGS:
	path

##  char *gnome_vfs_expand_initial_tilde (const char *path) 
char_own *
gnome_vfs_expand_initial_tilde (class, path)
	const char *path
    C_ARGS:
	path

##  char *gnome_vfs_unescape_string_for_display (const char *escaped) 
gchar_own *
gnome_vfs_unescape_string_for_display (class, escaped)
	const char *escaped
    C_ARGS:
	escaped

##  char *gnome_vfs_get_local_path_from_uri (const char *uri) 
char_own *
gnome_vfs_get_local_path_from_uri (class, uri)
	const char *uri
    C_ARGS:
	uri

##  char *gnome_vfs_get_uri_from_local_path (const char *local_full_path) 
char_own *
gnome_vfs_get_uri_from_local_path (class, local_full_path)
	const char *local_full_path
    C_ARGS:
	local_full_path

##  gboolean gnome_vfs_is_executable_command_string (const char *command_string) 
gboolean
gnome_vfs_is_executable_command_string (class, command_string)
	const char *command_string
    C_ARGS:
	command_string

###  void gnome_vfs_list_deep_free (GList *list) 
#void
#gnome_vfs_list_deep_free (list)
#	GList *list


=for apidoc

Returns a GnomeVFSResult and a GnomeVFSFileSize.

=cut
##  GnomeVFSResult gnome_vfs_get_volume_free_space (const GnomeVFSURI *vfs_uri, GnomeVFSFileSize *size) 
void
gnome_vfs_get_volume_free_space (class, vfs_uri)
	const GnomeVFSURI *vfs_uri
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSFileSize size;
    PPCODE:
	result = gnome_vfs_get_volume_free_space (vfs_uri, &size);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileSize (size)));

##  char *gnome_vfs_icon_path_from_filename (const char *filename) 
char_own *
gnome_vfs_icon_path_from_filename (class, filename)
	const char *filename
    C_ARGS:
	filename

###  GnomeVFSResult gnome_vfs_open_fd (GnomeVFSHandle **handle, int filedes) 
#GnomeVFSResult
#gnome_vfs_open_fd (handle, filedes)
#	GnomeVFSHandle **handle
#	int filedes

##  gboolean gnome_vfs_is_primary_thread (void) 
gboolean
gnome_vfs_is_primary_thread (class)
    C_ARGS:
	/* void */

#if VFS_CHECK_VERSION (2, 2, 0)

=for apidoc

Returns a GnomeVFSResult, the file size and the file content.

=cut
##  GnomeVFSResult gnome_vfs_read_entire_file (const char *uri, int *file_size, char **file_contents) 
void
gnome_vfs_read_entire_file (class, uri)
	const char *uri
    PREINIT:
	GnomeVFSResult result;
	int file_size = 0;
	char *file_contents = NULL;
    PPCODE:
	result = gnome_vfs_read_entire_file (uri, &file_size, &file_contents);
	EXTEND (sp, 3);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSViv (file_size)));
	PUSHs (sv_2mortal (file_size
			   ? newSVpv (file_contents, file_size)
			   : newSVsv (&PL_sv_undef)));

##  char * gnome_vfs_format_uri_for_display (const char *uri) 
gchar_own *
gnome_vfs_format_uri_for_display (class, uri)
	const char *uri
    C_ARGS:
	uri

##  char * gnome_vfs_make_uri_from_input (const char *uri) 
char_own *
gnome_vfs_make_uri_from_input (class, uri)
	const char *uri
    C_ARGS:
	uri

#endif

#if VFS_CHECK_VERSION (2, 4, 0)

##  char * gnome_vfs_make_uri_from_input_with_dirs (const char *uri, GnomeVFSMakeURIDirs dirs) 
char_own *
gnome_vfs_make_uri_from_input_with_dirs (class, uri, dirs)
	const char *uri
	GnomeVFSMakeURIDirs dirs
    C_ARGS:
	uri, dirs

#endif

#if VFS_CHECK_VERSION (2, 12, 0)

##  char * gnome_vfs_make_uri_from_input_with_trailing_ws (const char *location);
char_own *
gnome_vfs_make_uri_from_input_with_trailing_ws (class, location)
	const char *location
    C_ARGS:
	location

#endif

#if VFS_CHECK_VERSION (2, 2, 0)

##  char * gnome_vfs_make_uri_canonical_strip_fragment (const char *uri) 
char_own *
gnome_vfs_make_uri_canonical_strip_fragment (class, uri)
	const char *uri
    C_ARGS:
	uri

##  gboolean gnome_vfs_uris_match (const char *uri_1, const char *uri_2) 
gboolean
gnome_vfs_uris_match (class, uri_1, uri_2)
	const char *uri_1
	const char *uri_2
    C_ARGS:
	uri_1, uri_2

##  char * gnome_vfs_get_uri_scheme (const char *uri) 
char_own *
gnome_vfs_get_uri_scheme (class, uri)
	const char *uri
    C_ARGS:
	uri

##  char * gnome_vfs_make_uri_from_shell_arg (const char *uri) 
char_own *
gnome_vfs_make_uri_from_shell_arg (class, uri)
	const char *uri
    C_ARGS:
	uri

# deprecated.
###  char * gnome_vfs_make_uri_full_from_relative (const char *base_uri, const char *relative_uri) 
#char_own *
#gnome_vfs_make_uri_full_from_relative (class, base_uri, relative_uri)
#	const char *base_uri
#	const char *relative_uri
#    C_ARGS:
#	base_uri, relative_uri

#endif

#if VFS_CHECK_VERSION (2, 4, 0)

##  GnomeVFSResult gnome_vfs_url_show (const char *url) 
GnomeVFSResult
gnome_vfs_url_show (class, url)
	const char *url
    C_ARGS:
	url

##  GnomeVFSResult gnome_vfs_url_show_with_env (const char *url, char **envp) 
GnomeVFSResult
gnome_vfs_url_show_with_env (class, url, env_ref)
	const char *url
	SV *env_ref
    PREINIT:
	char **envp;
    CODE:
	envp = SvGnomeVFSCharArray (env_ref);
	RETVAL = gnome_vfs_url_show_with_env (url, envp);
	g_free (envp);
    OUTPUT:
	RETVAL

#endif
