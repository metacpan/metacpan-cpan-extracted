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
use lib qw(../);
use Time::HiRes qw(gettimeofday);
use RE;
use NFA;
use DFA;

# skirt around deep recursion warning annoyance
local $SIG{__WARN__} = sub { $_[0] =~ /^Deep recursion/ or warn $_[0] };

my $SEED = 'a';
my $re;
my $close = '';

sub init {
  # Seed the random number generator.
  srand $$;
} # end init sub

sub getRandomChar {
  my $ch = '';
  # Get a random character between 0 and 127.
  do {
    $ch = chr(int(rand 255)+1);
  } while ($ch !~ /[a-zA-Z0-9\*|\(]/);  
  if ($ch eq '(') {
    $ch = "|(";
    $close .= ')';
  }
  return $ch;
}

# Call sub init
&init();
  
for (1..64) {
#  print "$SEED\n";
  $re = RE->new();
  $re->set_re("$SEED$close");
  my ($s1,$usec1) = gettimeofday();
  my $dfa = $re->to_dfa();
  my $nfa = $re->to_nfa();
#  print $dfa->info(); 
  my ($s2,$usec2) = gettimeofday();
  my $t = $usec2 - $usec1;
  print "$_: $t\n";
  print "$SEED$close\n";
  $SEED .= getRandomChar();  
  print "$SEED$close\n";
}

