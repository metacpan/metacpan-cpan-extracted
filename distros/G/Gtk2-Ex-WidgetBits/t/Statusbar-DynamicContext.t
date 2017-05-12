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
use Test::More tests => 16;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::Statusbar::DynamicContext;

my $want_version = 48;
my $check_version = $want_version + 1000;
is ($Gtk2::Ex::Statusbar::DynamicContext::VERSION, $want_version,
    'VERSION variable');
is (Gtk2::Ex::Statusbar::DynamicContext->VERSION,  $want_version,
    'VERSION class method');
ok (eval { Gtk2::Ex::Statusbar::DynamicContext->VERSION($want_version); 1 },
    "VERSION class check $want_version");
ok (! eval { Gtk2::Ex::Statusbar::DynamicContext->VERSION($check_version); 1 },
    "VERSION class check $check_version");

require Gtk2;

isnt (eval { Gtk2::Ex::Statusbar::DynamicContext->new(); 1 },
      1,
      'new() error without statusbar');

{
  my $statusbar = Gtk2::Statusbar->new;

  my $dc1 = Gtk2::Ex::Statusbar::DynamicContext->new($statusbar);
  my $dc2 = Gtk2::Ex::Statusbar::DynamicContext->new($statusbar);
  isnt ($dc1->str, $dc2->str,
        'two contexts different str()');
  isnt ($dc1->id, $dc2->id,
        'two contexts different id()');

  my $str2 = $dc2->str;
  undef $dc2;
  $dc2 = Gtk2::Ex::Statusbar::DynamicContext->new($statusbar);
  diag "re-create id ",$dc2->id," str ",$dc2->str;
  is ($dc2->str, $str2,
      're-create same str()');
  isnt ($dc1->id, $dc2->id,
        're-create contexts two different id()');

  undef $statusbar;
  is ($dc1->id, undef, 'dc1 id() undef when statusbar weakened');
  is ($dc2->id, undef, 'dc2 id() undef when statusbar weakened');

  isnt ($dc1->str, undef, 'dc1 str() not undef when statusbar weakened');
  isnt ($dc2->str, undef, 'dc2 str() not undef when statusbar weakened');
}

{
  my $statusbar = Gtk2::Statusbar->new;
  my $dc = Gtk2::Ex::Statusbar::DynamicContext->new ($statusbar);
  is ($dc->VERSION, $want_version, 'VERSION object method');
  ok (eval { $dc->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $dc->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

exit 0;
