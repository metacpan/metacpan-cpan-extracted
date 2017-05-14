#!/usr/bin/env perl

#
# Brett D. Estrade <estrabd@mailcan.com>
#
# NFA to DFA driver
#
# $Revision: 1.2 $ $Date: 2006/02/21 14:43:40 $ $Author: estrabd $

$^W++;
$|++;

use strict;
use lib '../lib';
use FLAT::Legacy::FA::PRE;

if (defined($ARGV[0])) {
  my $test = $ARGV[0];
  chomp($test);
  my $pre = FLAT::Legacy::FA::PRE->new();
  print STDERR "$test\n";
  $pre->set_pre($test);
  $pre->parse();
  my $pfa1 = $pre->to_pfa();
  $pfa1->number_nodes();
  my $nfa1 = $pfa1->to_nfa();
  $nfa1->number_states();
  my $dfa1 = $pre->to_pfa()->to_nfa()->to_dfa();
  my @removed = $dfa1->minimize();
  $dfa1->number_states();
  print STDERR $dfa1->info();
}

exit 1;
