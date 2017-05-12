/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */
#include "gtk2perl.h"

/*
 * Programs and libraries can register their own GtkIconSizes, making the
 * standard enum handling rather incorrect.  so, we override that stuff
 * here.  FIXME if this stuff is ever needed outside this file, we'll have
 * to undef and prototype in gtk2perl.h, instead.
 */
#undef newSVGtkIconSize
#undef SvGtkIconSize

static SV *
newSVGtkIconSize (GtkIconSize size)
{
	/* crap.  there is no try.  do, or do not. */
	/* SV * sv = gperl_try_convert_back_enum (GTK_TYPE_ICON_SIZE, size); */
	SV * sv = gperl_convert_back_enum_pass_unknown (GTK_TYPE_ICON_SIZE,
							size);
	if (looks_like_number (sv)) {
		/* fall back... */
		const char * name;
		name = gtk_icon_size_get_name (size);
		if (name)
			sv_setpv (sv, name);
	}
	return sv;
}

static GtkIconSize
SvGtkIconSize (SV * sv)
{
	GtkIconSize size;
	if (gperl_try_convert_enum (GTK_TYPE_ICON_SIZE, sv, (gint*)&size))
		return size;
	/* fall back... */
	return gtk_icon_size_from_name (SvPV_nolen (sv));
}


MODULE = Gtk2::IconFactory	PACKAGE = Gtk2::IconFactory	PREFIX = gtk_icon_factory_

##  GtkIconFactory* gtk_icon_factory_new (void) 
GtkIconFactory_noinc *
gtk_icon_factory_new (class)
    C_ARGS:
	/*void*/

##  void gtk_icon_factory_add (GtkIconFactory *factory, const gchar *stock_id, GtkIconSet *icon_set) 
void
gtk_icon_factory_add (factory, stock_id, icon_set)
	GtkIconFactory *factory
	const gchar *stock_id
	GtkIconSet *icon_set

##  GtkIconSet* gtk_icon_factory_lookup (GtkIconFactory *factory, const gchar *stock_id) 
GtkIconSet*
gtk_icon_factory_lookup (factory, stock_id)
	GtkIconFactory *factory
	const gchar *stock_id

##  void gtk_icon_factory_add_default (GtkIconFactory *factory) 
void
gtk_icon_factory_add_default (factory)
	GtkIconFactory *factory

##  void gtk_icon_factory_remove_default (GtkIconFactory *factory) 
void
gtk_icon_factory_remove_default (factory)
	GtkIconFactory *factory

# apps should generally use themes for this, but the stock browser needs it
##  GtkIconSet* gtk_icon_factory_lookup_default (const gchar *stock_id) 
GtkIconSet*
gtk_icon_factory_lookup_default (class, stock_id)
	const gchar *stock_id
    CODE:
	RETVAL = gtk_icon_factory_lookup_default (stock_id);
	if (!RETVAL)
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

MODULE = Gtk2::IconFactory	PACKAGE = Gtk2::IconSize	PREFIX = gtk_icon_size_

##  gboolean gtk_icon_size_lookup (GtkIconSize size, gint *width, gint *height) 
=for apidoc
=for signature (width, height) = Gtk2::IconSize->lookup ($size)
=cut
void
gtk_icon_size_lookup (class, size)
	GtkIconSize size
    PREINIT:
	gint width;
	gint height;
    PPCODE:
	if (!gtk_icon_size_lookup (size, &width, &height))
		XSRETURN_EMPTY;
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSViv (width)));
	PUSHs (sv_2mortal (newSViv (height)));

#if GTK_CHECK_VERSION(2,2,0)

