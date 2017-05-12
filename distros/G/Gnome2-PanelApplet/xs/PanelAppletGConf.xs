/*
 * Copyright (C) 2007 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by the
 * Free Software Foundation; either version 2.1 of the License, or (at your
 * option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 * $Id$
 */

#include "libpanelapplet-perl.h"

MODULE = Gnome2::PanelApplet::GConf	PACKAGE = Gnome2::PanelApplet	PREFIX = panel_applet_

=for object Gnome2::PanelApplet::GConf
=cut

gchar_own * panel_applet_gconf_get_full_key (PanelApplet *applet, const gchar *key);

# --------------------------------------------------------------------------- #

=for apidoc gconf_set_value __gerror__
=cut

=for apidoc gconf_set_bool __gerror__
=cut

=for apidoc gconf_set_int __gerror__
=cut

=for apidoc gconf_set_string __gerror__
=cut

=for apidoc gconf_set_float __gerror__
=cut

# void panel_applet_gconf_set_value (PanelApplet *applet, const gchar *key, GConfValue *value, GError **opt_error);
# void panel_applet_gconf_set_bool (PanelApplet *applet, const gchar *key, gboolean the_bool, GError **opt_error);
# void panel_applet_gconf_set_int (PanelApplet *applet, const gchar *key, gint the_int, GError **opt_error);
# void panel_applet_gconf_set_string (PanelApplet *applet, const gchar *key, const gchar *the_string, GError **opt_error);
# void panel_applet_gconf_set_float (PanelApplet *applet, const gchar *key, gdouble the_float, GError **opt_error);
void
panel_applet_gconf_set_value (PanelApplet *applet, const gchar *key, SV *value, gboolean check_error=TRUE)
    PREINIT:
	GError *err = NULL;
    ALIAS:
	gconf_set_bool = 1
	gconf_set_int = 2
	gconf_set_string = 3
	gconf_set_float = 4
    CODE:
#define CALL(func, real_value) func (applet, key, real_value, check_error ? &err : NULL);
	switch (ix) {
	case 0:
	{
		GConfValue *real_value = SvGConfValue (value);
		CALL (panel_applet_gconf_set_value, real_value);
		gconf_value_free (real_value);
	}
		break;
	case 1:
		CALL (panel_applet_gconf_set_bool, SvUV (value));
		break;
	case 2:
		CALL (panel_applet_gconf_set_int, SvIV (value));
		break;
	case 3:
		CALL (panel_applet_gconf_set_string, SvGChar (value));
		break;
	case 4:
		CALL (panel_applet_gconf_set_float, SvNV (value));
		break;
	default:
		g_assert_not_reached ();
	}
	if (err)
		gperl_croak_gerror (NULL, err);
#undef CALL

# --------------------------------------------------------------------------- #

=for apidoc gconf_get_value __gerror__
=cut

=for apidoc gconf_get_bool __gerror__
=cut

=for apidoc gconf_get_int __gerror__
=cut

=for apidoc gconf_get_string __gerror__
=cut

=for apidoc gconf_get_float __gerror__
=cut

# GConfValue * panel_applet_gconf_get_value (PanelApplet *applet, const gchar *key, GError **opt_error);
# gboolean panel_applet_gconf_get_bool (PanelApplet *applet, const gchar *key, GError **opt_error);
# gint panel_applet_gconf_get_int (PanelApplet *applet, const gchar *key, GError **opt_error);
# gchar *panel_applet_gconf_get_string (PanelApplet *applet, const gchar *key, GError **opt_error);
# gdouble panel_applet_gconf_get_float (PanelApplet *applet, const gchar *key, GError **opt_error);
SV *
panel_applet_gconf_get_value (PanelApplet *applet, const gchar *key, gboolean check_error=TRUE)
    PREINIT:
	GError *err = NULL;
    ALIAS:
	gconf_get_bool = 1
	gconf_get_int = 2
	gconf_get_string = 3
	gconf_get_float = 4
    CODE:
#define CALL(func, type, converter)	\
	{	\
		type tmp = func (applet, key, check_error ? &err : NULL);	\
		RETVAL = converter (tmp);	\
	}
	switch (ix) {
	case 0:
		CALL (panel_applet_gconf_get_value, GConfValue*, newSVGConfValue);
		break;
	case 1:
		CALL (panel_applet_gconf_get_bool, gboolean, newSVuv);
		break;
	case 2:
		CALL (panel_applet_gconf_get_int, gint, newSViv);
		break;
	case 3:
		CALL (panel_applet_gconf_get_string, gchar*, newSVGChar);
		break;
	case 4:
		CALL (panel_applet_gconf_get_float, gdouble, newSVnv);
		break;
	default:
		g_assert_not_reached ();
	}
	if (err)
		gperl_croak_gerror (NULL, err);
#undef CALL
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

# These are implemented in Perl, but we need the stubs so we get generated
# documentation.

#if 0

=for apidoc __gerror__
=cut
# void panel_applet_gconf_set_list (PanelApplet *applet, const gchar *key, GConfValueType list_type, GSList *list, GError **opt_error);
void
panel_applet_gconf_set_list (PanelApplet *applet, const gchar *key, const gchar *list_type, SV *list, gboolean check_error=TRUE);

=for apidoc __gerror__
=for signature list = $applet->gconf_get_list($key, $check_error=TRUE)
=cut
# GSList * panel_applet_gconf_get_list (PanelApplet *applet, const gchar *key, GConfValueType list_type, GError **opt_error);
void
panel_applet_gconf_get_list (PanelApplet *applet, const gchar *key, gboolean check_error=TRUE);

#endif
