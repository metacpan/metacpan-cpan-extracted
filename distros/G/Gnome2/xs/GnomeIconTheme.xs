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

/* gnome-icon-theme.h was deprecated in 2003. */
#undef GNOME_DISABLE_DEPRECATED

#ifdef GNOME_TYPE_ICON_THEME

static SV * 
newSVGnomeIconData (const GnomeIconData * data)
{
	HV * hv = newHV ();

	if (data) {
		AV * av = newAV ();
		int i;

		for (i = 0; i < data->n_attach_points; i++) {
			AV * av_points = newAV ();
			GnomeIconDataPoint point = (data->attach_points)[i];

			av_store (av_points, 0, newSViv (point.x));
			av_store (av_points, 1, newSViv (point.y));

			av_store (av, i, newRV_noinc ((SV*) av_points));
		}

		hv_store (hv, "has_embedded_rect", 17, newSVuv (data->has_embedded_rect), 0);
		hv_store (hv, "x0", 2, newSViv (data->x0), 0);
		hv_store (hv, "y0", 2, newSViv (data->y0), 0);
		hv_store (hv, "x1", 2, newSViv (data->x1), 0);
		hv_store (hv, "y1", 2, newSViv (data->y1), 0);
		hv_store (hv, "attach_points", 13, newRV_noinc ((SV*) av), 0);
		if (data->display_name)
			hv_store (hv, "display_name", 12, newSVpv (data->display_name, 0), 0);
	}

	return newRV_noinc ((SV *) hv);
}

#if 0 /* not used at the moment */

static GnomeIconData * 
SvGnomeIconData (SV * sv)
{
	HV * hv = (HV*) SvRV (sv);
	SV ** value;
	GnomeIconData * data = gperl_alloc_temp (sizeof (GnomeIconData));

	SV ** points = hv_fetch (hv, "attach_points", 13, FALSE);

	int i;
	AV * av = (AV*) SvRV (*points);

	if (! (sv && SvOK (sv) && SvROK (sv) && SvTYPE (SvRV (sv)) == SVt_PVHV))
		croak ("malformed icon data; use a reference to a hash as icon data");

	/* ----------------------------------------------------------------- */

	value = hv_fetch (hv, "has_embedded_rect", 17, FALSE);
	if (value) data->has_embedded_rect = SvUV (*value);

	value = hv_fetch (hv, "x0", 2, FALSE);
	if (value) data->x0 = SvIV (*value);

	value = hv_fetch (hv, "y0", 2, FALSE);
	if (value) data->y0 = SvIV (*value);

	value = hv_fetch (hv, "x1", 2, FALSE);
	if (value) data->x1 = SvIV (*value);

	value = hv_fetch (hv, "y1", 2, FALSE);
	if (value) data->y1 = SvIV (*value);

	value = hv_fetch (hv, "display_name", 12, FALSE);
	if (value) data->display_name = SvPV_nolen (*value);

	/* ----------------------------------------------------------------- */

	if (! (*points && SvOK (*points) && SvROK (*points) && SvTYPE (SvRV (*points)) == SVt_PVAV))
		croak ("malformed points data; use a reference to an array as points data");

	data->attach_points = gperl_alloc_temp (av_len (av) * sizeof (GnomeIconDataPoint));

	for (i = 0; i <= av_len (av); i++) {
		SV ** point = av_fetch (av, i, FALSE);
		AV * av_point = (AV*) SvRV (*point);

		GnomeIconDataPoint point_data;

		if (! (*point && SvOK (*point) && SvROK (*point) && SvTYPE (SvRV (*point)) == SVt_PVAV))
			croak ("malformed point data; use a reference to an array as point data");

		if (av_len (av) != 1)
			croak ("malformed point data; point data must have two elements");

		point = av_fetch (av_point, 0, FALSE);
		if (point) point_data.x = SvIV (*point);

		point = av_fetch (av_point, 1, FALSE);
		if (point) point_data.y = SvIV (*point);

		(data->attach_points)[i] = point_data;
	}

	/* ----------------------------------------------------------------- */

	return data;
}

#endif

#endif /* GNOME_TYPE_ICON_THEME */

MODULE = Gnome2::IconTheme	PACKAGE = Gnome2::IconTheme	PREFIX = gnome_icon_theme_

BOOT:
/* pass -Werror even if there are no xsubs at all */
#ifndef GNOME_TYPE_ICON_THEME
	PERL_UNUSED_VAR (file);
#endif

#ifdef GNOME_TYPE_ICON_THEME

##  GnomeIconTheme *gnome_icon_theme_new (void) 
GnomeIconTheme *
gnome_icon_theme_new (class)
    C_ARGS:
	/* void */

