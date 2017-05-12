/*
 * Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::StatusIcon	PACKAGE = Gtk2::StatusIcon	PREFIX = gtk_status_icon_

GtkStatusIcon_noinc *gtk_status_icon_new (class);
    C_ARGS:
        /*void*/

GtkStatusIcon_noinc *gtk_status_icon_new_from_pixbuf (class, GdkPixbuf *pixbuf);
    C_ARGS:
        pixbuf

GtkStatusIcon_noinc *gtk_status_icon_new_from_file (class, GPerlFilename_const filename);
    C_ARGS:
        filename

GtkStatusIcon_noinc *gtk_status_icon_new_from_stock (class, const gchar *stock_id);
    C_ARGS:
        stock_id

GtkStatusIcon_noinc *gtk_status_icon_new_from_icon_name (class, const gchar *icon_name);
    C_ARGS:
        icon_name

void gtk_status_icon_set_from_pixbuf (GtkStatusIcon *status_icon, GdkPixbuf_ornull *pixbuf);

##void gtk_status_icon_set_from_file (GtkStatusIcon *status_icon, const gchar *filename);
void gtk_status_icon_set_from_file (GtkStatusIcon *status_icon, GPerlFilename_const filename);

void gtk_status_icon_set_from_stock (GtkStatusIcon *status_icon, const gchar *stock_id);

void gtk_status_icon_set_from_icon_name (GtkStatusIcon *status_icon, const gchar *icon_name);

GtkImageType gtk_status_icon_get_storage_type (GtkStatusIcon *status_icon);

GdkPixbuf_ornull *gtk_status_icon_get_pixbuf (GtkStatusIcon *status_icon);

const gchar_ornull *gtk_status_icon_get_stock (GtkStatusIcon *status_icon);

const gchar_ornull *gtk_status_icon_get_icon_name (GtkStatusIcon *status_icon);

gint gtk_status_icon_get_size (GtkStatusIcon *status_icon);

void gtk_status_icon_set_tooltip (GtkStatusIcon *status_icon, const gchar_ornull *tooltip_text);

void gtk_status_icon_set_visible (GtkStatusIcon *status_icon, gboolean visible);

gboolean gtk_status_icon_get_visible (GtkStatusIcon *status_icon);

void gtk_status_icon_set_blinking (GtkStatusIcon *status_icon, gboolean blinking);

gboolean gtk_status_icon_get_blinking (GtkStatusIcon *status_icon);

gboolean gtk_status_icon_is_embedded (GtkStatusIcon *status_icon);

=for apidoc

=for signature (x, y, push_in) = Gtk2::StatusIcon::position_menu (menu, icon)
=for signature (x, y, push_in) = Gtk2::StatusIcon::position_menu (menu, x, y, icon)

=for arg menu (Gtk2::Menu)
=for arg x (integer)
=for arg y (integer)
=for arg icon (Gtk2::StatusIcon)

This function takes four arguments so that it may be passed directly as the
menu position callback to Gtk2::Menu::popup(), which passes in initial x and y
values for historical reasons.  Otherwise, you need only pass two arguments.

This function can be used as the I<menu_pos_func> argument to
I<Gtk2::Menu::popup>.

=cut
void
gtk_status_icon_position_menu (GtkMenu *menu, ...)
     PREINIT:
	gboolean push_in;
	gint x, y;
	GtkStatusIcon *icon;
     PPCODE:
	if (items == 4) {
		/* Compatibility mode */
		x = SvIV (ST (1));
		y = SvIV (ST (2));
		icon = SvGtkStatusIcon (ST (3));
	} else
		icon = SvGtkStatusIcon (ST (1));
	/* PUTBACK/SPAGAIN because gtk_status_icon_position_menu() calls out
	   to menu->size_request, which may be a perl class closure */
	PUTBACK;
	gtk_status_icon_position_menu (menu, &x, &y, &push_in, icon);
	SPAGAIN;
	EXTEND (sp, 3);
	PUSHs (sv_2mortal (newSViv (x)));
	PUSHs (sv_2mortal (newSViv (y)));
	PUSHs (sv_2mortal (newSVuv (push_in)));

# gboolean gtk_status_icon_get_geometry (GtkStatusIcon *status_icon, GdkScreen **screen, GdkRectangle *area, GtkOrientation *orientation);
void
gtk_status_icon_get_geometry (GtkStatusIcon *status_icon)
    PREINIT:
	GdkScreen *screen;
	GdkRectangle area;
	GtkOrientation orientation;
    PPCODE:
	if (!gtk_status_icon_get_geometry (status_icon, &screen, &area,
	                                   &orientation))
		XSRETURN_EMPTY;

	EXTEND (sp, 3);
	PUSHs (sv_2mortal (newSVGdkScreen (screen)));
	PUSHs (sv_2mortal (newSVGdkRectangle_copy (&area)));
	PUSHs (sv_2mortal (newSVGtkOrientation (orientation)));

#if GTK_CHECK_VERSION (2, 12, 0)

void gtk_status_icon_set_screen (GtkStatusIcon *status_icon, GdkScreen *screen);

GdkScreen *gtk_status_icon_get_screen (GtkStatusIcon *status_icon);

#endif

#if GTK_CHECK_VERSION (2, 14, 0)

guint32 gtk_status_icon_get_x11_window_id (GtkStatusIcon *status_icon);

#endif /* 2.14 */

#if GTK_CHECK_VERSION (2, 16, 0)

void gtk_status_icon_set_has_tooltip (GtkStatusIcon *status_icon, gboolean has_tooltip);

gboolean gtk_status_icon_get_has_tooltip (GtkStatusIcon *status_icon);

gchar_own_ornull *gtk_status_icon_get_tooltip_markup (GtkStatusIcon *status_icon);

gchar_own_ornull *gtk_status_icon_get_tooltip_text (GtkStatusIcon *status_icon);

#Unlike the corresponding methods in GtkWidget, these setters use plain char instead of gchar.
#However I expect that is an error or oversight and the char and gchar types are supposedly
#equivalent anyway. Also using gchar lets me use the _ornull.

void gtk_status_icon_set_tooltip_text (GtkStatusIcon *status_icon,  const gchar_ornull *text);

void gtk_status_icon_set_tooltip_markup (GtkStatusIcon *status_icon, const gchar_ornull *markup);

#endif /* 2.16 */

#if GTK_CHECK_VERSION (2, 18, 0)

void gtk_status_icon_set_title (GtkStatusIcon *status_icon, const gchar *title);

const gchar * gtk_status_icon_get_title (GtkStatusIcon *status_icon);

#endif /* 2.18 */

#if GTK_CHECK_VERSION (2, 20, 0)

void gtk_status_icon_set_name (GtkStatusIcon *status_icon, const gchar *name);

#endif /* 2.20 */

