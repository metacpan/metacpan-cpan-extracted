/*
 * Copyright (C) 2003-2005, 2013 by the gtk2-perl team
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

/* So we get those functions that were deprecated after we bound them. */
#undef GNOME_VFS_DISABLE_DEPRECATED

/* ------------------------------------------------------------------------- */

#if 0

struct Bonobo_ServerInfo_type
{
   Bonobo_ImplementationID iid;
   CORBA_string server_type;
   CORBA_string location_info;
   CORBA_string username;
   CORBA_string hostname;
   CORBA_string domain;
   CORBA_sequence_Bonobo_ActivationProperty props;
};

typedef struct {
        GnomeVFSMimeActionType action_type;
        union {
                Bonobo_ServerInfo *component;
                void *dummy_component;
                GnomeVFSMimeApplication *application;
        } action;
} GnomeVFSMimeAction;

SV *
newSVGnomeVFSMimeAction (GnomeVFSMimeAction *action)
{
	...
}

#endif

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::VFS::Mime	PACKAGE = Gnome2::VFS::Mime	PREFIX = gnome_vfs_mime_

=for apidoc

=for arg ... of GnomeVFSMimeApplication's

=cut
# FIXME: leak.
##  gboolean gnome_vfs_mime_id_in_application_list (const char *id, GList *applications) 
gboolean
gnome_vfs_mime_id_in_application_list (class, id, ...)
	const char *id
    PREINIT:
	int i;
	GList *applications = NULL;
    CODE:
	for (i = 2; i < items; i++)
		applications = g_list_append (applications, SvGnomeVFSMimeApplication (ST (i)));

	RETVAL = gnome_vfs_mime_id_in_application_list (id, applications);

	/* gnome_vfs_mime_application_list_free (applications); */
	g_list_free (applications);
    OUTPUT:
	RETVAL

=for apidoc

=for arg ... of GnomeVFSMimeApplication's

Returns a boolean indicating whether anything was removed and the resulting
list of GnomeVFSMimeApplication's.

=cut
# FIXME: leak.
##  GList * gnome_vfs_mime_remove_application_from_list (GList *applications, const char *application_id, gboolean *did_remove) 
void
gnome_vfs_mime_remove_application_from_list (class, application_id, ...)
	const char *application_id
    PREINIT:
	int i;
	GList *applications = NULL, *result, *j;
	gboolean did_remove;
    PPCODE:
	for (i = 2; i < items; i++)
		applications = g_list_append (applications, SvGnomeVFSMimeApplication (ST (i)));

	result = gnome_vfs_mime_remove_application_from_list (applications, application_id, &did_remove);

	EXTEND (sp, 1);
	PUSHs (sv_2mortal (newSVuv (did_remove)));

	for (j = result; j != NULL; j = j->next) {
		XPUSHs (sv_2mortal (newSVGnomeVFSMimeApplication (j->data)));
		/* gnome_vfs_mime_application_free (j->data); */
	}

	g_list_free (result);

=for apidoc

=for arg ... of GnomeVFSMimeApplication's

Returns a list of application id's.

=cut
# FIXME: leak.
##  GList * gnome_vfs_mime_id_list_from_application_list (GList *applications) 
void
gnome_vfs_mime_id_list_from_application_list (class, ...)
    PREINIT:
	int i;
	GList *applications = NULL, *ids, *j;
    PPCODE:
	for (i = 1; i < items; i++)
		applications = g_list_append (applications, SvGnomeVFSMimeApplication (ST (i)));

	ids = gnome_vfs_mime_id_list_from_application_list (applications);

	for (j = ids; j != NULL; j = j->next) {
		XPUSHs (sv_2mortal (newSVpv (j->data, 0)));
		/* g_free (j->data); */
	}

	g_list_free (applications);
	g_list_free (ids);

