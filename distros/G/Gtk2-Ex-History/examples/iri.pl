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


# Usage: perl iri.pl
#
# This is an example of using URI.pm objects as the places in a history.
# The "place-to-text" handler calls as_iri() to get a perl wide-char string
# to display, which basically means interpreting %HH byte sequences like
# %E2%98%BA in the URI as utf-8 encoded characters.
#
# Plain ascii %HH like %7E for "~" aren't turned into characters by
# $uri->as_iri(), at least not as of URI 1.55.  But they can be crunched
# down with $uri->canonical if desired.  That could be done either just for
# display, or before adding to the history if you wanted to use canonical
# form everywhere.
#
# It would also work to have plain strings for the places, and have
# place-to-text crunch the "%"s for display either directly with Encode or
# whatever or though a temporary URI->new($str)->as_iri().
#

use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::History::Dialog;
use URI;

use FindBin;
my $progname = $FindBin::Script;

my $history = Gtk2::Ex::History->new;
$history->signal_connect (place_to_text => sub {
                            my ($history, $uri) = @_;
                            return $uri->as_iri;
                          });

# fill with some sample URIs
foreach my $str ('http://foo.org/red%09ros%C3%A9#red',
                 'http://www.%E2%98%BA.org/~yorick',
                 'http://foo.org/20%C2%B0_celsius') {
  my $uri = URI->new($str);
  $history->goto ($uri);
}
$history->back(1);

my $dialog = Gtk2::Ex::History::Dialog->new (history => $history);
$dialog->signal_connect (destroy => sub { Gtk2->main_quit; });
$dialog->show;

Gtk2->main;
exit 0;
