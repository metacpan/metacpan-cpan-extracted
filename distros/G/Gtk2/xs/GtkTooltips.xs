/*
 * Copyright (c) 2003, 2013 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::Tooltips	PACKAGE = Gtk2::Tooltips	PREFIX = gtk_tooltips_

## GtkTooltips* gtk_tooltips_new (void)
GtkTooltips *
gtk_tooltips_new (class)
    C_ARGS:
	/* void */

## void gtk_tooltips_enable (GtkTooltips *tooltips)
void
gtk_tooltips_enable (tooltips)
	GtkTooltips * tooltips

## void gtk_tooltips_disable (GtkTooltips *tooltips)
void
gtk_tooltips_disable (tooltips)
	GtkTooltips * tooltips

## void gtk_tooltips_set_tip (GtkTooltips *tooltips, GtkWidget *widget, const gchar *tip_text, const gchar *tip_private)
void
gtk_tooltips_set_tip (tooltips, widget, tip_text, tip_private=NULL)
	GtkTooltips * tooltips
	GtkWidget   * widget
	const gchar * tip_text
	SV * tip_private
    PREINIT:
	const gchar * real_tip_private = NULL;
    CODE:
	if (gperl_sv_is_defined (tip_private))
		real_tip_private = SvGChar (tip_private);
	gtk_tooltips_set_tip (tooltips, widget, tip_text, real_tip_private);
	/* gtk+'s widgets do not hold a reference on the tooltips object,
	 * as you might expect; in fact, it's the other way around.
	 * let's use a weakref on the widget to keep the tooltips object
	 * alive as long as the widget is alive. */
	g_object_ref (G_OBJECT (tooltips));
	g_object_weak_ref (G_OBJECT (widget),
	                   (GWeakNotify)g_object_unref, tooltips);

## GtkTooltipsData* gtk_tooltips_data_get (GtkWidget *widget)
=for apidoc
=for signature hash_ref = $tooltips->data_get ($widget)
Returns a hash reference with the keys: tooptips, widget, tip_text, and
tip_private.

tooltips is the GtkTooltips group that this tooltip belongs to. widget is the
GtkWidget that this tooltip data is associated with. tip_text is a string
containing the tooltip message itself.

tip_private is a string that is not shown as the default tooltip. Instead, this
message may be more informative and go towards forming a context-sensitive help
system for your application.
=cut
void
gtk_tooltips_data_get (class, widget)
	GtkWidget * widget
    PREINIT:
	GtkTooltipsData * ret = NULL;
	HV              * hv;
    PPCODE:
	ret = gtk_tooltips_data_get(widget);
	if( !ret )
		XSRETURN_UNDEF;

	hv = newHV();

	if (ret->tooltips)
		gperl_hv_take_sv_s(hv, "tooltips", newSVGtkTooltips(ret->tooltips));
	if (ret->widget)
		gperl_hv_take_sv_s(hv, "widget", newSVGtkWidget(GTK_WIDGET(ret->widget)));
	if (ret->tip_text)
		gperl_hv_take_sv_s(hv, "tip_text", newSVpv(ret->tip_text, 0));
	if (ret->tip_private)
		gperl_hv_take_sv_s(hv, "tip_private", newSVpv(ret->tip_private, 0));

	XPUSHs(sv_2mortal(newRV_noinc((SV*)hv)));

## void gtk_tooltips_force_window (GtkTooltips *tooltips)
void
gtk_tooltips_force_window (tooltips)
	GtkTooltips * tooltips

## void _gtk_tooltips_toggle_keyboard_mode (GtkWidget *widget)

