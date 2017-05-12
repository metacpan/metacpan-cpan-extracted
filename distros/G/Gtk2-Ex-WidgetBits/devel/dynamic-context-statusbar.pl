#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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
use 5.010;
use Gtk2;
use Gtk2::Ex::Statusbar::DynamicContext;

use FindBin;
my $progname = $FindBin::Script;

my $statusbar = Gtk2::Statusbar->new;
my $statusbar2 = Gtk2::Statusbar->new;

$statusbar->get_context_id ('hello');
$statusbar->get_context_id ('world');

my $ctx = Gtk2::Ex::Statusbar::DynamicContext->new($statusbar);
print "$progname: ", $ctx->str, " id= ", $ctx->id, "\n";

my $ctx2 = Gtk2::Ex::Statusbar::DynamicContext->new($statusbar);
print "$progname: ", $ctx2->str, " id= ", $ctx2->id, "\n";

my $ctx3 = Gtk2::Ex::Statusbar::DynamicContext->new($statusbar);
print "$progname: ", $ctx3->str, " id= ", $ctx3->id, "\n";

undef $ctx2;
$ctx2 = Gtk2::Ex::Statusbar::DynamicContext->new($statusbar);
print "$progname: ", $ctx2->str, " id= ", $ctx2->id, "\n";

exit 0;
