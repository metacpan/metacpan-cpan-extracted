#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 156;

use Games::Cards::Bridge::Contract;

while(<DATA>){
  s/^\s+//g;
  s/\s+$//sg;
  s/^#.+//;
  next unless length;
  my ($down, @scores) = split ' ', $_;
  foreach my $i ( 0..$#scores ){
    my $expected = -1 * $scores[$i];
    my $vul = $i >= 3;
    my $dbl = $i % 3;
    my $contract = Games::Cards::Bridge::Contract->new( declarer=>'N', trump=>'C', bid=>7, down=>$down, vul=>$vul, penalty=>$dbl);
    my $pts = $contract->duplicate_score;
    is($pts, $expected, sprintf("-%d vul=%d dbl=%d Dup: %d", $down, $vul, $dbl, $expected) );
    (undef, undef, $pts) = $contract->rubber_score;
    $pts *= -1;
    is($pts, $expected, sprintf("-%d vul=%d dbl=%d Rub: %d", $down, $vul, $dbl, $expected) );
  }
}

__DATA__
#		DEFEATED CONTRACTS
#	Non-Vulnerable		Vulnerable
#Down	Undbl	Dbl	Redbl	Undbl	Dbl	Redbl
1	50	100	200	100	200	400
2	100	300	600	200	500	1000
3	150	500	1000	300	800	1600
4	200	800	1600	400	1100	2200
5	250	1100	2200	500	1400	2800
6	300	1400	2800	600	1700	3400
7	350	1700	3400	700	2000	4000
8	400	2000	4000	800	2300	4600
9	450	2300	4600	900	2600	5200
10	500	2600	5200	1000	2900	5800
11	550	2900	5800	1100	3200	6400
12	600	3200	6400	1200	3500	7000
13	650	3500	7000	1300	3800	7600

