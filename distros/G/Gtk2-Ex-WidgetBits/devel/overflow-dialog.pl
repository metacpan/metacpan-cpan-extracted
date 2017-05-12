#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ToolItem::OverflowToDialog;

use Smart::Comments;

use FindBin;
my $progname = $FindBin::Script;

Glib::Type->register_enum ('My::Test1', 'foo', 'bar-ski', 'quux',
                           # 100 .. 105,
                          );

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$vbox->show;
$toplevel->add ($vbox);

my $toolbar = Gtk2::Toolbar->new;
$toolbar->show;
$vbox->pack_start ($toolbar, 0,0,0);


{
  my $toolitem = Gtk2::ToolButton->new(undef,'ZZZZZZ');
  $toolitem->show;
  $toolbar->insert($toolitem, -1);
}

my $child_widget = Gtk2::Button->new('JSDKALFJADSKFJDSKSDJKF');
$child_widget->set (tooltip_text => 'Child tooltip');
$child_widget->show;

my $toolitem = Gtk2::Ex::ToolItem::OverflowToDialog->new
  (child => $child_widget,
   overflow_mnemonic => '_Foo',
   visible => 1,
   tooltip_text => 'This is a tooltip');
$toolitem->show;
$toolitem->signal_connect
  (notify => sub {
     my ($toolitem, $pspec) = @_;
     print "$progname: toolitem notify ",$pspec->get_name,"\n";
   });
$toolbar->insert($toolitem,-1);

{
  my $a = $toolitem->get_ancestor('Gtk2::ToolItem');
  ### ancestor: "$a"
}

sub gets {
  my $t = Gtk2::Ex::ToolItem::OverflowToDialog->child_get_toolitem
    ($child_widget);
  my $t2 = Gtk2::Ex::ToolItem::OverflowToDialog->child_get_ancestor
    ($child_widget, 'Gtk2::ToolItem');
  my $top = Gtk2::Ex::ToolItem::OverflowToDialog->child_get_ancestor
    ($child_widget, 'Gtk2::Window');
  ### t: "$t"
  ### t2: "$t2"
  ### top: "$top"
}
gets();

my $menuitem;
{
  my $button = Gtk2::Button->new_with_label ('Get MenuItem');
  $button->signal_connect
    (clicked => sub {
       $menuitem = $toolitem->get_proxy_menu_item
         ('Gtk2::Ex::ToolItem::OverflowToDialog');
       ### $menuitem
       if ($menuitem) {
         $button->signal_connect (destroy => sub {
                                    print "$progname: menuitem destroy\n";
                                  });
       }
       require Scalar::Util;
       Scalar::Util::weaken ($menuitem);
     });
  $button->show_all;
  $vbox->pack_start ($button, 0, 0, 0);
}


{
  my $button = Gtk2::Button->new_with_label ('Remove Child');
  $button->show;
  $button->signal_connect
    (clicked => sub {
       $toolitem->remove ($toolitem->get('child_widget'));
     });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Unset child-widget');
  $button->show;
  $button->signal_connect
    (clicked => sub {
       $toolitem->set(child_widget => undef);
     });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Destroy Toolitem');
  $button->signal_connect
    (clicked => sub {
       $menuitem = $toolitem->get_proxy_menu_item
         ('Gtk2::Ex::ToolItem::OverflowToDialog');
       require Scalar::Util;
       Scalar::Util::weaken ($menuitem);
       Scalar::Util::weaken ($toolitem);
       $toolitem->destroy;
       ### $toolitem
       ### $menuitem
     });
  $button->show_all;
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Show get_s');
  $button->signal_connect
    (clicked => sub {
       gets();
     });
  $button->show_all;
  $vbox->pack_start ($button, 0, 0, 0);
}

{
  my $button = Gtk2::CheckButton->new_with_label ('Toolitem Sensitive');
  require Glib::Ex::ConnectProperties;
  Glib::Ex::ConnectProperties->new
      ([$toolitem, 'sensitive'],
       [$button, 'active']);
  $button->show;
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::CheckButton->new_with_label ('Child Sensitive');
  Glib::Ex::ConnectProperties->new
      ([$child_widget, 'sensitive'],
       [$button, 'active']);
  $button->show;
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $connp;
  my $button = Gtk2::CheckButton->new_with_label ('Dialog Visible');
  Glib::Timeout->add
      (500,
       sub {
         my $dialog = $toolitem->{'dialog'};
         $connp = ($dialog && do {
           # print "$progname: dialog $dialog\n";
           Glib::Ex::ConnectProperties->dynamic
               ([$dialog, 'visible'],
                [$button, 'active']);
         });
         return Glib::SOURCE_CONTINUE;
       });
  $button->show;
  $vbox->pack_start ($button, 0, 0, 0);
}


$toplevel->show;
Gtk2->main;
exit 0;


no Smart::Comments;

package Gtk2::Ex::ToolItem::OverflowToDialog;

# =item C<< $toolitem = Gtk2::Ex::ToolItem::OverflowToDialog->child_get_toolitem ($child) >>
# 
# If C<$child> is the C<child-widget> of a
# C<Gtk2::Ex::ToolItem::OverflowToDialog> then return that toolitem parent,
# otherwise return C<undef>.
# 
# As noted above, the dialog reparenting may mean C<< $child->get_parent >> is
# somewhere in the dialog, not the toolitem.  C<child_get_toolitem> gives the
# toolitem wherever the child is currently shown.
# 
# =cut

sub child_get_toolitem {
  my ($class, $child) = @_;

  my ($toolitem, $dialog);
  if (# in the toolitem
      (($toolitem = $child->get_parent)
       && $toolitem->isa('Gtk2::Ex::ToolItem::OverflowToDialog'))
      ||
      # or in the dialog
      (($dialog = $child->get_ancestor('Gtk2::Ex::ToolItem::OverflowToDialog::Dialog'))
       && ($toolitem = $dialog->{'toolitem'}))) {
    ### found toolitem: $toolitem

    # only allow $child as the actual child-widget, don't return the
    # toolitem if $child is another part of the dialog, like the buttons, or
    # if it's a sub-part of the child widget (which could reach the dialog
    # from get_ancestor())
    #
    my $child_widget;
    if (($child_widget = $toolitem->{'child_widget'}) # has a child-widget
        && $child == $child_widget) {                 # and this is it
      return $toolitem;
    }
  }
  return undef;
}

# =item C<< $toolitem = Gtk2::Ex::ToolItem::OverflowToDialog->child_get_ancestor ($child, $ancestor_class) >>
# 
# If C<$child> is the C<child-widget> of a
# C<Gtk2::Ex::ToolItem::OverflowToDialog> then do a
# C<< $toolitem->get_ancestor($ancestor_class) >> from its toolitem.
#
# If it's not a C<child-widget> or there's no C<$ancestor_class> then return
# C<undef>, which is also what the C<< $toolitem->get_ancestor >> returns if
# the requested C<$ancestor_class> is then not found.
# 
# =cut

sub child_get_ancestor {
  my ($class, $child, $ancestor_class) = @_;
  ### child_get_ancestor()
  my $toolitem;
  return (($toolitem = $class->child_get_toolitem($child))
          && do {
            ### ancestor from toolitem: $class->child_get_toolitem($child)
            $toolitem->get_ancestor ($ancestor_class)
          });
}
