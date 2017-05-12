#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2::Ex::ActionTooltips qw(group_tooltips_to_menuitems
                                action_tooltips_to_menuitems_dynamic);

plan tests => 1;

require Gtk2;
MyTestHelpers::glib_gtk_versions();


{
  my $actiongroup = Gtk2::ActionGroup->new ('test1');
  group_tooltips_to_menuitems ($actiongroup);
}
{
  my $action1 = Gtk2::Action->new (name     => 'Quit',
                                   stock_id => 'gtk-quit',
                                   tooltip  => 'The initial tooltip for Quit');
  action_tooltips_to_menuitems_dynamic ($action1);
}
ok(1);

exit 0;
