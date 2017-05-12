#!/usr/bin/perl -w

use Test::More tests => 17;

use Games::Boggle;

my $board = Games::Boggle->new("TRTO xIHP TEEB MEQP");
isa_ok $board, "Games::Boggle";

my @fail = qw/BEETS TITHED THREE PEEP QEET TEEPEE/;
foreach my $word (@fail) {
  ok !$board->has_word($word), "Can't get $word";
}

my %ok = (
  BEET => [2, [12]],
  Tithe => [4, [1, 9]],
  PEEM => [4, [8, 16]],
  teX => [1, [9]],
	Queit => [6, [15]],
);
foreach my $word (keys %ok) {
  is scalar $board->has_word($word), $ok{$word}[0], "Board has $word";
  is_deeply [$board->has_word($word)], $ok{$word}[1], " in correct places";
}
