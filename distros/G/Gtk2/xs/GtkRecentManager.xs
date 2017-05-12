/*
 * Copyright (C) 2006, 2010 by the gtk2-perl team (see the file AUTHORS for a
 * complete listing)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "gtk2perl.h"

/* Also used in GtkRecentFilter.xs */
const gchar **
gtk2perl_sv_to_strv (SV *sv)
{
	AV *av;
	SV **svp;
	int i;
	gchar **retval;

	if (!gperl_sv_is_array_ref (sv))
		croak ("invalid groups value - expecting an array reference");

	av = (AV *) SvRV (sv);
	retval = gperl_alloc_temp (sizeof (gchar*) * (av_len (av) + 2));
	for (i = 0; i <= av_len (av); i++)
		if ((svp = av_fetch (av, i, 0)))
			retval[i] = SvGChar (*svp);
	retval[i] = NULL;

	return (const gchar **) retval;
}

/* Used in GtkRecentFilter.xs */
SV *
gtk2perl_sv_from_strv (const gchar **strv)
{
	AV *av;
	int i;

	av = newAV ();
	i = 0;
	while (strv[i])
		av_push (av, newSVGChar (strv[i++]));

	return newRV_noinc ((SV *) av);
}

/*
struct _GtkRecentData
{
  gchar *display_name;
  gchar *description;

  gchar *mime_type;

  gchar *app_name;
  gchar *app_exec;

  gchar **groups;

  gboolean is_private;
};
*/

static GtkRecentData *
SvGtkRecentData (SV *sv)
{
  GtkRecentData *data;
  HV *hv;
  SV **svp;

  if (!gperl_sv_is_hash_ref (sv))
	  croak ("invalid recent data - expecting a hash reference");

  hv = (HV *) SvRV (sv);

  data = gperl_alloc_temp (sizeof (GtkRecentData));

  if ((svp = hv_fetch (hv, "display_name", 12, 0)))
	  data->display_name = SvGChar (*svp);

  if ((svp = hv_fetch (hv, "description", 11, 0)))
	  data->description = SvGChar (*svp);

  if ((svp = hv_fetch (hv, "mime_type", 9, 0)))
	  data->mime_type = SvGChar (*svp);

  if ((svp = hv_fetch (hv, "app_name", 8, 0)))
	  data->app_name = SvGChar (*svp);

  if ((svp = hv_fetch (hv, "app_exec", 8, 0)))
	  data->app_exec = SvGChar (*svp);

  if ((svp = hv_fetch (hv, "is_private", 10, 0)))
	  data->is_private = SvIV (*svp);

  if ((svp = hv_fetch (hv, "groups", 6, 0)))
	  data->groups = (gchar **) gtk2perl_sv_to_strv (*svp);

  return data;
}

MODULE = Gtk2::RecentManager	PACKAGE = Gtk2::RecentManager	PREFIX = gtk_recent_manager_


=for enum GtkRecentManagerError
=cut

GtkRecentManager_noinc *
gtk_recent_manager_new (class)
    C_ARGS:
        /* void */

GtkRecentManager *
gtk_recent_manager_get_default (class)
    C_ARGS:
        /* void */

GtkRecentManager *
gtk_recent_manager_get_for_screen (class, GdkScreen *screen)
    C_ARGS:
        screen

void
gtk_recent_manager_set_screen (GtkRecentManager *manager, GdkScreen *screen)

=for apidoc
Add I<$uri> to the list of recently used documents.  The Gtk2::RecentManager
object will try to guess the meta-data of the document from its URI, but if
you know it you should use C<add_full> above.
=cut
gboolean
gtk_recent_manager_add_item (GtkRecentManager *manager, const gchar *uri)

=for apidoc
Add I<$uri> to the list of recently used documents.  Instead of letting the
Gtk2::RecentManager object guess the meta-data, use I<$data> to supply it.
I<$data> is a hash reference with these keys:

=over

=item display_name

The name to be used when displaying the document inside the recently used
documents list.

=item description

A short description of the document.

=item mime_type

The MIME type of the document. [Mandatory]

