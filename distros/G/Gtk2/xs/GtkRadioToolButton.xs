/*
 * Copyright (c) 2003, 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

static GSList *
group_from_sv (SV * member_or_listref)
{
	GSList * group = NULL;
	if (gperl_sv_is_defined (member_or_listref)) {
		GtkRadioToolButton * member = NULL;
		if (gperl_sv_is_array_ref (member_or_listref)) {
			AV * av = (AV*) SvRV (member_or_listref);
			SV ** svp = av_fetch (av, 0, FALSE);
			if (svp && gperl_sv_is_defined (*svp))
				member = SvGtkRadioToolButton (*svp);
		} else
			member = SvGtkRadioToolButton_ornull (member_or_listref);
		if (member)
			group = gtk_radio_tool_button_get_group (member);
	}
	return group;
}

static AV *
av_from_group (GSList * group)
{
	GSList * i;
	AV * av = newAV ();
	for (i = group ; i != NULL ; i = i->next)
		av_push (av, newSVGtkRadioToolButton (i->data));
	return av;
}

MODULE = Gtk2::RadioToolButton PACKAGE = Gtk2::RadioToolButton PREFIX = gtk_radio_tool_button_

## this group implementation is similiar to what GtkRadioButton does.

 ## GtkToolItem *gtk_radio_tool_button_new (GSList *group);
GtkToolItem *gtk_radio_tool_button_new (class, SV * member_or_listref=NULL)
    C_ARGS:
	group_from_sv (member_or_listref)

 ## GtkToolItem *gtk_radio_tool_button_new_from_stock (GSList *group, const gchar *stock_id);
GtkToolItem *
gtk_radio_tool_button_new_from_stock (class, member_or_listref, stock_id)
	SV * member_or_listref
	const gchar * stock_id
    C_ARGS:
	group_from_sv (member_or_listref), stock_id

GtkToolItem *gtk_radio_tool_button_new_from_widget (class, GtkRadioToolButton_ornull *group);
    C_ARGS:
	group

GtkToolItem *gtk_radio_tool_button_new_with_stock_from_widget (class, GtkWidget_ornull *group, const gchar *stock_id);
    C_ARGS:
	(GtkRadioToolButton*)group, stock_id

 ##GSList * gtk_radio_tool_button_get_group (GtkRadioToolButton *button);
AV *
gtk_radio_tool_button_get_group (GtkRadioToolButton *button)
    CODE:
	RETVAL = av_from_group (gtk_radio_tool_button_get_group (button));
	sv_2mortal ((SV*) RETVAL);  /* typemap expects RETVAL mortalized */
    OUTPUT:
	RETVAL

 ##void gtk_radio_tool_button_set_group (GtkRadioToolButton *button, GSList *group);
void
gtk_radio_tool_button_set_group (button, member_or_listref)
	GtkRadioToolButton *button
	SV *member_or_listref
    C_ARGS:
	button, group_from_sv (member_or_listref)