=for apidoc

=for arg ... of paths

=cut
##  void gnome_icon_theme_set_search_path (GnomeIconTheme *theme, const char *path[], int n_elements) 
void
gnome_icon_theme_set_search_path (theme, ...)
	GnomeIconTheme *theme
    PREINIT:
	int i;
	const char **path = NULL;
    CODE:
	path = g_new0 (const char*, items - 1);

	for (i = 1; i < items; i++)
		path[i - 1] = SvPV_nolen (ST (i));

	gnome_icon_theme_set_search_path (theme, path, i - 1);

=for apidoc

Returns a list of paths.

=cut
##  void gnome_icon_theme_get_search_path (GnomeIconTheme *theme, char **path[], int *n_elements) 
void
gnome_icon_theme_get_search_path (theme)
	GnomeIconTheme *theme
    PREINIT:
	char **path;
	int n_elements, i;
    PPCODE:
	gnome_icon_theme_get_search_path (theme, &path, &n_elements);

	if (path) {
		EXTEND (sp, n_elements);
		for (i = 0; i < n_elements; i++)
			PUSHs (sv_2mortal (newSVpv (path[i], 0)));
	}
	else
		XSRETURN_EMPTY;

##  void gnome_icon_theme_set_allow_svg (GnomeIconTheme *theme, gboolean allow_svg) 
void
gnome_icon_theme_set_allow_svg (theme, allow_svg)
	GnomeIconTheme *theme
	gboolean allow_svg

##  gboolean gnome_icon_theme_get_allow_svg (GnomeIconTheme *theme) 
gboolean
gnome_icon_theme_get_allow_svg (theme)
	GnomeIconTheme *theme

##  void gnome_icon_theme_append_search_path (GnomeIconTheme *theme, const char *path) 
void
gnome_icon_theme_append_search_path (theme, path)
	GnomeIconTheme *theme
	const char *path

##  void gnome_icon_theme_prepend_search_path (GnomeIconTheme *theme, const char *path) 
void
gnome_icon_theme_prepend_search_path (theme, path)
	GnomeIconTheme *theme
	const char *path

##  void gnome_icon_theme_set_custom_theme (GnomeIconTheme *theme, const char *theme_name) 
void
gnome_icon_theme_set_custom_theme (theme, theme_name)
	GnomeIconTheme *theme
	const char *theme_name

=for apidoc

Returns the filename, the icon data and the base size.

=cut
# FIXME: it seems like icon_data never gets filled.
##  char * gnome_icon_theme_lookup_icon (GnomeIconTheme *theme, const char *icon_name, int size, const GnomeIconData **icon_data, int *base_size) 
void
gnome_icon_theme_lookup_icon (theme, icon_name, size)
	GnomeIconTheme *theme
	const char *icon_name
	int size
    PREINIT:
	char *filename;
	const GnomeIconData *icon_data;
	int base_size;
    PPCODE:
	filename = gnome_icon_theme_lookup_icon (theme, icon_name, size, &icon_data, &base_size);

	if (!filename)
		XSRETURN_EMPTY;

	EXTEND (sp, 3);
	PUSHs (sv_2mortal (newSVpv (filename, 0)));
	PUSHs (sv_2mortal (newSVGnomeIconData (icon_data)));
	PUSHs (sv_2mortal (newSViv (base_size)));

	g_free (filename);

##  gboolean gnome_icon_theme_has_icon (GnomeIconTheme *theme, const char *icon_name) 
gboolean
gnome_icon_theme_has_icon (theme, icon_name)
	GnomeIconTheme *theme
	const char *icon_name

=for apidoc

Returns a list of icons.

=cut
##  GList * gnome_icon_theme_list_icons (GnomeIconTheme *theme, const char *context) 
void
gnome_icon_theme_list_icons (theme, context=NULL)
	GnomeIconTheme *theme
	const char *context
    PREINIT:
	GList *i, *results = NULL;
    PPCODE:
	results = gnome_icon_theme_list_icons (theme, context);
	for (i = results; i != NULL; i = i->next) {
		XPUSHs (sv_2mortal (newSVpv (i->data, 0)));
		g_free (i->data);
	}
	g_list_free (results);

##  char * gnome_icon_theme_get_example_icon_name (GnomeIconTheme *theme) 
char *
gnome_icon_theme_get_example_icon_name (theme)
	GnomeIconTheme *theme

##  gboolean gnome_icon_theme_rescan_if_needed (GnomeIconTheme *theme) 
gboolean
gnome_icon_theme_rescan_if_needed (theme)
	GnomeIconTheme *theme

#endif