=item app_name

The name of the application that is registering the document.  You might
use the same name you used in C<Glib::set_application_name>
(see L<Glib::Utils>).

=item app_exec

The command line needed to launch the application with the document.  You
can use the variable C<"%u">, which will be expanded to the document's URI,
or the variable C<"%f"> which will be expanded to the document's canonical
full path.

=item groups

An array reference, containing the group names the document belongs to.

=item is_private

Whether the document should be visible only to the applications and groups
that have registered it.

=back

=cut
gboolean
gtk_recent_manager_add_full (GtkRecentManager *manager, const gchar *uri, SV *data)
    C_ARGS:
        manager, uri, SvGtkRecentData (data)

=for apidoc __gerror__
=cut
void
gtk_recent_manager_remove_item (GtkRecentManager *manager, const gchar *uri)
    PREINIT:
        GError *error = NULL;
    CODE:
        gtk_recent_manager_remove_item (manager, uri, &error);
	if (error)
		gperl_croak_gerror (NULL, error);

=for apidoc __gerror__
=cut
GtkRecentInfo *
gtk_recent_manager_lookup_item (GtkRecentManager *manager, const gchar *uri)
    PREINIT:
        GError *error = NULL;
    CODE:
        RETVAL = gtk_recent_manager_lookup_item (manager, uri, &error);
	if (error)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
        RETVAL

gboolean
gtk_recent_manager_has_item (GtkRecentManager *manager, const gchar *uri)

=for apidoc __gerror__
=cut
void
gtk_recent_manager_move_item (manager, old_uri, new_uri)
	GtkRecentManager *manager
	const gchar *old_uri
	const gchar_ornull *new_uri
    PREINIT:
        GError *error = NULL;
    CODE:
        gtk_recent_manager_move_item (manager, old_uri, new_uri, &error);
	if (error)
		gperl_croak_gerror (NULL, error);

void
gtk_recent_manager_set_limit (GtkRecentManager *manager, gint limit)

gint
gtk_recent_manager_get_limit (GtkRecentManager *manager)

=for apidoc
=for signature (items) = $manager->get_items
=cut
void
gtk_recent_manager_get_items (GtkRecentManager *manager)
    PREINIT:
        GList *items, *l;
    PPCODE:
        items = gtk_recent_manager_get_items (manager);
	for (l = items; l != NULL; l = l->next)
		XPUSHs (sv_2mortal (newSVGtkRecentInfo_own (l->data)));
	g_list_free (items);

=for apidoc __gerror__
=cut
gint
gtk_recent_manager_purge_items (GtkRecentManager *manager)
    PREINIT:
        GError *error = NULL;
    CODE:
        RETVAL = gtk_recent_manager_purge_items (manager, &error);
	if (error)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
        RETVAL

#
# GtkRecentInfo
#

MODULE = Gtk2::RecentManager	PACKAGE = Gtk2::RecentInfo	PREFIX = gtk_recent_info_

# not needed
##GtkRecentInfo *gtk_recent_info_ref   (GtkRecentInfo  *info);
##void           gtk_recent_info_unref (GtkRecentInfo  *info);

=for apidoc Gtk2::RecentInfo::get_uri
=for signature string = $info->get_uri
=cut

=for apidoc Gtk2::RecentInfo::get_display_name
=for signature string = $info->get_display_name
=cut

=for apidoc Gtk2::RecentInfo::get_description
=for signature string = $info->get_description
=cut

=for apidoc Gtk2::RecentInfo::get_mime_type
=for signature string = $info->get_mime_type
=cut

const gchar *
get_uri (GtkRecentInfo *info)
    ALIAS:
        Gtk2::RecentInfo::get_uri          = 0
        Gtk2::RecentInfo::get_display_name = 1
	Gtk2::RecentInfo::get_description  = 2
	Gtk2::RecentInfo::get_mime_type    = 3
    CODE:
        switch (ix) {
		case 0: RETVAL = gtk_recent_info_get_uri          (info); break;
		case 1: RETVAL = gtk_recent_info_get_display_name (info); break;
		case 2: RETVAL = gtk_recent_info_get_description  (info); break;
		case 3: RETVAL = gtk_recent_info_get_mime_type    (info); break;
		default:
			RETVAL = NULL;
			g_assert_not_reached ();
	}
    OUTPUT:
        RETVAL


