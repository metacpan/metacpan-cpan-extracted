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
use PFA;
use PRE;
use Data::Dumper;


if (defined($ARGV[0])) {
  my $test = $ARGV[0];
  chomp($test);
  my $pre = PRE->new();
  print STDERR "$test\n";
  $pre->set_pre($test);
  $pre->parse();
  my $pfa1 = $pre->to_pfa();
  $pfa1->number_nodes();
  #print STDERR "\n#### PFA:\n",$pfa1->info();
  my $nfa1 = $pfa1->to_nfa();
  $nfa1->number_states();
  #print STDERR "\n\n#### NFA:\n",$nfa1->info();
  my $dfa1 = $nfa1->to_dfa();
  $dfa1->number_states();
  #print STDERR "\n\n#### DFA:\n",$dfa1->info();
  my @removed = $dfa1->minimize();
  print STDERR ($#removed+1);
  print STDERR " states removed \n";
  $dfa1->number_states();
  print STDERR "\n\n#### DFA (min):\n",$dfa1->info();
  print STDERR "Validate strings (ctrl-c to quit)\n";
  while (1) {
    print STDERR "\r>>";
    my $in = <STDIN>;
    chomp($in);
    if ($dfa1->is_valid($in)) {
      print STDERR ("\r (org) valid :)\n");
    } else {
      print STDERR ("\r (org) not valid!\n");
    }
  }
} else {
  my @strings = qw(aaam abcm acbm bcam bacm cabm 
                   cbam acm aaacm caaaam cam bcm cbm abm bam 
		   aaabm baaam acbmaba cccaaabmcdcdacccbbbba dogcatpig
		   dogpigcat catdogpig catpigdog pigdogcat pigcatdog
		   aaabm aabam abaam aaaabbb bbbbaaa abababababa
		   aaaab aaaba aabaa abaaa baaaa ababcdcd abcdabcd 
		   cdabcdab cdcdababcd abbacddc abcdbadc bm a b);
  while (<DATA>) {
    my $test = $_;
    chomp($test);
    my $pre = PRE->new();
    print STDERR "$test\n";
    $pre->set_pre($test);
    $pre->parse();
#   my $pfa1 = $pre->to_pfa();
#   my $nfa1 = $pfa1->to_nfa();
    # neat!
    my $dfa1 = $pre->to_pfa()->to_nfa()->to_dfa();
    my @removed = $dfa1->minimize();
    $dfa1->number_states();
    print STDERR ($#removed+1);
    print STDERR " states removed \n";
    my $count = 1;
    foreach my $str (@strings) {
      if ($dfa1->is_valid($str)) {
        print STDERR "  Line: $count $str\n";
      }
      $count++;
    }
  }
}
__DATA__
(a*|b&c)m
(a&b&c)m
(a&a&a)m
(a|b&c)m
(a*|b&c)m
(a&b)m
(a*&b)m
a*&b
a*&b*
(ab)*&(cd)*
(a&b)*&(c&d)*
(dog&cat&pig)
(a*b&c*)m(ac*&(cd)*&b*a)
