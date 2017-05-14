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
use NFA;
use DFA;

my $string = undef;
while (<>) {
  $string .= $_;
}

$/++; # slurp mode, i.e., read in all of __DATA__ at once
my @test = split("\n",<DATA>);

my $nfa1 = NFA->new();
$nfa1->load_string($string);
my $dfa1 = $nfa1->to_dfa();
print STDERR $dfa1->info();
my $dfa2 = $dfa1->clone();
my @removed = $dfa2->minimize();
if (@removed) {print ($#removed+1)." removed\n";};
print STDERR $dfa2->info();
my $c = 0;
foreach (@test) {
  $c++;
  chomp;
  if ($dfa1->is_valid($_)) {
    print STDERR "(Normal DFA)       Line $c: $_ \n";
  }
  if ($dfa2->is_valid($_)) {
    print STDERR "(Optimized DFA)    Line $c: $_ \n";
  }
}

__DATA__
abb
bcd
a
abcb
cccc
abcb
bbcc
aaa
b
abcccd
aaaaaa
bcb
bbababaaa
abbcb
cabaa
e
bccbb
aacb
bcbcabc
bd

bbbb
cbc
abcde
dog
cat
sit