=for apidoc Gtk2::RecentInfo::get_added
=for signature timestamp = $info->get_added;
cut

=for apidoc Gtk2::RecentInfo::get_modified
=for signature timestamp = $info->get_modified;
cut

=for apidoc Gtk2::RecentInfo::get_visited
=for signature timestamp = $info->get_visited;
=cut

time_t
get_added (GtkRecentInfo *info)
    ALIAS:
        Gtk2::RecentInfo::get_added    = 0
        Gtk2::RecentInfo::get_modified = 1
	Gtk2::RecentInfo::get_visited  = 2
    CODE:
        switch (ix) {
		case 0: RETVAL = gtk_recent_info_get_added    (info); break;
		case 1: RETVAL = gtk_recent_info_get_modified (info); break;
		case 2: RETVAL = gtk_recent_info_get_visited  (info); break;
		default:
			RETVAL = (time_t) -1;
			g_assert_not_reached ();
	}
    OUTPUT:
        RETVAL


gboolean
gtk_recent_info_get_private_hint (GtkRecentInfo *info)


=for apidoc
=for signature (exec, count, timestamp) = $info->get_application_info ($app_name)
=cut
void
gtk_recent_info_get_application_info (info, app_name)
	GtkRecentInfo *info
	const gchar *app_name
    PREINIT:
	const gchar *app_exec;
	guint count;
	time_t timestamp;
	gboolean res;
    PPCODE:
        res = gtk_recent_info_get_application_info (info, app_name,
						    &app_exec,
						    &count,
						    &timestamp);
	if (!res)
		XSRETURN_EMPTY;
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSVGChar (app_exec)));
	PUSHs (sv_2mortal (newSVuv (count)));
	PUSHs (sv_2mortal (newSViv (timestamp)));

=for apidoc
=for signature (applications) = $info->get_applications
=cut
void
gtk_recent_info_get_applications (GtkRecentInfo *info)
    PREINIT:
        gchar **apps;
        gsize length, i;
    PPCODE:
        apps = gtk_recent_info_get_applications (info, &length);
	if (length > 0) {
		EXTEND (SP, length);
		for (i = 0; i < length; i++) {
			if (apps[i])
				PUSHs (sv_2mortal (newSVGChar (apps[i])));
		}
		g_strfreev (apps);
	}
	else
		XSRETURN_EMPTY;

gchar_own *
gtk_recent_info_last_application (GtkRecentInfo *info)

gboolean
gtk_recent_info_has_application (GtkRecentInfo *info, const gchar *app_name)

=for apidoc
=for signature (groups) = $info->get_groups
=cut
void
gtk_recent_info_get_groups (GtkRecentInfo *info)
    PREINIT:
        gchar **groups;
	gsize length, i;
    PPCODE:
        groups = gtk_recent_info_get_groups (info, &length);
	if (length > 0) {
		EXTEND (SP, length);
		for (i = 0; i < length; i++) {
			if (groups[i])
				PUSHs (sv_2mortal (newSVGChar (groups[i])));
		}
		g_strfreev (groups);
	}
	else
		XSRETURN_EMPTY;

gboolean
gtk_recent_info_has_group (GtkRecentInfo *info, const gchar *group_name)

GdkPixbuf_noinc *
gtk_recent_info_get_icon (GtkRecentInfo *info, gint size)

gchar_own *
gtk_recent_info_get_short_name (GtkRecentInfo *info)

gchar_own *
gtk_recent_info_get_uri_display (GtkRecentInfo *info)

gint
gtk_recent_info_get_age (GtkRecentInfo *info)

gboolean
gtk_recent_info_is_local (GtkRecentInfo *info)

gboolean
gtk_recent_info_exists (GtkRecentInfo *info)

gboolean
gtk_recent_info_match (GtkRecentInfo *info, GtkRecentInfo *other_info)
