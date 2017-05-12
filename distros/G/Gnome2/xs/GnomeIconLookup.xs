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

MODULE = Gnome2::IconLookup	PACKAGE = Gnome2::IconTheme	PREFIX = gnome_icon_

### GnomeIconTheme didn't appear until about 2.0.6, according to the changelogs
### for libgnomeui.

BOOT:
/* pass -Werror even if there are no xsubs at all */
#ifndef GNOME_TYPE_ICON_THEME
	PERL_UNUSED_VAR (file);
#endif

#ifdef GNOME_TYPE_ICON_THEME

=for apidoc

Returns the icon name and a GnomeIconLookupFlags.

=cut
##  char *gnome_icon_lookup (GnomeIconTheme *icon_theme, GnomeThumbnailFactory *thumbnail_factory, const char *file_uri, const char *custom_icon, GnomeVFSFileInfo *file_info, const char *mime_type, GnomeIconLookupFlags flags, GnomeIconLookupResultFlags *result) 
void
gnome_icon_lookup (icon_theme, thumbnail_factory, file_uri, custom_icon, file_info, mime_type, flags)
	 GnomeIconTheme *icon_theme
	 GnomeThumbnailFactory_ornull *thumbnail_factory
	 const char *file_uri
	 SV *custom_icon
	 GnomeVFSFileInfo *file_info
	 const char *mime_type
	 GnomeIconLookupFlags flags
    PREINIT:
	GnomeIconLookupResultFlags result;
	char *icon = NULL;
	const char *real_custom_icon = NULL;
    PPCODE:
	if (SvPOK (custom_icon))
		real_custom_icon = (const char *) SvPV_nolen (custom_icon);

	icon = gnome_icon_lookup (icon_theme, thumbnail_factory, file_uri, real_custom_icon, file_info, mime_type, flags, &result);

	if (icon == NULL)
		XSRETURN_UNDEF;

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVpv (icon, 0)));
	PUSHs (sv_2mortal (newSVGnomeIconLookupFlags (result)));

	g_free (icon);

=for apidoc

Returns the icon name and a GnomeIconLookupFlags.

=cut
##  char *gnome_icon_lookup_sync (GnomeIconTheme *icon_theme, GnomeThumbnailFactory *thumbnail_factory, const char *file_uri, const char *custom_icon, GnomeIconLookupFlags flags, GnomeIconLookupResultFlags *result) 
void
gnome_icon_lookup_sync (icon_theme, thumbnail_factory, file_uri, custom_icon, flags)
	GnomeIconTheme *icon_theme
	GnomeThumbnailFactory_ornull *thumbnail_factory
	const char *file_uri
	SV *custom_icon
	GnomeIconLookupFlags flags
    PREINIT:
	GnomeIconLookupResultFlags result;
	char *icon;
	const char *real_custom_icon = NULL;
    PPCODE:
	if (SvPOK (custom_icon))
		real_custom_icon = (const char *) SvPV_nolen (custom_icon);

	icon = gnome_icon_lookup_sync (icon_theme, thumbnail_factory, file_uri, real_custom_icon, flags, &result);

	if (icon == NULL)
		XSRETURN_UNDEF;

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVpv (icon, 0)));
	PUSHs (sv_2mortal (newSVGnomeIconLookupFlags (result)));

	g_free (icon);

#endif /* have GNOME_TYPE_ICON_THEME */
