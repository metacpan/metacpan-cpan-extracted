#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
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
use Gtk2 '-init';
use Gtk2::Ex::History;
use Gtk2::Ex::History::MenuToolButton;

# uncomment this to run the ### lines
use Smart::Comments;

use FindBin;
my $progname = $FindBin::Script;

my $history = Gtk2::Ex::History->new;
$history->goto ('AAA');
$history->goto ('BBB');
$history->goto ('CCC');
$history->goto ('DDD');
$history->goto ('EEE');
$history->goto ('FFF');
$history->goto ('GGG');
$history->back(3);

# {
#   my $back = $history->model('back');
#   ### $back
#   use List::Util;
#   my $aref = [123];
#   my @foo = ($aref);
#   Scalar::Util::weaken ($foo[0]);
#   List::Util::first {
#     ### $_
#     (defined $_ && $_==123)
#   } @{$back->{'others'}};
#   exit 0;
# }

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $toolbar = Gtk2::Toolbar->new;
$toplevel->add ($toolbar);

{
  my $toolitem = Gtk2::Ex::History::MenuToolButton->new (history => $history,
                                                         # way => 'back',
                                                        );
  $toolbar->add ($toolitem);
}
{
  my $toolitem = Gtk2::Ex::History::MenuToolButton->new (history => $history,
                                                         way => 'forward',
                                                        );
  $toolbar->add ($toolitem);
}
$toplevel->show_all;
Gtk2->main;
exit 0;
