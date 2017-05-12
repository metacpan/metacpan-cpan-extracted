#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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


use strict;
use warnings;
use Test::More tests => 46;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::AdjustmentBits;

#-----------------------------------------------------------------------------
# VERSION

{
  my $want_version = 48;
  is ($Gtk2::Ex::AdjustmentBits::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::AdjustmentBits->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Gtk2::Ex::AdjustmentBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::AdjustmentBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();


#-----------------------------------------------------------------------------
# scroll_value()

{
  my $adj = Gtk2::Adjustment->new (50,  # value
                                   1,   # lower
                                   100, # upper
                                   5,   # step_increment
                                   10,  # page_increment
                                   20); # page_size
  Gtk2::Ex::AdjustmentBits::scroll_value ($adj, 5);
  is ($adj->value, 55);
  Gtk2::Ex::AdjustmentBits::scroll_value ($adj, 1000);
  is ($adj->value, 80); # upper-page clamp

  Gtk2::Ex::AdjustmentBits::scroll_value ($adj, -10);
  is ($adj->value, 70);
  Gtk2::Ex::AdjustmentBits::scroll_value ($adj, -1000);
  is ($adj->value, 1);  # lower clamp
}

#-----------------------------------------------------------------------------
# scroll_increment()

{
  my $adj = Gtk2::Adjustment->new (50,  # value
                                   1,   # lower
                                   100, # upper
                                   5,   # step_increment
                                   10,  # page_increment
                                   20); # page_size
  Gtk2::Ex::AdjustmentBits::scroll_increment ($adj, 'step');
  is ($adj->value, 55);
  Gtk2::Ex::AdjustmentBits::scroll_increment ($adj, 'page');
  is ($adj->value, 65);

  Gtk2::Ex::AdjustmentBits::scroll_increment ($adj, 'step', 1);
  is ($adj->value, 60);
  Gtk2::Ex::AdjustmentBits::scroll_increment ($adj, 'page', 1);
  is ($adj->value, 50);

  Gtk2::Ex::AdjustmentBits::scroll_increment ($adj, 'step', 0);
  is ($adj->value, 55);
}

#-----------------------------------------------------------------------------
# set_maybe()

{
  my $adjustment = Gtk2::Adjustment->new (50,  # value
                                          1,   # lower
                                          100, # upper
                                          5,   # step_increment
                                          10,  # page_increment
                                          20); # page_size

  my $notify = 0;
  my $changed = 0;
  my $value_changed = 0;
  $adjustment->signal_connect (notify => sub {
                                 my ($adj, $pspec) = @_;
                                 diag "notify ",$pspec->get_name;
                                 $notify++;
                               });
  $adjustment->signal_connect (changed => sub {
                                 diag "changed";
                                 $changed++;
                               });
  $adjustment->signal_connect (value_changed => sub {
                                 diag "value_changed";
                                 $value_changed++;
                               });

  Gtk2::Ex::AdjustmentBits::set_maybe ($adjustment);
  is ($changed, 0);
  is ($value_changed, 0);
  is ($notify, 0);

  Gtk2::Ex::AdjustmentBits::set_maybe ($adjustment, page_size => 20);
  is ($changed, 0);
  is ($value_changed, 0);
  is ($notify, 0);

  Gtk2::Ex::AdjustmentBits::set_maybe ($adjustment, page_size => 19);
  is ($adjustment->page_size, 19);
  is ($changed, 1);
  is ($value_changed, 0);
  is ($notify, 1);

  $changed = 0;
  $value_changed = 0;
  $notify = 0;
  Gtk2::Ex::AdjustmentBits::set_maybe ($adjustment, value => 51);
  is ($adjustment->value, 51);
  is ($changed, 0);
  is ($value_changed, 1);
  is ($notify, 1);

  $changed = 0;
  $value_changed = 0;
  $notify = 0;
  Gtk2::Ex::AdjustmentBits::set_maybe ($adjustment,
                                       lower => -1,
                                       upper => 200);
  is ($adjustment->lower, -1);
  is ($adjustment->upper, 200);
  is ($changed, 1);
  is ($value_changed, 0);
  is ($notify, 2);

  $changed = 0;
  $value_changed = 0;
  $notify = 0;
  Gtk2::Ex::AdjustmentBits::set_maybe ($adjustment,
                                       lower => 0,
                                       value => 49);
  is ($adjustment->lower, 0);
  is ($adjustment->value, 49);
  is ($changed, 1);
  is ($value_changed, 1);
  is ($notify, 2);
}

#-----------------------------------------------------------------------------
# set_empty()

{
  my $adjustment = Gtk2::Adjustment->new (50, 1, 100, 5, 10, 20);

  my $notify = 0;
  my $changed = 0;
  my $value_changed = 0;
  $adjustment->signal_connect (notify => sub {
                                 my ($adj, $pspec) = @_;
                                 diag "notify ",$pspec->get_name;
                                 $notify++;
                               });
  $adjustment->signal_connect (changed => sub {
                                 diag "changed";
                                 $changed++;
                               });
  $adjustment->signal_connect (value_changed => sub {
                                 diag "value_changed";
                                 $value_changed++;
                               });

  Gtk2::Ex::AdjustmentBits::set_empty ($adjustment);

  cmp_ok ($changed,       '==', 1, 'set_empty() - changed');
  cmp_ok ($value_changed, '==', 1, 'set_empty() - value_changed');
  cmp_ok ($notify,        '==', 6, 'set_empty() - notify');

  is ($adjustment->upper,          0, 'set_empty() - upper');
  is ($adjustment->lower,          0, 'set_empty() - lower');
  is ($adjustment->page_size,      0, 'set_empty() - page_size');
  is ($adjustment->page_increment, 0, 'set_empty() - page_increment');
  is ($adjustment->step_increment, 0, 'set_empty() - step_increment');
  is ($adjustment->value,          0, 'set_empty() - value');
}


exit 0;