##  gboolean gtk_icon_size_lookup_for_settings (GtkSettings *settings, GtkIconSize size, gint *width, gint *height) 
=for apidoc
=for signature (width, height) = Gtk2::IconSize->lookup_for_settings ($settings, $size)
=cut
void
gtk_icon_size_lookup_for_settings (class, settings, size)
	GtkSettings *settings
	GtkIconSize size
    PREINIT:
	gint width;
	gint height;
    PPCODE:
	if (!gtk_icon_size_lookup_for_settings (settings, size, &width, &height))
		XSRETURN_EMPTY;
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSViv (width)));
	PUSHs (sv_2mortal (newSViv (height)));

#endif /* >= 2.2.0 */

##  GtkIconSize gtk_icon_size_register (const gchar *name, gint width, gint height) 
GtkIconSize
gtk_icon_size_register (class, name, width, height)
	const gchar *name
	gint width
	gint height
    C_ARGS:
	name, width, height

##  void gtk_icon_size_register_alias (const gchar *alias, GtkIconSize target) 
void
gtk_icon_size_register_alias (class, alias, target)
	const gchar *alias
	GtkIconSize target
    C_ARGS:
	alias, target

##  GtkIconSize gtk_icon_size_from_name (const gchar *name) 
GtkIconSize
gtk_icon_size_from_name (class, name)
	const gchar *name
    C_ARGS:
	name

##  const gchar * gtk_icon_size_get_name (GtkIconSize size) 

MODULE = Gtk2::IconFactory	PACKAGE = Gtk2::IconSet	PREFIX = gtk_icon_set_

##  GtkIconSet* gtk_icon_set_new (void) 
GtkIconSet_own*
gtk_icon_set_new (class)
    C_ARGS:
	/*void*/

##  GtkIconSet* gtk_icon_set_new_from_pixbuf (GdkPixbuf *pixbuf) 
GtkIconSet_own*
gtk_icon_set_new_from_pixbuf (class, pixbuf)
	GdkPixbuf *pixbuf
    C_ARGS:
	pixbuf

 # these are done for you by the Glib bindings
###  GtkIconSet* gtk_icon_set_ref (GtkIconSet *icon_set) 
###  void gtk_icon_set_unref (GtkIconSet *icon_set) 
###  GtkIconSet* gtk_icon_set_copy (GtkIconSet *icon_set) 

#### apps should almost always use gtk_widget_render_icon
##  GdkPixbuf* gtk_icon_set_render_icon (GtkIconSet *icon_set, GtkStyle *style, GtkTextDirection direction, GtkStateType state, GtkIconSize size, GtkWidget *widget, const char *detail) 
GdkPixbuf_noinc*
gtk_icon_set_render_icon (icon_set, style, direction, state, size, widget, detail=NULL)
	GtkIconSet *icon_set
	GtkStyle_ornull *style
	GtkTextDirection direction
	GtkStateType state
	GtkIconSize size
	GtkWidget_ornull *widget
	const char *detail

##  void gtk_icon_set_add_source (GtkIconSet *icon_set, const GtkIconSource *source) 
void
gtk_icon_set_add_source (icon_set, source)
	GtkIconSet *icon_set
	GtkIconSource *source

##  void gtk_icon_set_get_sizes (GtkIconSet *icon_set, GtkIconSize **sizes, gint *n_sizes) 
=for apidoc
Returns a list of Gtk2::IconSize's.
=cut
void
gtk_icon_set_get_sizes (icon_set)
	GtkIconSet *icon_set
    PREINIT:
	GtkIconSize * sizes = NULL;
	gint n_sizes, i;
    PPCODE:
	gtk_icon_set_get_sizes (icon_set, &sizes, &n_sizes);
	EXTEND (SP, n_sizes);
	for (i = 0 ; i < n_sizes ; i++)
		PUSHs (sv_2mortal (newSVGtkIconSize (sizes[i])));
	g_free (sizes);
	

MODULE = Gtk2::IconFactory	PACKAGE = Gtk2::IconSource	PREFIX = gtk_icon_source_

##  GtkIconSource* gtk_icon_source_new (void) 
GtkIconSource_own*
gtk_icon_source_new (class)
    C_ARGS:
	/*void*/

 # these are done for you by the Glib::Boxed bindings
