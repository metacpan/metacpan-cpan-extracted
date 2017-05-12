#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./financequote.pl [-method] symbol symbol ...
#
# This is a kinda minimal example of a stock ticker, using prices downloaded
# with Finance::Quote.  The default is some Australian shares, but method
# and symbols can be given on the command line, like
#
#        ./financequote.pl -usa F GM IBM AAPL
#
# The downloads are done at the start and then just displayed from a
# Gtk2::ListStore.  A proper program would have some sort of refresh, and
# would preferably not block the GUI, meaning all the usual Gtk2-Perl
# approaches of a subprocess, or a thread, or POE cooperative tasking like
# in poe-yahoo-quotes.pl, or one of the asynch HTTP libraries, etc.
#
# It's also possible to use something more sophisticated than just a
# ListStore for the data.  You could make a ListStore of the symbols alone
# and then have a TreeModelFilter wrapping it with a "modify" func which
# generates the displayed strings "on demand", perhaps out of a database,
# and with 'row-changed' emission when a download has provided new data (to
# make that element redraw if necessary).
#


use strict;
use warnings;
use Finance::Quote;
use Gtk2 '-init';
use Gtk2::Ex::TickerView;

my $method = 'australia';
my @symbols = ('^AXJO', 'BHP', 'NAB', 'ALL', 'BBG', 'WOW');

if (@ARGV && $ARGV[0] =~ /^-/) {
  $method = substr $ARGV[0], 1;
  shift @ARGV;
}
if (@ARGV) {
  @symbols = @ARGV;
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->set_size_request (300, -1);

# return pango markup for $symbol using the Finance::Quote info in $quotes
sub quotes_string {
  my ($quotes, $symbol) = @_;
  my $ret = "$symbol ";
  if (! $quotes->{$symbol,'success'}) { return $ret . '[error]'; }

  my $last = $quotes->{$symbol,'last'};
  if (! defined $last && defined $quotes->{$symbol,'price'}) {
    $last = $quotes->{$symbol,'price'}; # sometimes price instead of last
  }
  if (! defined $last) { return $ret . '[no price]'; }
  $ret .= " $last";

  my $change = $quotes->{$symbol,'net'};
  if (! defined $change) { return $ret; }
  if ($change == 0) { return $ret . " unch"; }
  $ret .= " $change";

  if ($change > 0) {
    $ret = '<span foreground="#FF7070">' . $ret . '</span>';
  } elsif ($change < 0) {
    $ret = '<span foreground="green">' . $ret . '</span>';
  }
  return $ret;
}

my $fq = Finance::Quote->new;
print "Downloading quotes ...\n";
my $quotes = $fq->fetch ($method, @symbols);
print "... done\n";

my $liststore = Gtk2::ListStore->new ('Glib::String');
foreach my $symbol (@symbols) {
  $liststore->set_value ($liststore->append,
                         # into column 0
                         0 => '  ' . quotes_string ($quotes, $symbol));
}

my $ticker = Gtk2::Ex::TickerView->new (model => $liststore);
$toplevel->add ($ticker);

my $renderer = Gtk2::CellRendererText->new;
$renderer->set (background => 'black');
$renderer->set (foreground => 'white');
$ticker->pack_start ($renderer, 0);
$ticker->set_attributes ($renderer, markup => 0); # display column 0

$toplevel->show_all;
Gtk2->main;
exit 0;