# FIXME: Needs bonobo typemaps.
###  gboolean gnome_vfs_mime_id_in_component_list (const char *iid, GList *components) 
#gboolean
#gnome_vfs_mime_id_in_component_list (iid, components)
#	const char *iid
#	GList *components

# FIXME: Needs bonobo typemaps.
###  GList * gnome_vfs_mime_remove_component_from_list (GList *components, const char *iid, gboolean *did_remove) 
#GList *
#gnome_vfs_mime_remove_component_from_list (components, iid, did_remove)
#	GList *components
#	const char *iid
#	gboolean *did_remove

# FIXME: Needs bonobo typemaps.
###  GList * gnome_vfs_mime_id_list_from_component_list (GList *components) 
#GList *
#gnome_vfs_mime_id_list_from_component_list (components)
#	GList *components

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::Mime	PACKAGE = Gnome2::VFS::Mime::Type	PREFIX = gnome_vfs_mime_

SV *
gnome_vfs_mime_new (class, mime_type)
	const char *mime_type
    CODE:
	RETVAL = newSVGnomeVFSMimeType (mime_type);
    OUTPUT:
	RETVAL

##  GnomeVFSMimeActionType gnome_vfs_mime_get_default_action_type (const char *mime_type) 
GnomeVFSMimeActionType
gnome_vfs_mime_get_default_action_type (mime_type)
	GnomeVFSMimeType *mime_type

# FIXME: Needs bonobo typemaps.
###  GnomeVFSMimeAction * gnome_vfs_mime_get_default_action (const char *mime_type) 
#GnomeVFSMimeAction *
#gnome_vfs_mime_get_default_action (mime_type)
#	const char *mime_type

##  GnomeVFSMimeApplication *gnome_vfs_mime_get_default_application (const char *mime_type) 
GnomeVFSMimeApplication *
gnome_vfs_mime_get_default_application (mime_type)
	GnomeVFSMimeType *mime_type

#if VFS_CHECK_VERSION (2, 10, 0)

##  GnomeVFSMimeApplication *gnome_vfs_mime_get_default_application_for_uri (const char *uri, const char *mime_type);
GnomeVFSMimeApplication *
gnome_vfs_mime_get_default_application_for_uri (mime_type, uri)
	GnomeVFSMimeType *mime_type
	const char *uri
    C_ARGS:
	uri, mime_type

#endif

# FIXME: Needs bonobo typemaps.
###  Bonobo_ServerInfo * gnome_vfs_mime_get_default_component (const char *mime_type) 
#Bonobo_ServerInfo *
#gnome_vfs_mime_get_default_component (mime_type)
#	const char *mime_type

=for apidoc

Returns a list of GnomeVFSMimeApplication's.

=cut
##  GList * gnome_vfs_mime_get_short_list_applications (const char *mime_type) 
void
gnome_vfs_mime_get_short_list_applications (mime_type)
	GnomeVFSMimeType *mime_type
    PREINIT:
	GList *i, *applications;
    PPCODE:
	applications = gnome_vfs_mime_get_short_list_applications (mime_type);

	for (i = applications; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGnomeVFSMimeApplication (i->data)));

	/* gnome_vfs_mime_application_list_free (applications); */
	g_list_free (applications);

# FIXME: Needs bonobo typemaps.
###  GList * gnome_vfs_mime_get_short_list_components (const char *mime_type) 
#GList *
#gnome_vfs_mime_get_short_list_components (mime_type)
#	const char *mime_type

=for apidoc

Returns a list of GnomeVFSMimeApplication's.

=cut
##  GList * gnome_vfs_mime_get_all_applications (const char *mime_type) 
void
gnome_vfs_mime_get_all_applications (mime_type)
	GnomeVFSMimeType *mime_type
    PREINIT:
	GList *i, *applications;
    PPCODE:
	applications = gnome_vfs_mime_get_all_applications (mime_type);

	for (i = applications; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGnomeVFSMimeApplication (i->data)));

	/* gnome_vfs_mime_application_list_free (applications); */
	g_list_free (applications);

