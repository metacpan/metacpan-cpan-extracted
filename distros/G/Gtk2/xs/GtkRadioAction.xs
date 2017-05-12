/*
 * Copyright (c) 2003-2006, 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::RadioAction	PACKAGE = Gtk2::RadioAction	PREFIX = gtk_radio_action_

=for position SYNOPSIS

=head1 SYNOPSIS

  my $action = Gtk2::RadioAction->new (name => 'one',
                                       tooltip => 'One',
                                       value => 23);

Note that the constructor slightly deviates from the convenience constructor in
the C API.  Instead of passing in a list of values for name, label, tooltip,
stock-id and value, you just use key => value pairs like with
Glib::Object::new.

=cut

## GSList  *gtk_radio_action_get_group (GtkRadioAction *action);
AV *
gtk_radio_action_get_group (GtkRadioAction *action)
    PREINIT:
	GSList * group, * i;
    CODE:
	group = gtk_radio_action_get_group (action);
	RETVAL = newAV();
	sv_2mortal ((SV*) RETVAL);  /* typemap expects RETVAL mortalized */
	for (i = group ; i != NULL ; i = i->next)
		av_push (RETVAL, newSVGtkRadioAction (i->data));
    OUTPUT:
	RETVAL

## void gtk_radio_action_set_group (GtkRadioAction *action, GSList *group);
void gtk_radio_action_set_group (GtkRadioAction *action, SV *member_or_listref);
    PREINIT:
	GSList * group = NULL;
    CODE:
	if (member_or_listref && SvTRUE (member_or_listref)) {
		GtkRadioAction * member = NULL;
		if (gperl_sv_is_array_ref (member_or_listref)) {
			AV * av = (AV*) SvRV (member_or_listref);
			SV ** svp = av_fetch (av, 0, 0);
			if (svp && gperl_sv_is_defined (*svp))
				member = SvGtkRadioAction (*svp);
		} else
			member = SvGtkRadioAction_ornull (member_or_listref);
		if (member)
			group = gtk_radio_action_get_group (member);
	}
	gtk_radio_action_set_group (action, group);

gint gtk_radio_action_get_current_value (GtkRadioAction *action);

#if GTK_CHECK_VERSION (2, 10, 0)

void gtk_radio_action_set_current_value (GtkRadioAction *action, gint value);

#endif
