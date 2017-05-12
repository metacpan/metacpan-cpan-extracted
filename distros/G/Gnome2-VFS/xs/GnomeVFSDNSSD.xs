/*
 * Copyright (C) 2004, 2013 by the gtk2-perl team
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
#include <gperl_marshal.h>

/* ------------------------------------------------------------------------- */

static SV *
newSVGnomeVFSDNSSDService (GnomeVFSDNSSDService *service)
{
	HV *hv = newHV ();

	if (service->name)
		hv_store (hv, "name", 4, newSVpv (service->name, 0), 0);
	if (service->type)
		hv_store (hv, "type", 4, newSVpv (service->type, 0), 0);
	if (service->domain)
		hv_store (hv, "domain", 6, newSVpv (service->domain, 0), 0);

	return newRV_noinc ((SV *) hv);
}

/* ------------------------------------------------------------------------- */

static void
hash_table_foreach (char *key, char *value, HV *hv)
{
	if (key)
		hv_store (hv, key, strlen (key),
		          value ? newSVpv (value, 0) : &PL_sv_undef, 0);
}

static SV *
newSVGnomeVFSDNSSDResolveHashTable (GHashTable *table)
{
	HV *hv = newHV ();

	if (table)
		g_hash_table_foreach (table, (GHFunc) hash_table_foreach, hv);

	return newRV_noinc ((SV *) hv);
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_dns_sd_resolve_callback_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static void
vfs2perl_dns_sd_resolve_callback (GnomeVFSDNSSDResolveHandle *handle,
                                  GnomeVFSResult result,
                                  const GnomeVFSDNSSDService *service,
                                  const char *host,
                                  int port,
                                  const GHashTable *text,
                                  int text_raw_len,
                                  const char *text_raw,
                                  GPerlCallback* callback)
{
	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 7);
	PUSHs (sv_2mortal (newSVGnomeVFSDNSSDResolveHandle (handle)));
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSDNSSDService ((GnomeVFSDNSSDService *) service)));
	PUSHs (host ? sv_2mortal (newSVpv (host, 0)) : &PL_sv_undef);
	PUSHs (sv_2mortal (newSViv (port)));
	PUSHs (sv_2mortal (newSVGnomeVFSDNSSDResolveHashTable ((GHashTable *) text)));
	PUSHs (text_raw ? sv_2mortal (newSVpv (text_raw, text_raw_len)) : &PL_sv_undef);
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_dns_sd_browse_callback_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static void
vfs2perl_dns_sd_browse_callback (GnomeVFSDNSSDBrowseHandle *handle,
                                 GnomeVFSDNSSDServiceStatus status,
                                 const GnomeVFSDNSSDService *service,
                                 GPerlCallback* callback)
{
	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSVGnomeVFSDNSSDBrowseHandle (handle)));
	PUSHs (sv_2mortal (newSVGnomeVFSDNSSDServiceStatus (status)));
	PUSHs (sv_2mortal (newSVGnomeVFSDNSSDService ((GnomeVFSDNSSDService *) service)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::VFS::DNSSD	PACKAGE = Gnome2::VFS::DNSSD	PREFIX = gnome_vfs_dns_sd_

##  GnomeVFSResult gnome_vfs_dns_sd_browse (GnomeVFSDNSSDBrowseHandle **handle, const char *domain, const char *type, GnomeVFSDNSSDBrowseCallback callback, gpointer callback_data, GDestroyNotify callback_data_destroy_func)
void
gnome_vfs_dns_sd_browse (class, domain, type, func, data = NULL)
	const char *domain
	const char *type
	SV *func
	SV *data
    PREINIT:
	GnomeVFSDNSSDBrowseHandle *handle;
	GnomeVFSResult result;
	GPerlCallback *callback;
    PPCODE:
	callback = vfs2perl_dns_sd_browse_callback_create (func, data);

	result = gnome_vfs_dns_sd_browse (&handle,
	                                  domain,
	                                  type,
	                                  (GnomeVFSDNSSDBrowseCallback)
	                                    vfs2perl_dns_sd_browse_callback,
	                                  callback,
	                                  (GDestroyNotify)
	                                    gperl_callback_destroy);

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSDNSSDBrowseHandle (handle)));

##  GnomeVFSResult gnome_vfs_dns_sd_resolve (GnomeVFSDNSSDResolveHandle **handle, const char *name, const char *type, const char *domain, int timeout, GnomeVFSDNSSDResolveCallback callback, gpointer callback_data, GDestroyNotify callback_data_destroy_func)
void
gnome_vfs_dns_sd_resolve (class, name, type, domain, timeout, func, data=NULL)
	const char *name
	const char *type
	const char *domain
	int timeout
	SV *func
	SV *data
    PREINIT:
	GnomeVFSDNSSDResolveHandle *handle;
	GnomeVFSResult result;
	GPerlCallback *callback;
    PPCODE:
	callback = vfs2perl_dns_sd_resolve_callback_create (func, data);

	result = gnome_vfs_dns_sd_resolve (&handle,
	                                   name,
	                                   type,
	                                   domain,
	                                   timeout,
	                                   (GnomeVFSDNSSDResolveCallback)
	                                     vfs2perl_dns_sd_resolve_callback,
	                                   callback,
	                                   (GDestroyNotify)
	                                     gperl_callback_destroy);

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSDNSSDResolveHandle (handle)));

##  GnomeVFSResult gnome_vfs_dns_sd_browse_sync (const char *domain, const char *type, int timeout_msec, int *n_services, GnomeVFSDNSSDService **services)
void
gnome_vfs_dns_sd_browse_sync (class, domain, type, timeout_msec)
	const char *domain
	const char *type
	int timeout_msec
    PREINIT:
	GnomeVFSResult result;
	int n_services, i;
	GnomeVFSDNSSDService *services = NULL;
    PPCODE:
	result = gnome_vfs_dns_sd_browse_sync (domain, type, timeout_msec, &n_services, &services);

	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));

	if (result == GNOME_VFS_OK && services) {
		for (i = 0; i < n_services; i++) {
			XPUSHs (sv_2mortal (newSVGnomeVFSDNSSDService (&services[i])));
		}
		gnome_vfs_dns_sd_service_list_free (services, n_services);
	}

##  GnomeVFSResult gnome_vfs_dns_sd_resolve_sync (const char *name, const char *type, const char *domain, int timeout_msec, char **host, int *port, GHashTable **text, int *text_raw_len, char **text_raw)
void
gnome_vfs_dns_sd_resolve_sync (class, name, type, domain, timeout_msec)
	const char *name
	const char *type
	const char *domain
	int timeout_msec
    PREINIT:
	GnomeVFSResult result;
	char *host = NULL;
	int port;
	GHashTable *text = NULL;
	int text_raw_len;
	char *text_raw = NULL;
    PPCODE:
	result = gnome_vfs_dns_sd_resolve_sync (name, type, domain, timeout_msec, &host, &port, &text, &text_raw_len, &text_raw);

	EXTEND (sp, 5);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (host ? sv_2mortal (newSVpv (host, 0)) : &PL_sv_undef);
	PUSHs (sv_2mortal (newSViv (port)));
	PUSHs (sv_2mortal (newSVGnomeVFSDNSSDResolveHashTable (text)));
	PUSHs (text_raw ? sv_2mortal (newSVpv (text_raw, text_raw_len)) : &PL_sv_undef);

	if (host)
		g_free (host);
	if (text_raw)
		g_free (text_raw);
	if (text)
		g_hash_table_destroy (text);

##  GnomeVFSResult gnome_vfs_dns_sd_list_browse_domains_sync (const char *domain, int timeout_msec, GList **domains)
void
gnome_vfs_dns_sd_list_browse_domains_sync (class, domain, timeout_msec)
	const char *domain
	int timeout_msec
    PREINIT:
	GnomeVFSResult result;
	GList *domains = NULL, *i;
    PPCODE:
	result = gnome_vfs_dns_sd_list_browse_domains_sync (domain, timeout_msec, &domains);

	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));

	if (result == GNOME_VFS_OK) {
		for (i = domains; i; i = i->next) {
			if (i->data) {
				XPUSHs (sv_2mortal (newSVpv (i->data, 0)));
				g_free (i->data);
			}
		}
	}

	g_list_free (domains);

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::DNSSD	PACKAGE = Gnome2::VFS	PREFIX = gnome_vfs_

=for object Gnome2::VFS::DNSSD
=cut

##  GList * gnome_vfs_get_default_browse_domains (void)
void
gnome_vfs_get_default_browse_domains (class)
    PREINIT:
	GList *domains = NULL, *i;
    PPCODE:
	PERL_UNUSED_VAR (ax);
	domains = gnome_vfs_get_default_browse_domains ();

	for (i = domains; i; i = i->next) {
		if (i->data) {
			XPUSHs (sv_2mortal (newSVpv (i->data, 0)));
			g_free (i->data);
		}
	}

	g_list_free (domains);

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::DNSSD	PACKAGE = Gnome2::VFS::DNSSD::Browse::Handle	PREFIX = gnome_vfs_dns_sd_browse_

##  GnomeVFSResult gnome_vfs_dns_sd_stop_browse (GnomeVFSDNSSDBrowseHandle *handle)
GnomeVFSResult
gnome_vfs_dns_sd_browse_stop (handle)
	GnomeVFSDNSSDBrowseHandle *handle
    CODE:
	RETVAL = gnome_vfs_dns_sd_stop_browse (handle);
    OUTPUT:
	RETVAL

MODULE = Gnome2::VFS::DNSSD	PACKAGE = Gnome2::VFS::DNSSD::Resolve::Handle	PREFIX = gnome_vfs_dns_sd_resolve_

##  GnomeVFSResult gnome_vfs_dns_sd_cancel_resolve (GnomeVFSDNSSDResolveHandle *handle)
GnomeVFSResult
gnome_vfs_dns_sd_resolve_cancel (handle)
	GnomeVFSDNSSDResolveHandle *handle
    CODE:
	RETVAL = gnome_vfs_dns_sd_cancel_resolve (handle);
    OUTPUT:
	RETVAL