#if VFS_CHECK_VERSION (2, 10, 0)

##  GList * gnome_vfs_mime_get_all_applications_for_uri (const char *uri, const char *mime_type);
void
gnome_vfs_mime_get_all_applications_for_uri (mime_type, uri)
	GnomeVFSMimeType *mime_type
	const char *uri
    PREINIT:
	GList *i, *applications;
    PPCODE:
	applications = gnome_vfs_mime_get_all_applications_for_uri (uri, mime_type);

	for (i = applications; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGnomeVFSMimeApplication (i->data)));

	/* gnome_vfs_mime_application_list_free (applications); */
	g_list_free (applications);

#endif

# FIXME: Needs bonobo typemaps.
###  GList * gnome_vfs_mime_get_all_components (const char *mime_type) 
#GList *
#gnome_vfs_mime_get_all_components (mime_type)
#	const char *mime_type

##  GnomeVFSResult gnome_vfs_mime_set_default_action_type (const char *mime_type, GnomeVFSMimeActionType action_type) 
GnomeVFSResult
gnome_vfs_mime_set_default_action_type (mime_type, action_type)
	GnomeVFSMimeType *mime_type
	GnomeVFSMimeActionType action_type

##  GnomeVFSResult gnome_vfs_mime_set_default_application (const char *mime_type, const char *application_id) 
GnomeVFSResult
gnome_vfs_mime_set_default_application (mime_type, application_id)
	GnomeVFSMimeType *mime_type
	const char *application_id

# FIXME: Needs bonobo typemaps.
###  GnomeVFSResult gnome_vfs_mime_set_default_component (const char *mime_type, const char *component_iid) 
#GnomeVFSResult
#gnome_vfs_mime_set_default_component (mime_type, component_iid)
#	const char *mime_type
#	const char *component_iid

##  const char *gnome_vfs_mime_get_icon (const char *mime_type) 
const char *
gnome_vfs_mime_get_icon (mime_type)
	GnomeVFSMimeType *mime_type

##  GnomeVFSResult gnome_vfs_mime_set_icon (const char *mime_type, const char *filename) 
GnomeVFSResult
gnome_vfs_mime_set_icon (mime_type, filename)
	GnomeVFSMimeType *mime_type
	const char *filename

##  const char * gnome_vfs_mime_get_description (const char *mime_type) 
const char *
gnome_vfs_mime_get_description (mime_type)
	GnomeVFSMimeType *mime_type

##  GnomeVFSResult gnome_vfs_mime_set_description (const char *mime_type, const char *description) 
GnomeVFSResult
gnome_vfs_mime_set_description (mime_type, description)
	GnomeVFSMimeType *mime_type
	const char *description

##  gboolean gnome_vfs_mime_can_be_executable (const char *mime_type) 
gboolean
gnome_vfs_mime_can_be_executable (mime_type)
	GnomeVFSMimeType *mime_type

##  GnomeVFSResult gnome_vfs_mime_set_can_be_executable (const char *mime_type, gboolean new_value) 
GnomeVFSResult
gnome_vfs_mime_set_can_be_executable (mime_type, new_value)
	GnomeVFSMimeType *mime_type
	gboolean new_value

=for apidoc

=for arg ... of application id's

=cut
# FIXME: leak ...
##  GnomeVFSResult gnome_vfs_mime_set_short_list_applications (const char *mime_type, GList *application_ids) 
GnomeVFSResult
gnome_vfs_mime_set_short_list_applications (mime_type, ...)
	GnomeVFSMimeType *mime_type
    PREINIT:
	GList *application_ids = NULL;
	int i;
    CODE:
	for (i = 1; i < items; i++)
		application_ids = g_list_append (application_ids, SvPV_nolen (ST (i)));

	RETVAL = gnome_vfs_mime_set_short_list_applications (mime_type, application_ids);

	g_list_free (application_ids);
    OUTPUT:
	RETVAL

