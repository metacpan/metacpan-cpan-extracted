#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2015 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./dump.pl [-method] SYMBOL SYMBOL ...
#
# Print a dump of Finance::Quote prices downloaded for the given symbols.
# The default is a sample, or a method and symbols can be given, like
#
#    ./dump.pl -mlc 'MLC Horizon 1 - Bond Portfolio,MasterKey Allocated Pension (Five Star)'
#
#    ./dump.pl -rba AUDUSD AUDTWI

use strict;
use Finance::Quote;

my $method = 'rba';
if (@ARGV && $ARGV[0] =~ /^-/) {
  $method = substr (shift @ARGV, 1);
}

my @symbols = @ARGV;
if (! @symbols) {
  @symbols = ('MNG');
}

# the Finance::Quote POD explains how to set FQ_LOAD_QUOTELET to load add-on
# modules in the defaults
#
my $q = Finance::Quote->new ('-defaults', 'MLC', 'MGEX', 'RBA', 'Ghana');
my %quotes = $q->fetch ($method, @symbols);

foreach my $symbol (@symbols) {
  print "Symbol: '$symbol'\n";

  foreach my $key (sort keys %quotes) {
    #
    # each key is the symbol and field with $; separator, like "$symbol$;last"
    # so match and strip the "$symbol$;" part
    #
    next unless $key =~ /^\Q$symbol$;\E(.*)/;
    my $field = $1;

    printf "  %-14s '%s'\n", $field, $quotes{$key};
  }
}

exit 0;
