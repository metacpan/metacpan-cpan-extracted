#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

use strict;
use lib 'devel/lib';

use FindBin;
my $progname = $FindBin::Script;

# use LWP::Debug '+';

my $method;
my @modules;
my @symbols;

if (1) {
  # Finance::Quote::Yahoo::Australia
  # Finance::Quote::Yahoo::Europe
  # Finance::Quote::Yahoo::USA
  # Finance::Quote::Yahoo::Asia
  # Finance::Quote::Yahoo::Base

  $method = 'australia'; @symbols = ('BHP');
  $method = 'europe'; @symbols = ('TSCO.L');
  $method = 'asia'; @symbols = ('000010.SS');
  $method = 'asia'; @symbols = ('ISPATIND.BO');
  $method = 'usa'; @symbols = ('F');
  $method = 'tsp'; @symbols = ('C','F','G','I','S','L2020','L2030','L2040','L2050','LINCOME');
}
if (0) {
  $method = 'mgex';
  @modules = ('MGEX');
  @symbols = ('ICMWZ09');
}
if (0) {
  $method = 'mlc';
  @modules = ('MLC');
  @symbols = ('MLC MasterKey Horizon 1 - Bond Portfolio,MasterKey Allocated Pension (Five Star)');
}
if (0) {
  $method = 'casablanca';
  @modules = ('Casablanca');
  # @symbols = ('MNG', 'BCE');
  @symbols = ('BCE');
}
if (0) {
  $method = 'rba';
  @modules = ('RBA');
  @symbols = ('AUDTWI', 'AUDUSD');
}
if (1) {
  $method = 'athex';
  @modules = ('ATHEX');
  @symbols = ('HTO', 'ALPHA');
}

if (@ARGV && $ARGV[0] =~ /^-/) {
  my $opt = shift @ARGV;
  $method = substr $opt, 1;
  @modules = ucfirst $method;
}
if (@ARGV) {
  @symbols = @ARGV;
}

{
  print "method  $method\n";
  print "modules @modules\n";
  print "symbols @symbols\n";

  require Finance::Quote;
  my $q = Finance::Quote->new (@modules);
  my $quotes = $q->fetch ($method,@symbols);

  require Data::Dumper;
  print Data::Dumper->new([$quotes],['quotes'])->Sortkeys(1)->Dump;
  exit 0;
}