# FIXME: Needs bonobo typemaps.
###  GnomeVFSResult gnome_vfs_mime_set_short_list_components (const char *mime_type, GList *component_iids) 
#GnomeVFSResult
#gnome_vfs_mime_set_short_list_components (mime_type, component_iids)
#	const char *mime_type
#	GList *component_iids

##  GnomeVFSResult gnome_vfs_mime_add_application_to_short_list (const char *mime_type, const char *application_id) 
GnomeVFSResult
gnome_vfs_mime_add_application_to_short_list (mime_type, application_id)
	GnomeVFSMimeType *mime_type
	const char *application_id

##  GnomeVFSResult gnome_vfs_mime_remove_application_from_short_list (const char *mime_type, const char *application_id) 
GnomeVFSResult
gnome_vfs_mime_remove_application_from_short_list (mime_type, application_id)
	GnomeVFSMimeType *mime_type
	const char *application_id

# FIXME: Needs bonobo typemaps.
###  GnomeVFSResult gnome_vfs_mime_add_component_to_short_list (const char *mime_type, const char *iid) 
#GnomeVFSResult
#gnome_vfs_mime_add_component_to_short_list (mime_type, iid)
#	const char *mime_type
#	const char *iid

# FIXME: Needs bonobo typemaps.
###  GnomeVFSResult gnome_vfs_mime_remove_component_from_short_list (const char *mime_type, const char *iid) 
#GnomeVFSResult
#gnome_vfs_mime_remove_component_from_short_list (mime_type, iid)
#	const char *mime_type
#	const char *iid

##  GnomeVFSResult gnome_vfs_mime_add_extension (const char *mime_type, const char *extension) 
GnomeVFSResult
gnome_vfs_mime_add_extension (mime_type, extension)
	GnomeVFSMimeType *mime_type
	const char *extension

##  GnomeVFSResult gnome_vfs_mime_remove_extension (const char *mime_type, const char *extension) 
GnomeVFSResult
gnome_vfs_mime_remove_extension (mime_type, extension)
	GnomeVFSMimeType *mime_type
	const char *extension

=for apidoc

=for arg ... of application id's

=cut
# FIXME: leak ...
##  GnomeVFSResult gnome_vfs_mime_extend_all_applications (const char *mime_type, GList *application_ids) 
GnomeVFSResult
gnome_vfs_mime_extend_all_applications (mime_type, ...)
	GnomeVFSMimeType *mime_type
    PREINIT:
	GList *application_ids = NULL;
	int i;
    CODE:
	for (i = 1; i < items; i++)
		application_ids = g_list_append (application_ids, SvPV_nolen (ST (i)));

	RETVAL = gnome_vfs_mime_extend_all_applications (mime_type, application_ids);

	g_list_free (application_ids);
    OUTPUT:
	RETVAL

=for apidoc

=for arg ... of application id's

=cut
# FIXME: leak ...
##  GnomeVFSResult gnome_vfs_mime_remove_from_all_applications (const char *mime_type, GList *application_ids) 
GnomeVFSResult
gnome_vfs_mime_remove_from_all_applications (mime_type, ...)
	GnomeVFSMimeType *mime_type
    PREINIT:
	GList *application_ids = NULL;
	int i;
    CODE:
	for (i = 1; i < items; i++)
		application_ids = g_list_append (application_ids, SvPV_nolen (ST (i)));

	RETVAL = gnome_vfs_mime_remove_from_all_applications (mime_type, application_ids);

	g_list_free (application_ids);
    OUTPUT:
	RETVAL

#if VFS_CHECK_VERSION (2, 8, 0)

##  GList *gnome_vfs_mime_get_all_desktop_entries (const char *mime_type)
void
gnome_vfs_mime_get_all_desktop_entries (mime_type)
      GnomeVFSMimeType *mime_type
    PREINIT:
	GList *result = NULL, *i;
    PPCODE:
	result = gnome_vfs_mime_get_all_desktop_entries (mime_type);

	for (i = result; i; i = i->next) {
		if (i->data) {
			XPUSHs (sv_2mortal (newSVpv (i->data, 0)));
			g_free (i->data);
		}
	}

	g_list_free (result);

