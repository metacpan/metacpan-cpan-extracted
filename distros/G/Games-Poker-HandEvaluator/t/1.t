use Test::More tests => 4;
use_ok("Games::Poker::HandEvaluator");
Games::Poker::HandEvaluator->import(qw(handval evaluate));

my $hand_a = evaluate("Jc 7c 8c Jh 3c 7s 5c");
my $hand_b = evaluate("9d 5d Ks 7h 5s 7s 4c");
ok ($hand_a > $hand_b, "Flush beats two pair");
is (handval($hand_a), "Flush (J 8 7 5 3)");
is (handval($hand_b), "TwoPair (7 5 K)");
