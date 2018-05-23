/*
 * Copyright (C) 2006,2012 by the gtk2-perl team (see the file AUTHORS for
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

SV *
newSVGBookmarkFile (GBookmarkFile * bookmark_file)
{
	HV * bookmark = newHV ();
	SV * sv;
	HV * stash;

	/* tie the key_file to our hash using some magic */
	_gperl_attach_mg ((SV *) bookmark, bookmark_file);

	/* wrap it, bless it, ship it. */
	sv = newRV_noinc ((SV *) bookmark);

	stash = gv_stashpv ("Glib::BookmarkFile", TRUE);
	sv_bless (sv, stash);

	return sv;
}

GBookmarkFile *
SvGBookmarkFile (SV * sv)
{
	MAGIC * mg;
	if (!gperl_sv_is_ref (sv) || !(mg = _gperl_find_mg (SvRV (sv))))
		return NULL;
	return (GBookmarkFile *) mg->mg_ptr;
}


MODULE = Glib::BookmarkFile	PACKAGE = Glib::BookmarkFile	PREFIX = g_bookmark_file_

=for object Glib::BookmarkFile Parser for bookmark files
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

  use Glib;

  $date .= $_ while (<DATA>);

  $b = Glib::BookmarkFile->new;
  $b->load_from_data($data);
  $uri = 'file:///some/path/to/a/file.txt';
  if ($b->has_item($uri)) {
  	$title = $b->get_title($uri);
	$desc  = $b->get_description($uri);

	print "Bookmark for `$uri' ($title):\n";
	print "  $desc\n";
  }
  0;

  __DATA__
  <?xml version="1.0" encoding="UTF-8"?>
  <xbel version="1.0"
        xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks"
        xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info">
    <bookmark href="file:///tmp/test-file.txt" added="2006-03-22T18:54:00Z" modified="2006-03-22T18:54:00Z" visited="2006-03-22T18:54:00Z">
      <title>Test File</title>
      <desc>Some test file</desc>
      <info>
        <metadata owner="http://freedesktop.org">
          <mime:mime-type type="text/plain"/>
          <bookmark:applications>
            <bookmark:application name="Gedit" exec="gedit %u" timestamp="1143053640" count="1"/>
          </bookmark:applications>
        </metadata>
      </info>
    </bookmark>
  </xbel>

=for position DESCRIPTION

=head1 DESCRIPTION

B<Glib::BookmarkFile> lets you parse, edit or create files containing lists
of bookmarks to resources pointed to by URIs, with some meta-data bound to
them, following the Desktop Bookmark Specification.  The recent files support
inside GTK+ uses this type of files to store the list of recently used
files.

The syntax of bookmark files is described in detail in the Desktop Bookmarks
Specification, here is a quick summary: bookmark files use a subclass of the
XML Bookmark Exchange Language (XBEL) document format, defining meta-data
such as the MIME type of the resource pointed by a bookmark, the list of
applications that have registered the same URI and the visibility of the
bookmark.

=cut


void
DESTROY (GBookmarkFile *bookmark_file)
    CODE:
        g_bookmark_file_free (bookmark_file);

GBookmarkFile *
g_bookmark_file_new (class)
    C_ARGS:
        /* void */

# unneeded
# void g_bookmark_file_free (GBookmarkFile *bookmark);

