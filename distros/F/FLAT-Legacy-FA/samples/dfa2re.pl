#!/usr/bin/env perl

#
# Brett D. Estrade <estrabd@mailcan.com>
#
# PFA to NFA driver
#
# $Revision: 1.1 $ $Date: 2006/02/23 05:11:01 $ $Author: estrabd $

$^W++;
$|++;

use strict;
use Data::Dumper;
use lib qw(../);
use RE;
use Data::Dumper;

my $test = '(a|m|s)|(b|cc*)';
if (defined($ARGV[0])) {
  $test = $ARGV[0];
}

chomp($test);
my $re = RE->new();
print STDERR "$test\n";
$re->set_re($test);

for (1..2) {
  $re->parse();
  my $nfa1 = $re->to_nfa();
  my $dfa1 = $nfa1->to_dfa();
  #$dfa1->minimize();
  $dfa1->number_states();
  print $dfa1->info();
  $re = $dfa1->to_re();
  print $re->get_re()."\n";
}
