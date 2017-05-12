#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Glib::Ex::ConnectProperties;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $label = Gtk2::Label->new ('Hello');
$vbox->add ($label);
my $label2 = Gtk2::Label->new ('');
$vbox->add ($label2);

my $sensitive_button = Gtk2::CheckButton->new_with_label ('Sensitive');
$vbox->add ($sensitive_button);
$sensitive_button->signal_connect
  ('notify::active' => sub {
     print "$progname: press_button active now ",
       $sensitive_button->get('active'),"\n"; });

my $conn = Glib::Ex::ConnectProperties->new ([$label,'sensitive'],
                                             [$sensitive_button,'active'],
                                             [$label2,'label']);
require Data::Dumper;
print Data::Dumper->new([$conn],['conn'])->Sortkeys(1)->Dump;
require Scalar::Util;
Scalar::Util::weaken ($conn);

{
  my $button = Gtk2::CheckButton->new_with_label ('Another Sensitive');
  $vbox->add ($button);

  Glib::Ex::ConnectProperties->new ([$label,'sensitive'],
                                    [$button,'active']);
}

if (1) {
  my $disp = Gtk2::Label->new ('Unset');
  $vbox->add ($disp);

  Glib::Ex::ConnectProperties->new ([$label,'sensitive'],
                                    [$disp, 'label',
                                     map_in => { 1 => 'Sens',
                                                 0 => 'Not Sens' }]);
}

{
  my $button = Gtk2::Button->new_with_label ('Disconnect');
  $vbox->add ($button);
  $button->signal_connect (clicked => sub { $conn->disconnect });
}
{
  my $button = Gtk2::Button->new_with_label ('Freeze');
  $vbox->add ($button);
  $button->signal_connect (clicked => sub {
                             print "$progname: freeze\n";
                             $sensitive_button->freeze_notify;
                           });
}
{
  my $button = Gtk2::Button->new_with_label ('Thaw');
  $vbox->add ($button);
  $button->signal_connect (clicked => sub {
                             print "$progname: thaw\n";
                             $sensitive_button->thaw_notify;
                           });
}


{
  my $label3 = Gtk2::Label->new;
  $vbox->add ($label3);
  sub my_Xtransform {
    my ($value, $object, $propertyname) = @_;
    return "the name is $value";
  }

  Glib::Ex::ConnectProperties->new
    ([$toplevel, 'name', map_out => \&my_Xtransform ],
     [$label3, 'label']);
}
{
  my $spin1 = Gtk2::SpinButton->new_with_range (0, 100, 1);
  my $spin2 = Gtk2::SpinButton->new_with_range (10, 210, 1);
  $vbox->add ($spin1);
  $vbox->add ($spin2);
  sub my_transform {
    my ($value, $object, $propertyname) = @_;
    return $value * 2 + 10;
  }
  sub my_untransform {
    my ($value, $object, $propertyname) = @_;
    return ($value - 10) / 2;
  }
  Glib::Ex::ConnectProperties->new
    ([$spin1, 'value'],
     [$spin2, 'value',
      # map_in  => \&my_transform,
      # map_out => \&my_untransform
     ]);

  my $label4 = Gtk2::Label->new;
  $vbox->add ($label4);
  Glib::Ex::ConnectProperties->new
    ([$spin1, 'value'],
     [$label4,'label',
      # map_in => sub { "the value is $_[0]"}
     ]);
}
{
  my $button = Gtk2::Button->new_with_label ('Quit');
  $button->signal_connect (clicked => sub { $toplevel->destroy; });
  $vbox->pack_start ($button, 0, 0, 0);
}

$toplevel->show_all;
Gtk2->main;

print "$progname: conn ",(defined $conn ? "defined\n" : "not defined\n");
exit 0;


__END__

$widget->style_get_property
# no corresponding set ?
# mangle underlying rcstyle ?

$goocanvas->style_set_property doesn't emit a signal



$from_val = ($from_elem->{'child_property'}
             ? do {
               my $from_parent;
               ($from_parent = $from_object->get_parent)
                 && $from_parent->child_get_property ($from_object,
                                                      $from_pname)
               }
             : $from_object->get_property ($from_pname));

my $to_child_property;
if ($to_child_property = $from_elem->{'child_property'}) {
  $to_parent = $to_object->get_parent || next;
}

                   ($to_child_property
                     ? $to_parent->child_get_property ($to_object, $to_pname)
                     : $to_object->get_property ($to_pname))

if ($to_child_property) {
  if (my $set_func = $to_parent->can('set_child_property')) {
    &$set_func ($to_parent, $to_object, $to_pname, $to_val);
  } else {
    $to_parent->child_set_property($to_object, $to_pname, $to_val)
  }
} else {
  $to_object->set_property ($to_pname, $to_val);
}

$elem->{'get_method'} = ($child_property
                         ? \&_child_get_property
                         : 'get_property');
$elem->{'set_method'} = ($child_property
                         ? \&_child_set_property
                         : 'set_property');