=for apidoc __gerror__
Parses a bookmark file.
=cut
void
g_bookmark_file_load_from_file (bookmark_file, file)
	GBookmarkFile *bookmark_file
	GPerlFilename_const file
    PREINIT:
        GError *err = NULL;
    CODE:
        g_bookmark_file_load_from_file (bookmark_file, file, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc __gerror__
Parses a string containing a bookmark file structure.
=cut
void
g_bookmark_file_load_from_data (bookmark_file, buf)
	GBookmarkFile *bookmark_file
	SV *buf
    PREINIT:
    	STRLEN length;
	GError *err = NULL;
	const gchar *data = (const gchar *) SvPV (buf, length);
    CODE:
        g_bookmark_file_load_from_data (bookmark_file, data, length, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc __gerror__
=signature ($full_path) = $bookmark_file->load_from_data_dirs ($file)

Parses a bookmark file, searching for it inside the data directories.
If a file is found, it returns the full path.
=cut
void
g_bookmark_file_load_from_data_dirs (bookmark_file, file)
	GBookmarkFile *bookmark_file
	GPerlFilename_const file
    PREINIT:
        GError *err = NULL;
	gchar *full_path;
    PPCODE:
        g_bookmark_file_load_from_data_dirs (bookmark_file, file,
					     &full_path,
					     &err);
	if (err)
		gperl_croak_gerror (NULL, err);
	if (full_path) {
		XPUSHs (sv_2mortal (newSVGChar (full_path)));
		g_free (full_path);
	}

=for apidoc __gerror__
Returns the bookmark file as a string.
=cut
gchar_own *
g_bookmark_file_to_data (bookmark_file)
	GBookmarkFile *bookmark_file
    PREINIT:
     	GError *err = NULL;
	gsize len;
    CODE:
        RETVAL = g_bookmark_file_to_data (bookmark_file, &len, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc __gerror__
Saves the contents of a bookmark file into a file.  The write operation
is guaranteed to be atomic by writing the contents of the bookmark file
to a temporary file and then moving the file to the target file.
=cut
void
g_bookmark_file_to_file (bookmark_file, file)
	GBookmarkFile *bookmark_file
	GPerlFilename_const file
    PREINIT:
        GError *err = NULL;
    CODE:
    	g_bookmark_file_to_file (bookmark_file, file, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc
Looks whether the bookmark file has a bookmark for $uri.
=cut
gboolean
g_bookmark_file_has_item (GBookmarkFile *bookmark_file, const gchar *uri)

=for apidoc __gerror__
Removes the bookmark for $uri from the bookmark file.
=cut
void
g_bookmark_file_remove_item (GBookmarkFile *bookmark_file, const gchar *uri)
    PREINIT:
        GError *err = NULL;
    CODE:
        g_bookmark_file_remove_item (bookmark_file, uri, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc __gerror__
Changes the URI of a bookmark item from $old_uri to $new_uri.  Any
existing bookmark for $new_uri will be overwritten.  If $new_uri is
undef, then the bookmark is removed.
=cut
void
g_bookmark_file_move_item (bookmark_file, old_uri, new_uri)
	GBookmarkFile *bookmark_file
	const gchar *old_uri
	const gchar_ornull *new_uri
    PREINIT:
        GError *err = NULL;
    CODE:
        g_bookmark_file_move_item (bookmark_file, old_uri, new_uri, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc
Gets the number of bookmarks inside the bookmark file.
=cut
gint g_bookmark_file_get_size (GBookmarkFile *bookmark_file)

=for apidoc
=signature list = $bookmark_file->get_uris
Returns the URI of all the bookmarks in the bookmark file.
=cut
void
g_bookmark_file_get_uris (bookmark_file)
	GBookmarkFile *bookmark_file
    PREINIT:
    	gchar **uris;
	gsize len, i;
    PPCODE:
    	uris = g_bookmark_file_get_uris (bookmark_file, &len);
	if (len != 0) {
		for (i = 0; i < len; i++) {
			if (uris[i])
				XPUSHs (sv_2mortal (newSVGChar (uris[i])));
		}
	}
	g_strfreev (uris);

=for apidoc
Sets the title of the bookmark for $uri.  If no bookmark for $uri is found
one is created.
=cut
void
g_bookmark_file_set_title (GBookmarkFile *bookmark_file, const gchar *uri, const gchar *title)

=for apidoc __gerror__
=signature $bookmark_file->get_title ($uri, $title)
Gets the title of the bookmark for $uri.
=cut
gchar_own *
g_bookmark_file_get_title (bookmark_file, uri)
	GBookmarkFile *bookmark_file
	const gchar *uri
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = g_bookmark_file_get_title (bookmark_file, uri, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc
Sets the description of the bookmark for $uri.  If no bookmark for $uri
is found one is created.
=cut
void
g_bookmark_file_set_description (GBookmarkFile *bookmark_file, const gchar *uri, const gchar *description)

=for apidoc __gerror__
=signature $bookmark_file->get_description ($uri)
Gets the description of the bookmark for $uri.
=cut
gchar_own *
g_bookmark_file_get_description (bookmark_file, uri)
	GBookmarkFile *bookmark_file
	const gchar *uri
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = g_bookmark_file_get_description (bookmark_file, uri, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc
Sets the MIME type of the bookmark for $uri.  If no bookmark for $uri
is found one is created.
=cut
void
g_bookmark_file_set_mime_type (GBookmarkFile *bookmark_file, const gchar *uri, const gchar *mime_type)

=for apidoc __gerror__
Gets the MIME type of the bookmark for $uri.
=cut
gchar_own *
g_bookmark_file_get_mime_type (bookmark_file, uri)
	GBookmarkFile *bookmark_file
	const gchar *uri
    PREINIT:
    	GError *err = NULL;
    CODE:
    	RETVAL = g_bookmark_file_get_mime_type (bookmark_file, uri, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
    	RETVAL

=for apidoc
=for arg ... one or more group names
Sets a list of group names for the item with URI $uri.  Each previously
set group name list is removed.  If no bookmark for $uri is found one
is created.
=cut
void
g_bookmark_file_set_groups (GBookmarkFile *bookmark_file, const gchar *uri, ...)
    PREINIT:
        gchar **groups;
	gsize groups_len;
	int i;
    CODE:
        groups_len = (gsize) (items - 2);
	groups = g_new0 (gchar *, groups_len + 1);
	for (i = 2; i < items; i++)
		groups[i - 2] = SvPV_nolen (ST (i));
	g_bookmark_file_set_groups (bookmark_file, uri,
			            (const gchar **) groups,
				    groups_len);
	g_free (groups);

=for apidoc
Adds $group to the list of groups to which the bookmark for $uri
belongs to.  If no bookmark for $uri is found one is created.
=cut
void
g_bookmark_file_add_group (GBookmarkFile *bookmark_file, const gchar *uri, const gchar *group)

=for apidoc __gerror__
Checks whether $group appears in the list of groups to which
the bookmark for $uri belongs to.
=cut
gboolean
g_bookmark_file_has_group (bookmark_file, uri, group)
	GBookmarkFile *bookmark_file
	const gchar *uri
	const gchar *group
    PREINIT:
        GError *err = NULL;
    CODE:
        RETVAL = g_bookmark_file_has_group (bookmark_file, uri, group, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
        RETVAL

=for apidoc __gerror__
Retrieves the list of group names of the bookmark for $uri.
=cut
void
g_bookmark_file_get_groups (GBookmarkFile *bookmark_file, const gchar *uri)
    PREINIT:
        GError *err = NULL;
	gchar **groups;
	gsize len, i;
    PPCODE:
        groups = g_bookmark_file_get_groups (bookmark_file, uri, &len, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
	if (len != 0) {
		for (i = 0; i < len; i++) {
			if (groups[i])
				XPUSHs (sv_2mortal (newSVGChar (groups[i])));
		}
	}
	g_strfreev (groups);

=for apidoc __gerror__
Removes $group from the list of groups to which the bookmark
for $uri belongs to.
=cut
void
g_bookmark_file_remove_group (bookmark_file, uri, group)
	GBookmarkFile *bookmark_file
	const gchar *uri
	const gchar *group
    PREINIT:
        GError *err = NULL;
    CODE:
        g_bookmark_file_remove_group (bookmark_file, uri, group, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc
Adds the application with $name and $exec to the list of
applications that have registered a bookmark for $uri into
$bookmark_file.

Every bookmark inside a C<Glib::BookmarkFile> must have at least an
application registered.  Each application must provide a name, a
command line useful for launching the bookmark, the number of times
the bookmark has been registered by the application and the last
time the application registered this bookmark.

If $name is undef, the name of the application will be the
same returned by Glib::get_application_name(); if $exec is undef,
the command line will be a composition of the program name as
returned by Glib::get_prgname() and the "%u" modifier, which will
be expanded to the bookmark's URI.

This function will automatically take care of updating the
registrations count and timestamping in case an application
with the same $name had already registered a bookmark for
$uri inside the bookmark file.  If no bookmark for $uri is found
one is created.
=cut
void
g_bookmark_file_add_application (bookmark_file, uri, name, exec)
	GBookmarkFile *bookmark_file
	const gchar *uri
	const gchar_ornull *name
	const gchar_ornull *exec

=for apidoc __gerror__
Checks whether the bookmark for $uri inside $bookmark_file has
been registered by application $name.
=cut
gboolean
g_bookmark_file_has_application (bookmark_file, uri, name)
	GBookmarkFile *bookmark_file
	const gchar *uri
	const gchar *name
    PREINIT:
        GError *err = NULL;
    CODE:
    	RETVAL = g_bookmark_file_has_application (bookmark_file,
						  uri,
						  name,
						  &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
        RETVAL

=for apidoc __gerror__
Removes application registered with $name from the list of applications
that have registered a bookmark for $uri inside $bookmark_file.
=cut
void
g_bookmark_file_remove_application (bookmark_file, uri, name)
	GBookmarkFile *bookmark_file
	const gchar *uri
	const gchar *name
    PREINIT:
        GError *err = NULL;
    CODE:
        g_bookmark_file_remove_application (bookmark_file, uri, name, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc __gerror__
=signature list = $bookmark_file->get_applications ($uri)
Retrieves the names of the applications that have registered the
bookmark for $uri.
=cut
void
g_bookmark_file_get_applications (bookmark_file, uri)
	GBookmarkFile *bookmark_file
	const gchar *uri
    PREINIT:
    	gchar **apps;
	gsize len, i;
	GError *err = NULL;
    PPCODE:
    	apps = g_bookmark_file_get_applications (bookmark_file, uri, &len, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
	if (len != 0) {
		for (i = 0; i < len; i++) {
			if (apps[i])
				XPUSHs (sv_2mortal (newSVGChar (apps[i])));
		}
	}
	g_strfreev (apps);

=for apidoc __gerror__
Sets the meta-data of application $name inside the list of
applications that have registered a bookmark for $uri inside
$bookmark_file.

You should rarely use this method; use Glib::BookmarkFile::add_application()
and Glib::BookmarkFile::remove_application() instead.

$name can be any UTF-8 encoded string used to identify an application.
$exec can have one of these two modifiers: "%f", which will be expanded
as the local file name retrieved from the bookmark's URI; "%u", which
will be expanded as the bookmark's URI. The expansion is done automatically
when retrieving the stored command line using the
Glib::BookmarkFile::get_app_info() method.
$count is the number of times the application has registered the
bookmark; if it is < 0, the current registration count will be increased
by one, if it is 0, the application with $name will be removed from
the list of registered applications.
$stamp is the Unix time of the last registration, as returned by time(); if
it is -1, the current time will be used.

If you try to remove an application by setting its registration count to
zero, and no bookmark for $uri is found, %FALSE is returned and an
exception is fired.
=cut
void
g_bookmark_file_set_app_info (bookmark_file, uri, name, exec, count, stamp)
	GBookmarkFile *bookmark_file
	const gchar *uri
	const gchar *name
	const gchar *exec
	gint count
	time_t stamp
    PREINIT:
    	GError *err = NULL;
    CODE:
    	g_bookmark_file_set_app_info (bookmark_file, uri, name,
				      exec,
				      count,
				      stamp,
				      &err);
	if (err)
		gperl_croak_gerror (NULL, err);

=for apidoc __gerror__
=signature ($exec, $count, $stamp) = $bookmark_file->get_app_info ($uri, $name)
Gets the registration information of $name for the bookmark for
$uri.  See Glib::BookmarkFile::set_app_info() for more information about
the returned data.
=cut
void
g_bookmark_file_get_app_info (bookmark_file, uri, name)
	GBookmarkFile *bookmark_file
	const gchar *uri
	const gchar *name
    PREINIT:
    	gchar *exec;
	guint count;
	time_t stamp;
        GError *err = NULL;
    PPCODE:
        g_bookmark_file_get_app_info (bookmark_file, uri, name,
				      &exec,
				      &count,
				      &stamp,
				      &err);
	if (err)
		gperl_croak_gerror (NULL, err);
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSVGChar (exec)));
	PUSHs (sv_2mortal (newSViv (count)));
	PUSHs (sv_2mortal (newSViv (stamp)));
	g_free (exec);

=for apidoc
=cut
void
g_bookmark_file_set_is_private (GBookmarkFile *bookmark_file, const gchar *uri, gboolean is_private)

=for apidoc __gerror__
=cut
gboolean
g_bookmark_file_get_is_private (GBookmarkFile *bookmark_file, const gchar *uri)
    PREINIT:
        GError *err = NULL;
    CODE:
    	RETVAL = g_bookmark_file_get_is_private (bookmark_file, uri, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
        RETVAL

=for apidoc
Sets the icon for the bookmark for $uri.  If $href is undef, unsets
the currently set icon.
=cut
void
g_bookmark_file_set_icon (bookmark_file, uri, href, mime_type)
	GBookmarkFile *bookmark_file
	const gchar *uri
	const gchar_ornull *href
	const gchar_ornull *mime_type

=for apidoc __gerror__
=signature ($href, $mime_type) = $bookmark_file->get_icon ($uri)
Gets the icon of the bookmark for $uri.
=cut
void
g_bookmark_file_get_icon (GBookmarkFile *bookmark_file, const gchar *uri)
    PREINIT:
        gchar *href, *mime_type;
        GError *err = NULL;
    PPCODE:
        g_bookmark_file_get_icon (bookmark_file, uri,
				  &href,
				  &mime_type,
				  &err);
	if (err)
		gperl_croak_gerror (NULL, err);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVGChar (href)));
	PUSHs (sv_2mortal (newSVGChar (mime_type)));
	g_free (href);
	g_free (mime_type);

=for apidoc Glib::BookmarkFile::get_added
=for apidoc __gerror__
Gets the time the bookmark for $uri was added to $bookmark_file.
=cut

=for apidoc Glib::BookmarkFile::get_modified
=for apidoc __gerror__
Gets the time the bookmark for $uri was last modified.
=cut

=for apidoc Glib::BookmarkFile::get_visited
=for apidoc __gerror__
Gets the time the bookmark for $uri was last visited.
=cut

time_t
g_bookmark_file_get_added (bookmark_file, uri)
	GBookmarkFile *bookmark_file
	const gchar *uri
    ALIAS:
        Glib::BookmarkFile::get_modified = 1
	Glib::BookmarkFile::get_visited  = 2
    PREINIT:
        GError *err = NULL;
    CODE:
        switch (ix) {
	    case 0:
		RETVAL = g_bookmark_file_get_added    (bookmark_file, uri, &err);
		break;
	    case 1:
		RETVAL = g_bookmark_file_get_modified (bookmark_file, uri, &err);
		break;
	    case 2:
		RETVAL = g_bookmark_file_get_visited  (bookmark_file, uri, &err);
		break;
	    default:
		RETVAL = 0;
		g_assert_not_reached ();
		break;
	}
	if (err)
		gperl_croak_gerror (NULL, err);
    OUTPUT:
        RETVAL

=for apidoc Glib::BookmarkFile::set_added
Sets the time the bookmark for $uri was added.
If no bookmark for $uri is found one is created.
=cut

=for apidoc Glib::BookmarkFile::set_modified
Sets the time the bookmark for $uri was last modified.
If no bookmark for $uri is found one is created.
=cut

=for apidoc Glib::BookmarkFile::set_visited
Sets the time the bookmark for $uri was last visited.
If no bookmark for $uri is found one is created.
=cut

void
g_bookmark_file_set_added (bookmark_file, uri, value)
	GBookmarkFile *bookmark_file
	const gchar *uri
	time_t value
    ALIAS:
        Glib::BookmarkFile::set_modified = 1
	Glib::BookmarkFile::set_visited  = 2
    CODE:
        switch (ix) {
		case 0:
		g_bookmark_file_set_added    (bookmark_file, uri, value); break;
		case 1:
		g_bookmark_file_set_modified (bookmark_file, uri, value); break;
		case 2:
		g_bookmark_file_set_visited  (bookmark_file, uri, value); break;
		default:
			g_assert_not_reached ();
			break;
	}