##  gchar *gnome_vfs_mime_get_default_desktop_entry (const char *mime_type)
gchar_own *
gnome_vfs_mime_get_default_desktop_entry (mime_type)
      GnomeVFSMimeType *mime_type

##  GnomeVFSMimeEquivalence gnome_vfs_mime_type_get_equivalence (const char *mime_type, const char *base_mime_type)
GnomeVFSMimeEquivalence
gnome_vfs_mime_get_equivalence (mime_type, base_mime_type)
	GnomeVFSMimeType *mime_type
	GnomeVFSMimeType *base_mime_type
    CODE:
	RETVAL = gnome_vfs_mime_type_get_equivalence (mime_type, base_mime_type);
    OUTPUT:
	RETVAL

##  gboolean gnome_vfs_mime_type_is_equal (const char *a, const char *b)
gboolean
gnome_vfs_mime_is_equal (a, b)
	GnomeVFSMimeType *a
	GnomeVFSMimeType *b
    CODE:
	RETVAL = gnome_vfs_mime_type_is_equal (a, b);
    OUTPUT:
	RETVAL

#endif

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::Mime	PACKAGE = Gnome2::VFS::Mime::Application	PREFIX = gnome_vfs_mime_application_

void
DESTROY (GnomeVFSMimeApplication *application)
    CODE:
	gnome_vfs_mime_application_free (application);

##  GnomeVFSMimeApplication *gnome_vfs_mime_application_new_from_id (const char *id) 
GnomeVFSMimeApplication *
gnome_vfs_mime_application_new_from_id (class, id)
	const char *id
    C_ARGS:
	id

#if VFS_CHECK_VERSION (2, 10, 0)

##  GnomeVFSMimeApplication *gnome_vfs_mime_application_new_from_desktop_id (const char *id);
GnomeVFSMimeApplication *
gnome_vfs_mime_application_new_from_desktop_id (class, id)
	const char *id
    C_ARGS:
	id

#endif

#if VFS_CHECK_VERSION (2, 4, 0)

=for apidoc

=for arg ... of URI strings

=cut
##  GnomeVFSResult gnome_vfs_mime_application_launch (GnomeVFSMimeApplication *app, GList *uris) 
GnomeVFSResult
gnome_vfs_mime_application_launch (app, ...)
	GnomeVFSMimeApplication *app
    PREINIT:
	GList *uris = NULL;
	int i;
    CODE:
	for (i = 1; i < items; i++)
		uris = g_list_append (uris, SvPV_nolen (ST (i)));

	RETVAL = gnome_vfs_mime_application_launch (app, uris);

	g_list_free (uris);
    OUTPUT:
	RETVAL

# FIXME: leak?
##  GnomeVFSResult gnome_vfs_mime_application_launch_with_env (GnomeVFSMimeApplication *app, GList *uris, char **envp) 
GnomeVFSResult
gnome_vfs_mime_application_launch_with_env (app, uri_ref, env_ref)
	GnomeVFSMimeApplication *app
	SV *uri_ref
	SV *env_ref
    PREINIT:
	char **envp;
	GList *uris;
    CODE:
	envp = SvEnvArray (env_ref);
	uris = SvPVGList (uri_ref);

	RETVAL = gnome_vfs_mime_application_launch_with_env (app, uris, envp);

	g_free (envp);
	g_list_free (uris);
    OUTPUT:
	RETVAL

#endif

#if VFS_CHECK_VERSION (2, 10, 0)

const char *gnome_vfs_mime_application_get_desktop_id (GnomeVFSMimeApplication *app);

const char *gnome_vfs_mime_application_get_desktop_file_path (GnomeVFSMimeApplication *app);

