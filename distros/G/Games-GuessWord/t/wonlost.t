use strict;
use Test::Simple tests => 19;
use Games::GuessWord;

my $g = Games::GuessWord->new(words => ["foo"]);
ok($g, "should create object ok");

$g->guess("e");
ok(!$g->lost, "shouldn't have lost");
ok(!$g->won, "shouldn't have won");

$g->guess("i");
ok(!$g->lost, "shouldn't have lost");
ok(!$g->won, "shouldn't have won");

$g->guess("t");
ok(!$g->lost, "shouldn't have lost");
ok(!$g->won, "shouldn't have won");

$g->guess("z");
ok(!$g->lost, "shouldn't have lost");
ok(!$g->won, "shouldn't have won");

$g->guess("k");
ok(!$g->lost, "shouldn't have lost");
ok(!$g->won, "shouldn't have won");

$g->guess("a");
ok(!$g->won, "shouldn't have won");
ok($g->lost, "should have lost");

$g->new_word;

$g->guess("e");
ok(!$g->lost, "shouldn't have lost");
ok(!$g->won, "shouldn't have won");

$g->guess("f");
ok(!$g->lost, "shouldn't have lost");
ok(!$g->won, "shouldn't have won");

$g->guess("o");
ok(!$g->lost, "shouldn't have lost");
ok($g->won, "should have won");






