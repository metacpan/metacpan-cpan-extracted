# Copyright 2012 Kevin Ryde

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


package Foo;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Data::Dumper;

use Glib::Object::Subclass
  'Gtk2::ToolItem',
  signals => { add => \&_do_add,
               notify => \&_do_notify,
             },
  properties => [ Glib::ParamSpec->int
                  ('foo',
                   'foo',
                   'Blurb.',
                   0,100,0,
                   Glib::G_PARAM_READWRITE),
                ];

sub _do_notify {
  my ($self, $pspec) = @_;

  print "_do_notify() begins\n";
  my $invocation_hint = $self->signal_get_invocation_hint;
  print Data::Dumper->Indent(1)->Dump([$invocation_hint],
                                      ['invocation_hint']);

  print "_do_notify(), chain up\n";
  $self->signal_chain_from_overridden ($pspec);
  print "_do_notify(), chain returned\n";
}

sub _do_add {
  my ($self, $child) = @_;

  print "_do_add(), chain up\n";
  $self->signal_chain_from_overridden ($child);
  print "_do_add(), chain returned()\n";

  print "_do_add(), call notify()\n";
  $self->notify('foo');
  print "_do_add() ends()\n";
}



package main;
use Gtk2 '-init';

print "Perl-Gtk2 version ",Gtk2->VERSION,"\n";
print "Gtk2 version ",Gtk2::major_version(),".",Gtk2::minor_version(),".",Gtk2::micro_version(),"\n";
print "Glib version ",Glib::major_version(),".",Glib::minor_version(),".",Glib::micro_version(),"\n";
print "\n";

my $child_widget = Gtk2::Button->new ('XYZ');
my $toolitem = Foo->new;
$toolitem->add ($child_widget);
