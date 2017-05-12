use strict;
use Test::Simple tests => 8;
use Games::GuessWord;

my $g = Games::GuessWord->new(words => ["foo"],
                              chances => 3);
ok($g, "should create object ok");

$g->guess("e");
ok(!$g->lost, "shouldn't have lost");

$g->guess("i");
ok(!$g->lost, "shouldn't have lost");

$g->guess("t");
ok($g->lost, "should have lost");

$g->new_word;
$g->starting_chances(4);

$g->guess("e");
ok(!$g->lost, "shouldn't have lost");

$g->guess("i");
ok(!$g->lost, "shouldn't have lost");

$g->guess("f");
ok(!$g->lost, "shouldn't have lost");

$g->guess("t");
ok($g->lost, "should have lost");







