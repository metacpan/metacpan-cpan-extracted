/*
 * Copyright (c) 2003, 2010 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::RadioButton	PACKAGE = Gtk2::RadioButton	PREFIX = gtk_radio_button_

=for position SYNOPSIS

=head1 SYNOPSIS

  # first group
  $foo1 = Gtk2::RadioButton->new (undef, 'Foo One');
  $foo2 = Gtk2::RadioButton->new ($foo1, 'Foo Two');
  $foo3 = Gtk2::RadioButton->new ($foo2, 'Foo Three');

  # second group, using the group reference
  $bar1 = Gtk2::RadioButton->new (undef, 'Bar One');
  $group = $bar1->get_group;
  $bar2 = Gtk2::RadioButton->new ($group, 'Bar Two');
  $bar3 = Gtk2::RadioButton->new ($group, 'Bar Three');

  # move bar3 from the bar group to the foo group.
  $bar->set_group ($foo->get_group);

  # iterate over the widgets in the group
  $group = $foo1->get_group;
  foreach my $r (@$group) {
      $r->set_sensitive ($whatever);
  }

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

A single radio button performs the same basic function as a Gtk2::CheckButton,
as its position in the object hierarchy reflects.  It is only when multiple
radio buttons are grouped together that they become a different user interface
component in their own right.

Every radio button is a member of some group of radio buttons.  When one is
selected, all other radio buttons in the same group are deselected.  A
Gtk2::RadioButton is one way of giving the user a choice from many options;
Gtk2::OptionMenu and Gtk2::ComboBox (added in gtk+ 2.4) are alternatives.

Each constructor can take either a group or widget from that group where the
group is wanted; this is an enhancement over the C API.  Nevertheless, the
_from_widget forms are provided for completeness.

=cut

=for apidoc Gtk2::RadioButton::new_with_mnemonic
=for arg member_or_listref reference to radiobutton group or a Gtk2::RadioButton belonging to that group.
Create a radio button with a mnemonic; this is an alias for C<new>.
=cut

=for apidoc Gtk2::RadioButton::new_with_label
=for arg member_or_listref reference to radiobutton group or a Gtk2::RadioButton belonging to that group.
Create a radio button with a plain text label, which will not be interpreted
as a mnemonic.
=cut

=for apidoc
=for arg member_or_listref reference to radiobutton group or a Gtk2::RadioButton belonging to that group.
Create a radio button.  If I<$label> is provided, it will be interpreted
as a mnemonic.  If I<$member_or_listref> is undef, the radio button will
be created in a new group.
=cut
GtkWidget *
gtk_radio_button_new (class, member_or_listref=NULL, label=NULL)
	SV          * member_or_listref
	const gchar * label
    ALIAS:
	Gtk2::RadioButton::new_with_mnemonic = 1
	Gtk2::RadioButton::new_with_label = 2
    PREINIT:
	GSList         * group = NULL;
	GtkRadioButton * member = NULL;
    CODE:
	if( gperl_sv_is_defined (member_or_listref)
	    && SvROK (member_or_listref)
	    && SvRV (member_or_listref) != &PL_sv_undef )
	{
		if( gperl_sv_is_array_ref (member_or_listref) )
		{
			AV * av = (AV*)SvRV(member_or_listref);
			SV ** svp = av_fetch(av, 0, 0);
			if( svp && gperl_sv_is_defined(*svp) )
				member = SvGtkRadioButton(*svp);
		}
		else
			member = SvGtkRadioButton_ornull(member_or_listref);
		if( member )
			group = member->group;
	}

	if (label) {
		if (ix == 2)
			RETVAL = gtk_radio_button_new_with_label (group, label);
		else
			RETVAL = gtk_radio_button_new_with_mnemonic (group, label);
	} else
		RETVAL = gtk_radio_button_new (group);
    OUTPUT:
	RETVAL


GtkWidget *
gtk_radio_button_new_from_widget (class, group, label=NULL)
	GtkRadioButton_ornull * group
	const gchar           * label
    ALIAS:
	Gtk2::RadioButton::new_with_mnemonic_from_widget = 1
	Gtk2::RadioButton::new_with_label_from_widget = 2
    CODE:
	if (label) {
		if (ix == 2)
			RETVAL = gtk_radio_button_new_with_label_from_widget (group, label);
		else
			RETVAL = gtk_radio_button_new_with_mnemonic_from_widget (group, label);
	} else
		RETVAL = gtk_radio_button_new_from_widget (group);
    OUTPUT:
	RETVAL

=for apidoc
=for arg member_or_listref reference to the group or a Gtk2::RadioButton belonging to that group.
Assign I<$radio_button> to a new group.
=cut
void
gtk_radio_button_set_group (radio_button, member_or_listref)
	GtkRadioButton * radio_button
	SV             * member_or_listref
    PREINIT:
	GSList         * group = NULL;
	GtkRadioButton * member = NULL;
    CODE:
	if( gperl_sv_is_defined (member_or_listref) )
	{
		if( gperl_sv_is_array_ref (member_or_listref) )
		{
			AV * av = (AV*)SvRV(member_or_listref);
			SV ** svp = av_fetch(av, 0, 0);
			if( svp && gperl_sv_is_defined(*svp) )
			{
				member = SvGtkRadioButton(*svp);
			}
		}
		else
			member = SvGtkRadioButton_ornull(member_or_listref);
		if( member )
			group = member->group;
	}
	gtk_radio_button_set_group(radio_button, group);

# GSList * gtk_radio_button_get_group (GtkRadioButton *radio_button)
=for apidoc
Return a reference to the radio group to which I<$radio_button> belongs.
The group is a reference to an array of widget references; the array is B<not>
magical, that is, it will not be updated automatically if the group changes;
call C<get_group> each time you want to use the group.
=cut
AV *
gtk_radio_button_get_group (radio_button)
	GtkRadioButton * radio_button
    PREINIT:
	GSList * group;
	GSList * i;
    CODE:
	group = gtk_radio_button_get_group (radio_button);
	RETVAL = newAV();
	sv_2mortal ((SV*) RETVAL);  /* typemap expects RETVAL mortalized */
	for( i = group; i ; i = i->next )
	{
		av_push(RETVAL, newSVGtkRadioButton(GTK_RADIO_BUTTON(i->data)));
	}
    OUTPUT:
	RETVAL

