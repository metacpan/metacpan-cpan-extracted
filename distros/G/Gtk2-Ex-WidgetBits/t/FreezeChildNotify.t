#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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
use Test::More tests => 23;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::FreezeChildNotify;

require Gtk2;
MyTestHelpers::glib_gtk_versions();


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 48;
  is ($Gtk2::Ex::FreezeChildNotify::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::FreezeChildNotify->VERSION, $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::FreezeChildNotify->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  ok (! eval { Gtk2::Ex::FreezeChildNotify->VERSION($want_version + 1000); 1 },
      "VERSION class check " . ($want_version + 1000));

  my $label = Gtk2::Label->new;
  my $freezer = Gtk2::Ex::FreezeChildNotify->new ($label);

  is ($freezer->VERSION, $want_version, 'VERSION object method');
  ok (eval { $freezer->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $freezer->VERSION($want_version + 1000); 1 },
      "VERSION object check " . ($want_version + 1000));
}

#------------------------------------------------------------------------------

{
  my $vbox = Gtk2::VBox->new;
  my $label = Gtk2::Label->new;
  $vbox->add($label);
  my $notified = 0;
  $label->signal_connect (child_notify => sub { $notified = 1; });

  {
    my $freezer = Gtk2::Ex::FreezeChildNotify->new ($label);
    ok (! $notified);
    $vbox->child_set_property ($label, padding => 1);
    $vbox->child_set_property ($label, fill => 1);
    ok (! $notified, 'freezer alive, no notify yet');
  }
  ok ($notified, 'notify goes out after freezer dies');
}

# notify goes out on two widgets when $freezer dies
{
  my $vbox = Gtk2::VBox->new;
  my $label1 = Gtk2::Label->new;
  my $label2 = Gtk2::Label->new;
  $vbox->add($label1);
  $vbox->add($label2);
  my $notified1 = 0;
  my $notified2 = 0;
  $label1->signal_connect (child_notify => sub { $notified1 = 1; });
  $label2->signal_connect (child_notify => sub { $notified2 = 1; });

  {
    my $freezer = Gtk2::Ex::FreezeChildNotify->new ($label1, $label2);
    $vbox->child_set_property ($label1, padding => 10);
    $vbox->child_set_property ($label2, padding => 20);
    ok (! $notified1, 'freezer alive, no notify label1 yet');
    ok (! $notified2, 'freezer alive, no notify label2 yet');
  }
  ok ($notified1, 'notify label1 goes out after freezer dies');
  ok ($notified2, 'notify label2 goes out after freezer dies');
}

{
  my $vbox = Gtk2::VBox->new;
  my $label = Gtk2::Label->new;
  $vbox->add($label);
  my $notified = 0;
  $label->signal_connect (child_notify => sub { $notified = 1; });

  eval {
    my $freezer = Gtk2::Ex::FreezeChildNotify->new ($label);
    die "an error";
  };
  $vbox->child_set_property ($label, padding => 1);
  ok ($notified, 'after a die the obj is not left frozen');
}

{
  my $vbox = Gtk2::VBox->new;
  my $label = Gtk2::Label->new;
  $vbox->add($label);
  my $notified = 0;
  $label->signal_connect (child_notify => sub { $notified = 1; });

  eval {
    my $freezer = Gtk2::Ex::FreezeChildNotify->new ($label);
    $label->set(bogosity => 1);
  };
  $vbox->child_set_property ($label, padding => 1);
  ok ($notified, 'after a bad set() propname the obj is not left frozen');
}

# notify goes out after a die
{
  my $vbox = Gtk2::VBox->new;
  my $label = Gtk2::Label->new;
  $vbox->add($label);
  my $notified = 0;
  my $die_notified = 'not set';
  $label->signal_connect (child_notify => sub { $notified = 1; });

  local $SIG{__DIE__} = sub {
    $die_notified = $notified;
  };

  eval {
    my $freezer = Gtk2::Ex::FreezeChildNotify->new ($label);
    $vbox->child_set_property ($label, padding => 1);
    ok (! $notified, "notify hasn't gone before the die");
    die "an error";
  };
  ok ($notified, 'notify has gone out after the die');
  is ($die_notified, 0,
     'SIG{__DIE__} runs inside the eval, so the freezer object is still alive and not yet done its thaw');
}

{
  my $vbox = Gtk2::VBox->new;
  my $label = Gtk2::Label->new;
  $vbox->add($label);
  my $freezer = Gtk2::Ex::FreezeChildNotify->new ($label);
  Scalar::Util::weaken ($label);
  $vbox->remove($label);
  ok (! defined $label, "doesn't keep a hard reference to its widget");
}

# doesn't keep a hard reference to either of two widgets
{
  my $vbox = Gtk2::VBox->new;
  my $label1 = Gtk2::Label->new;
  my $label2 = Gtk2::Label->new;
  $vbox->add($label1);
  $vbox->add($label2);
  my $freezer = Gtk2::Ex::FreezeChildNotify->new ($label1, $label2);
  Scalar::Util::weaken ($label2);
  $vbox->remove($label2);
  ok (! defined $label2, "doesn't keep a hard reference to label2");
  Scalar::Util::weaken ($label1);
  $vbox->remove($label1);
  ok (! defined $label1, "doesn't keep a hard reference to label1");
}

{
  my $vbox = Gtk2::VBox->new;
  my $label = Gtk2::Label->new;
  $vbox->add($label);
  my $notified;
  $label->signal_connect (child_notify => sub { $notified = 1; });
  eval { Gtk2::Ex::FreezeChildNotify->new ($label, 'something bad') };
  $notified = 0;
  $vbox->child_set_property ($label, padding => 1);
  ok ($notified,
      "if one argument to new() is bad the rest aren't left frozen");
}

exit 0;
