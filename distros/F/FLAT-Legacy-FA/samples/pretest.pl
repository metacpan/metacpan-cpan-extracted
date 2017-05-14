#!/usr/bin/env perl

#
# Brett D. Estrade <estrabd@mailcan.com>
#
# NFA to DFA driver
#
# $Revision: 1.1 $ $Date: 2006/02/23 05:11:01 $ $Author: estrabd $

$^W++;
$|++;

use strict;
use Data::Dumper;
use FLAT::FA::PRE;
use FLAT::FA::PFA;
use FLAT::FA::NFA;
use FLAT::FA::DFA;

if (defined($ARGV[0])) {
  my $test = $ARGV[0];
  chomp($test);
  my $pre = FLAT::FA::PRE->new();
  print STDERR "$test\n";
  $pre->trace_on();
  $pre->set_pre($test);
  $pre->parse();
  my $pfa1 = $pre->to_pfa();
  $pfa1->number_nodes();
  my $nfa1 = $pfa1->to_nfa();
  $nfa1->number_states();
  my $dfa1 = $pre->to_pfa()->to_nfa()->to_dfa();
  my @removed = $dfa1->minimize();
  $dfa1->number_states();
  #print STDERR $pfa1->info();
  #print STDERR $nfa1->info();
  print STDERR $dfa1->info();
  print STDOUT $dfa1->to_gdl();
}
