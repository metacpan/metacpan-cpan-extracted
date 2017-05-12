/*
 * Copyright (c) 2003, 2013 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"


/*
struct _GtkFileFilterInfo
{
  GtkFileFilterFlags contains;
  
  const gchar *filename;
  const gchar *uri;
  const gchar *display_name;
  const gchar *mime_type;
};
*/

static SV *
newSVGtkFileFilterInfo (const GtkFileFilterInfo * info)
{
	HV * hv;

	if (!info)
		return &PL_sv_undef;

	hv = newHV ();

	gperl_hv_take_sv_s (hv, "contains",
	                    newSVGtkFileFilterFlags (info->contains));
	if (info->filename)
		gperl_hv_take_sv_s (hv, "filename",
		                    gperl_sv_from_filename (info->filename));
	if (info->uri)
		gperl_hv_take_sv_s (hv, "uri",
		                    newSVpv (info->uri, 0));
	if (info->display_name)
		gperl_hv_take_sv_s (hv, "display_name",
		                    newSVGChar (info->display_name));
	if (info->mime_type)
		gperl_hv_take_sv_s (hv, "mime_type",
		                    newSVGChar (info->mime_type));

	return newRV_noinc ((SV*) hv);
}

static GtkFileFilterInfo *
SvGtkFileFilterInfo (SV * sv)
{
	HV * hv;
	SV ** svp;
	GtkFileFilterInfo * info;

	if (!gperl_sv_is_hash_ref (sv))
		croak ("invalid file filter info - expecting a hash reference");

	hv = (HV*) SvRV (sv);

	info = gperl_alloc_temp (sizeof (GtkFileFilterInfo));

	if ((svp = hv_fetch (hv, "contains", 8, 0)))
		info->contains = SvGtkFileFilterFlags (*svp);
	if ((svp = hv_fetch (hv, "filename", 8, 0)))
		info->filename = gperl_filename_from_sv (*svp);
	if ((svp = hv_fetch (hv, "uri", 3, 0)))
		info->uri = SvPV_nolen (*svp);
	if ((svp = hv_fetch (hv, "display_name", 12, 0)))
		info->display_name = SvGChar (*svp);
	if ((svp = hv_fetch (hv, "mime_type", 9, 0)))
		info->mime_type = SvGChar (*svp);

	return info;
}

static gboolean
gtk2perl_file_filter_func (const GtkFileFilterInfo *filter_info,
                           gpointer                 data)
{
	GPerlCallback * callback = (GPerlCallback*) data;
	GValue value = {0,};
	gboolean retval;
	SV * sv;
	g_value_init (&value, G_TYPE_BOOLEAN);
	sv = newSVGtkFileFilterInfo (filter_info);
	gperl_callback_invoke (callback, &value, sv);
	retval = g_value_get_boolean (&value);
	SvREFCNT_dec (sv);
	g_value_unset (&value);
	return retval;
}

MODULE = Gtk2::FileFilter	PACKAGE = Gtk2::FileFilter	PREFIX = gtk_file_filter_

GtkFileFilter * gtk_file_filter_new (class);
    C_ARGS:
	/*void*/

void gtk_file_filter_set_name (GtkFileFilter *filter, const gchar *name);

const gchar *gtk_file_filter_get_name (GtkFileFilter *filter);

void gtk_file_filter_add_mime_type (GtkFileFilter *filter, const gchar *mime_type);

void gtk_file_filter_add_pattern (GtkFileFilter *filter, const gchar *pattern);

 ### /* there appears to be no boxed type support for GtkFileFilterInfo */

void gtk_file_filter_add_custom (GtkFileFilter *filter, GtkFileFilterFlags needed, SV * func, SV * data=NULL);
    PREINIT:
	GType param_types[1];
	GPerlCallback * callback;
    CODE:
	param_types[0] = GPERL_TYPE_SV;
	callback = gperl_callback_new (func, data, 1, param_types, G_TYPE_BOOLEAN);
	gtk_file_filter_add_custom (filter, needed,
	                            gtk2perl_file_filter_func, callback,
	                            (GDestroyNotify)gperl_callback_destroy);

GtkFileFilterFlags gtk_file_filter_get_needed (GtkFileFilter *filter);

###gboolean gtk_file_filter_filter (GtkFileFilter *filter, const GtkFileFilterInfo *filter_info);
gboolean gtk_file_filter_filter (GtkFileFilter *filter, SV *filter_info);
    C_ARGS:
	filter, SvGtkFileFilterInfo (filter_info)

#if GTK_CHECK_VERSION (2, 6, 0)

void gtk_file_filter_add_pixbuf_formats (GtkFileFilter *filter)

#endif
