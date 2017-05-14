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

print STDERR $nfa1->info();
$nfa1->pinch();
print STDERR $nfa1->info();
$nfa1->number_states();
print STDERR $nfa1->info();
exit;

my $dfa1 = $nfa1->to_dfa();
my $c = 0;
foreach (@test) {
  $c++;
  chomp;
  if ($dfa1->is_valid($_)) {
    print STDERR "Line $c: $_ \n";
  }
}
print STDERR "########################\n\n";

print $nfa1->to_string();

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