##  GtkIconSource* gtk_icon_source_copy (const GtkIconSource *source) 
##  void gtk_icon_source_free (GtkIconSource *source) 

##  void gtk_icon_source_set_filename (GtkIconSource *source, const gchar *filename) 
void
gtk_icon_source_set_filename (source, filename)
	GtkIconSource *source
	GPerlFilename filename

GPerlFilename_const
gtk_icon_source_get_filename (source)
	GtkIconSource *source

##  void gtk_icon_source_set_pixbuf (GtkIconSource *source, GdkPixbuf *pixbuf) 
void
gtk_icon_source_set_pixbuf (source, pixbuf)
	GtkIconSource *source
	GdkPixbuf *pixbuf

##  GdkPixbuf* gtk_icon_source_get_pixbuf (const GtkIconSource *source) 
GdkPixbuf_ornull*
gtk_icon_source_get_pixbuf (source)
	GtkIconSource *source

##  void gtk_icon_source_set_direction_wildcarded (GtkIconSource *source, gboolean setting) 
void
gtk_icon_source_set_direction_wildcarded (source, setting)
	GtkIconSource *source
	gboolean setting

##  void gtk_icon_source_set_state_wildcarded (GtkIconSource *source, gboolean setting) 
void
gtk_icon_source_set_state_wildcarded (source, setting)
	GtkIconSource *source
	gboolean setting

##  void gtk_icon_source_set_size_wildcarded (GtkIconSource *source, gboolean setting) 
void
gtk_icon_source_set_size_wildcarded (source, setting)
	GtkIconSource *source
	gboolean setting

##  gboolean gtk_icon_source_get_size_wildcarded (const GtkIconSource *source) 
gboolean
gtk_icon_source_get_size_wildcarded (source)
	GtkIconSource *source

##  gboolean gtk_icon_source_get_state_wildcarded (const GtkIconSource *source) 
gboolean
gtk_icon_source_get_state_wildcarded (source)
	GtkIconSource *source

##  gboolean gtk_icon_source_get_direction_wildcarded (const GtkIconSource *source) 
gboolean
gtk_icon_source_get_direction_wildcarded (source)
	GtkIconSource *source

##  void gtk_icon_source_set_direction (GtkIconSource *source, GtkTextDirection direction) 
void
gtk_icon_source_set_direction (source, direction)
	GtkIconSource *source
	GtkTextDirection direction

##  void gtk_icon_source_set_state (GtkIconSource *source, GtkStateType state) 
void
gtk_icon_source_set_state (source, state)
	GtkIconSource *source
	GtkStateType state

##  void gtk_icon_source_set_size (GtkIconSource *source, GtkIconSize size) 
void
gtk_icon_source_set_size (source, size)
	GtkIconSource *source
	GtkIconSize size

##  GtkTextDirection gtk_icon_source_get_direction (const GtkIconSource *source) 
GtkTextDirection
gtk_icon_source_get_direction (source)
	GtkIconSource *source

##  GtkStateType gtk_icon_source_get_state (const GtkIconSource *source) 
GtkStateType
gtk_icon_source_get_state (source)
	GtkIconSource *source

##  GtkIconSize gtk_icon_source_get_size (const GtkIconSource *source) 
GtkIconSize
gtk_icon_source_get_size (source)
	GtkIconSource *source

#if GTK_CHECK_VERSION(2,4,0)

##  void gtk_icon_source_set_icon_name (GtkIconSource *source, const gchar *icon_name) 
void
gtk_icon_source_set_icon_name (source, icon_name)
	GtkIconSource *source
	const gchar *icon_name

##  const gchar *gtk_icon_source_get_icon_name (const GtkIconSource *source) 
const gchar *
gtk_icon_source_get_icon_name (source)
	GtkIconSource *source

#endif