const char *gnome_vfs_mime_application_get_name (GnomeVFSMimeApplication *app);

const char *gnome_vfs_mime_application_get_generic_name (GnomeVFSMimeApplication *app);

const char *gnome_vfs_mime_application_get_icon (GnomeVFSMimeApplication *app);

const char *gnome_vfs_mime_application_get_exec (GnomeVFSMimeApplication *app);

const char *gnome_vfs_mime_application_get_binary_name (GnomeVFSMimeApplication *app);

gboolean gnome_vfs_mime_application_supports_uris (GnomeVFSMimeApplication *app);

gboolean gnome_vfs_mime_application_requires_terminal (GnomeVFSMimeApplication *app);

gboolean gnome_vfs_mime_application_supports_startup_notification (GnomeVFSMimeApplication *app);

const char *gnome_vfs_mime_application_get_startup_wm_class (GnomeVFSMimeApplication *app);

#endif

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::Mime	PACKAGE = Gnome2::VFS::Mime::Action	PREFIX = gnome_vfs_mime_action_

##  void gnome_vfs_mime_action_free (GnomeVFSMimeAction *action) 

# FIXME: Needs bonobo typemaps.
###  GnomeVFSResult gnome_vfs_mime_action_launch (GnomeVFSMimeAction *action, GList *uris) 
#GnomeVFSResult
#gnome_vfs_mime_action_launch (action, uris)
#	GnomeVFSMimeAction *action
#	GList *uris

###  GnomeVFSResult gnome_vfs_mime_action_launch_with_env (GnomeVFSMimeAction *action, GList *uris, char **envp) 
#GnomeVFSResult
#gnome_vfs_mime_action_launch_with_env (action, uris, envp)
#	GnomeVFSMimeAction *action
#	GList *uris
#	char **envp

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::Mime	PACKAGE = Gnome2::VFS::Mime::Monitor	PREFIX = gnome_vfs_mime_monitor_
 
##  GnomeVFSMIMEMonitor *gnome_vfs_mime_monitor_get (void)
GnomeVFSMIMEMonitor *
gnome_vfs_mime_monitor_get (class)
    C_ARGS:
	/* void */

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::Mime	PACKAGE = Gnome2::VFS	PREFIX = gnome_vfs_

=for object Gnome2::VFS::Mime
=cut

##  char *gnome_vfs_get_mime_type (const char *text_uri)
char_own *
gnome_vfs_get_mime_type (class, text_uri)
	const char *text_uri
    C_ARGS:
	text_uri

##  const char *gnome_vfs_get_mime_type_for_data (gconstpointer data, int data_size)
const char *
gnome_vfs_get_mime_type_for_data (class, data)
	SV *data
    PREINIT:
	STRLEN data_size;
	gconstpointer real_data;
    CODE:
	real_data = SvPV (data, data_size);
	RETVAL = gnome_vfs_get_mime_type_for_data (real_data, data_size);
    OUTPUT:
	RETVAL

#if VFS_CHECK_VERSION (2, 14, 0)

# char * gnome_vfs_get_slow_mime_type (const char *text_uri);
char_own * gnome_vfs_get_slow_mime_type (class, const char *text_uri)
    C_ARGS:
	text_uri

# const char * gnome_vfs_get_mime_type_for_name (const char *filename);
const char *
gnome_vfs_get_mime_type_for_name (class, const char *filename)
    C_ARGS:
	filename

# const char * gnome_vfs_get_mime_type_for_name_and_data (const char *filename, gconstpointer data, gssize data_size);
const char *
gnome_vfs_get_mime_type_for_name_and_data (class, filename, data)
	const char *filename
	SV *data
    PREINIT:
	STRLEN data_size;
	gconstpointer real_data;
    CODE:
	real_data = SvPV (data, data_size);
	RETVAL = gnome_vfs_get_mime_type_for_name_and_data (filename, real_data, data_size);
    OUTPUT:
	RETVAL

#endif
