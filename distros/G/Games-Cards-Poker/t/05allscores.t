#!/usr/bin/perl
use warnings;use Test::More;
BEGIN { plan tests => 7462 }
use Games::Cards::Poker qw(:all);
for my $i (0..7461){my $h =  ScoreHand($i);
                    ok($i == HandScore($h), sprintf("roundtrip HandScore(ScoreHand( i )):%4d i:%4d h:%s",HandScore($h),$i,$h));}
#done_testing(7462); # instead of pre-declaring count, can just output it at the end
# don't want to just ok all, instead learn to single line count up to plan like more complex test suites do,
#   or loop main hand categories with subtests for contents (but how to not make every ok on separate line there either?)
