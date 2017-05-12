#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-History is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-History.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More tests => 29;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::History;


#-----------------------------------------------------------------------------
my $want_version = 8;
is ($Gtk2::Ex::History::VERSION, $want_version, 'VERSION variable');
is (Gtk2::Ex::History->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { Gtk2::Ex::History->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::History->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# new()

{
  my $history = Gtk2::Ex::History->new;
  isa_ok ($history, 'Gtk2::Ex::History');

  is ($history->VERSION, $want_version, 'VERSION object method');
  ok (eval { $history->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $history->VERSION($want_version + 1000); 1 },
      "VERSION object check " . ($want_version + 1000));
}

#------------------------------------------------------------------------------
# _default_place_equal()

{
  my $history = Gtk2::Ex::History->new;
  ok (  $history->signal_emit ('place-equal', 'abc', 'abc'));
  ok (! $history->signal_emit ('place-equal', 'abc', 'def'));
  ok (  $history->signal_emit ('place-equal', undef, undef));
  ok (! $history->signal_emit ('place-equal', 'abc', undef));
  ok (! $history->signal_emit ('place-equal', undef, 'abc'));
}

#------------------------------------------------------------------------------
# place-equal handler

{
  my $history = Gtk2::Ex::History->new;
  my $equal_called = 0;
  my $equal_history;
  $history->signal_connect (place_equal => sub {
                              my ($h, $p1, $p2) = @_;
                              $equal_history = $h;
                              $equal_called = 1;
                              return ($p1 == $p2);
                            });
  my $got = $history->signal_emit ('place-equal', 1, 1);
  ok ($equal_called, 'place-equal handler - called');
  is ($equal_history, $history, 'place-equal handler - history obj arg');
  is (  $got, 1, 'place-equal handler - result');
  ok (! $history->signal_emit ('place-equal', 1, 2),
      'place-equal handler - args 1 2 are not equal');
  ok (  $history->signal_emit ('place-equal', '1.0', 1),
        'place-equal handler - args 1.0 1 are equal');
}

#------------------------------------------------------------------------------
# _default_place_to_text()

{
  my $history = Gtk2::Ex::History->new;
  is ($history->signal_emit ('place-to-text', 'abc'), 'abc',
      '_default_place_to_text() string arg');
  {
    my $place = ['hello'];
    my $place_str = "$place";
    is ($history->signal_emit ('place-to-text', $place), $place_str,
        '_default_place_to_text() stringize ref');
  }
}

#------------------------------------------------------------------------------
# place-to-text handler

{
  my $history = Gtk2::Ex::History->new;
  my $to_text_called = 0;
  my $to_text_h;
  $history->signal_connect (place_to_text => sub {
                              my ($h, $place) = @_;
                              $to_text_called = 1;
                              $to_text_h = $h;
                              return "xx $place yy";
                            });
  my $got = $history->signal_emit ('place-to-text', 'abc');
  ok ($to_text_called, 'place-to-text handler - called');
  is ($to_text_h, $history, 'place-to-text handler - history object arg');
  is ($got, "xx abc yy", 'place-to-text handler - result');
  is ($history->signal_emit ('place-to-text', $history),
      "xx $history yy",
      'place-to-text handler - 1,2');
}

#------------------------------------------------------------------------------
# weaken garbage collect

{
  my $history = Gtk2::Ex::History->new;
  require Scalar::Util;
  Scalar::Util::weaken ($history);
  is ($history, undef, 'weaken() garbage collect');
}

{
  my $history = Gtk2::Ex::History->new;
  my $back    = $history->model('back');
  my $forward = $history->model('forward');
  my $current = $history->model('current');
  require Scalar::Util;
  Scalar::Util::weaken ($history);
  Scalar::Util::weaken ($back);
  Scalar::Util::weaken ($forward);
  Scalar::Util::weaken ($current);
  is ($history, undef, 'weaken() history       garbage collect');
  is ($history, undef, 'weaken() back_model    garbage collect');
  is ($history, undef, 'weaken() forward_model garbage collect');
  is ($history, undef, 'weaken() current_model garbage collect');
}

exit 0;
