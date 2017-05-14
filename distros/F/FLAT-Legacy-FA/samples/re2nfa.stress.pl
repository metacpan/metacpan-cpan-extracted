#!/usr/bin/env perl

#
# Brett D. Estrade <estrabd@mailcan.com>
#
# Generates random regexes to test - can set % chance that *, |, or ()s will occur
#


# $Revision: 1.2 $ $Date: 2006/02/23 06:33:44 $ $Author: estrabd $

$^W++;
$|++;

use strict;
use lib qw(../);
use FLAT::FA::RE;
use FLAT::FA::NFA;
use FLAT::FA::DFA;
use Getopt::Long;  # used to process commandline options

# skirt around deep recursion warning annoyance
local $SIG{__WARN__} = sub { $_[0] =~ /^Deep recursion/ or warn $_[0] };
srand $$;

my %CMDLINEOPTS = ();
$CMDLINEOPTS{LENGTH} = 8;
$CMDLINEOPTS{OR} = 10;
$CMDLINEOPTS{STAR} = 10;
$CMDLINEOPTS{OPEN} = 5;
$CMDLINEOPTS{CLOSE} = 5;
$CMDLINEOPTS{n} = 100;

 GetOptions("l=s"        => \$CMDLINEOPTS{LENGTH},
 	    "n=s"        => \$CMDLINEOPTS{n},
            "or=s"       => \$CMDLINEOPTS{OR},
            "star=s"     => \$CMDLINEOPTS{STAR},
	    "open=s"     => \$CMDLINEOPTS{OPEN},
	    "close=s"    => \$CMDLINEOPTS{CLOSE},
	    );
 
sub getRandomChar {
  my $ch = '';
  # Get a random character between 0 and 127.
  do {
    $ch = int(rand 2);
  } while ($ch !~ m/[a-zA-Z0-9]/);  
  return $ch;
}

sub getRandomRE {
  my $str = '';
  my @closeparens = ();
  for (1..$CMDLINEOPTS{LENGTH}) {
    $str .= getRandomChar();  
    # % chance of an "or"
    if (int(rand 100) < $CMDLINEOPTS{OR}) {
      $str .= "|";
    } elsif (int(rand 100) < $CMDLINEOPTS{STAR}) {
      $str .= "*";    
    } elsif (int(rand 100) < $CMDLINEOPTS{OPEN}) {
      $str .= "(";
      push(@closeparens,')');
    } elsif (int(rand 100) < $CMDLINEOPTS{CLOSE} && @closeparens) {
      $str .= pop(@closeparens);
    }
  }
  # empty out @closeparens if there are still some left
  if (@closeparens) {
    #$str .= join('',@closeparens);  
  }
  return $str;
}

my $re = FLAT::FA::RE->new();

my $max = 0;
my $maxre = '';
my $total = 0;
my $total_red = 0;
my $red_count = 0;
for (1..$CMDLINEOPTS{n}) {  
  my $regex = getRandomRE();
  print "$regex\n";
  $re->set_re($regex);
  my $nfa = $re->to_nfa();
  my $dfa = $nfa->to_dfa();
  my @removed = $dfa->minimize();
  if (($#removed+1) > $max) {
    $max = ($#removed+1);
    $total += ($#removed+1);
    $maxre = $regex;
  }
  if (@removed) {
#    print STDERR ($#removed+1)." states removed\n";
    $total_red += ($#removed+1);
    $red_count++;
  }
}
print STDERR "Report:\n";
print STDERR "Total Reduced: $red_count\n";
print STDERR "Ave. Reduce Overall: ".($total/1000)."\%\n";
print STDERR "Ave. Of Reduced: ".($total_red/$red_count)." states removed\n";
print STDERR "Max Removed: $max\n";
print STDERR "on RE: $maxre\n";
print STDERR "RE Symbols: $CMDLINEOPTS{LENGTH}\n";
print STDERR "OR Chance: $CMDLINEOPTS{OR}\%\n";
print STDERR "STAR  Chance: $CMDLINEOPTS{STAR}\%\n";
print STDERR "OPEN Parens Chance: $CMDLINEOPTS{OPEN}\%\n";
print STDERR "CLOSE Parens Chance: $CMDLINEOPTS{CLOSE}\%\n";
