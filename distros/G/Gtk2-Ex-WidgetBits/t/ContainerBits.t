#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More tests => 13;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::ContainerBits;

{
  my $want_version = 48;
  is ($Gtk2::Ex::ContainerBits::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::ContainerBits->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::ContainerBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::ContainerBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();

{
  my $hbox = Gtk2::HBox->new;
  Gtk2::Ex::ContainerBits::remove_all ($hbox);
  is_deeply ([$hbox->get_children], [], 'hbox already empty');
}

{
  my $hbox = Gtk2::HBox->new;
  $hbox->add (Gtk2::Label->new('foo'));
  Gtk2::Ex::ContainerBits::remove_all ($hbox);
  is_deeply ([$hbox->get_children], [], 'hbox one');
}

{
  my $hbox = Gtk2::HBox->new;
  $hbox->add (Gtk2::Label->new('one'));
  $hbox->add (Gtk2::Label->new('two'));
  Gtk2::Ex::ContainerBits::remove_all ($hbox);
  is_deeply ([$hbox->get_children], [], 'hbox two');
}

{
  my $hbox = Gtk2::HBox->new;
  my $label1 = Gtk2::Label->new('one');
  my $label2 = Gtk2::Label->new('two');
  $hbox->add ($label1);
  $hbox->add ($label2);
  my $extra_done;
  $hbox->signal_connect (remove => sub {
                           my ($hbox, $child) = @_;
                           if (! $extra_done) {
                             $extra_done = 1;
                             if ($child == $label1) {
                               $hbox->remove ($label2);
                             } else {
                               $hbox->remove ($label1);
                             }
                           }
                         });
  Gtk2::Ex::ContainerBits::remove_all ($hbox);
  is ($extra_done, 1, 'hbox two, extra remove done');
  is_deeply ([$hbox->get_children], [], 'hbox two, second removed by signal');
}

{
  my $hbox = Gtk2::HBox->new;
  my $hbox2 = Gtk2::HBox->new;
  my $label1 = Gtk2::Label->new('one');
  my $label2 = Gtk2::Label->new('two');
  $hbox->add ($label1);
  $hbox->add ($label2);
  my $reparent_done;
  $hbox->signal_connect (remove => sub {
                           my ($hbox, $child) = @_;
                           if (! $reparent_done) {
                             if ($child == $label1) {
                               $reparent_done = $label2;
                               $label2->reparent ($hbox2);
                             } else {
                               $reparent_done = $label1;
                               $label1->reparent ($hbox2);
                             }
                           }
                         });
  Gtk2::Ex::ContainerBits::remove_all ($hbox);
  is_deeply ([$hbox->get_children], [],
             'hbox two, second reparented by signal');
  is_deeply ([$hbox2->get_children], [$reparent_done],
             'hbox two, reparented label in second hbox');
}

{
  my $hbox = Gtk2::HBox->new;
  my $label = Gtk2::Label->new('one');
  $hbox->add ($label);
  my $count = 0;
  $hbox->signal_connect (remove => sub {
                           my ($hbox, $child) = @_;
                           if ($count++ >= 20) {
                             diag "re-add count exceeded: $count";
                             exit 1;
                           }
                           $hbox->add (Gtk2::Label->new);
                         });
  Gtk2::Ex::ContainerBits::remove_all ($hbox);
  is_deeply (scalar @{[$hbox->get_children]}, 1,
             'hbox re-add leaves one');
  isnt ($label, ($hbox->get_children)[0],
        "hbox re-add doesn't leave original");
}

exit 0;
