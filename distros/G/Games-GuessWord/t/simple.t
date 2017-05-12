use strict;
use Test::Simple tests => 100;
use Games::GuessWord;

my $g = Games::GuessWord->new(words => ["sleepy"]);
ok($g, "should create object ok");

ok($g->score == 0, "score should be 0");
ok($g->chances == 6, "should have 6 chances left");
ok($g->secret eq "sleepy", "secret should be sleepy");
ok($g->answer eq "******", "guess should be ******");
ok($g->guesses == 0, "guesses should be empty");

ok($g->guess("e"), "should accept guess ok");
ok($g->score == 7, "score should be 7");
ok($g->chances == 6, "should have 6 chances left");
ok($g->answer eq "**ee**", "guess should be **ee**");
ok($g->guesses == 1, "guesses should contain e");

ok($g->guess("t"), "should accept guess ok");
ok($g->score == 7, "score should be 7");
ok($g->chances == 5, "should have 5 chances left");
ok($g->answer eq "**ee**", "guess should be **ee**");
ok($g->guesses == 2, "guesses should contain e,t");

ok($g->guess("s"), "should accept guess ok");
ok($g->score == 13, "score should be 3");
ok($g->chances == 5, "should have 5 chances left");
ok($g->answer eq "s*ee**", "guess should be s*ee**");
ok($g->guesses == 3, "guesses should contain e,t,s");

ok($g->guess("l"), "should accept guess ok");
ok($g->score == 19, "score should be 19");
ok($g->chances == 5, "should have 5 chances left");
ok($g->answer eq "slee**", "guess should be slee**");
ok($g->guesses == 4, "guesses should contain e,t,s,l");

ok($g->guess("p"), "should accept guess ok");
ok($g->score == 25, "score should be 25");
ok($g->chances == 5, "should have 5 chances left");
ok($g->answer eq "sleep*", "guess should be sleep*");
ok($g->guesses == 5, "guesses should contain e,t,s,l,p");

ok($g->guess("y"), "should accept guess ok");
ok($g->score == 31, "score should be 31");
ok($g->chances == 5, "should have 5 chances left");
ok($g->answer eq "sleepy", "guess should be sleepy");
ok($g->guesses == 6, "guesses should contain e,t,s,l,p,y");

# Wahey, I won, let's try again...

ok($g->new_word, "should get new word ok");
ok($g->score == 31, "score should be 0");
ok($g->chances == 6, "should have 6 chances left");
ok($g->secret eq "sleepy", "secret should be sleepy");
ok($g->answer eq "******", "guess should be ******");
ok($g->guesses == 0, "guesses should be empty");

ok($g->guess("a"), "should accept guess ok");
ok($g->score == 31, "score should be 31");
ok($g->chances == 5, "should have 5 chances left");
ok($g->answer eq "******", "guess should be ******");
ok($g->guesses == 1, "guesses should be contain a");

ok($g->guess("b"), "should accept guess ok");
ok($g->score == 31, "score should be 31");
ok($g->chances == 4, "should have 5 chances left");
ok($g->answer eq "******", "guess should be ******");
ok($g->guesses == 2, "guesses should be contain a,b");

ok($g->guess("c"), "should accept guess ok");
ok($g->score == 31, "score should be 31");
ok($g->chances == 3, "should have 5 chances left");
ok($g->answer eq "******", "guess should be ******");
ok($g->guesses == 3, "guesses should be contain a,b,c");

ok($g->guess("d"), "should accept guess ok");
ok($g->score == 31, "score should be 31");
ok($g->chances == 2, "should have 5 chances left");
ok($g->answer eq "******", "guess should be ******");
ok($g->guesses == 4, "guesses should be contain a,b,c,d");

ok($g->guess("e"), "should accept guess ok");
ok($g->score == 34, "score should be 31");
ok($g->chances == 2, "should have 5 chances left");
ok($g->answer eq "**ee**", "guess should be **ee**");
ok($g->guesses == 5, "guesses should be contain a,b,c,d,e");

ok($g->guess("f"), "should accept guess ok");
ok($g->score == 34, "score should be 31");
ok($g->chances == 1, "should have 5 chances left");
ok($g->answer eq "**ee**", "guess should be **ee**");
ok($g->guesses == 6, "guesses should be contain a,b,c,d,e,f");

ok($g->guess("g"), "should accept guess ok");
ok($g->score == 34, "score should be 31");
ok($g->chances == 0, "should have 5 chances left");
ok($g->answer eq "**ee**", "guess should be **ee**");
ok($g->guesses == 7, "guesses should be contain a,b,c,d,e,f,g");

ok(!defined($g->guess("h")), "should not accept guess ok");

$g = Games::GuessWord->new(file => "t/words");
ok($g, "should create object ok");
foreach (1..21) {
#  print $g->secret . "\n";
  $g->new_word;
  ok($g->secret =~ /^(awake|asleep|alive)$/, "should read word in ok");
}





