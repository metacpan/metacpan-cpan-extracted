#!/usr/bin/perl -w
# 46ALRRQ - mkHoleDr.pl created by Pip Stuart <Pip@CPAN.Org>
#   to create directories for storing Hold'Em statistics.
# This code is distributed under the GNU General Public License (version 2).
use strict; use Games::Cards::Poker qw(:all);
my @holz = Holz(); mkdir("h$_", 0755) foreach(@holz);
