use Test::More 'no_plan';

use Games::Poker::TexasHold'em; 
my $test = Games::Poker::TexasHold'em->new(
    bet => 10,
    players => [
        { name => "RutnBot-T1",  bankroll => 251131 },
        { name => "UmmiteBotD",  bankroll => -22077 },
        { name => "Pokibrat-T2", bankroll => 104093 },
        { name => "Pokibrat-T1", bankroll => 335515 }
    ],
    button => "UmmiteBotD"
);

$test->blinds;
$test->call;
is($test->bankroll("UmmiteBotD"), -22087, "First call OK");
$test->fold;
$test->raise(10);
$test->fold;
$test->raise(10);
is ($test->{current_bet}, 20, "We're up to 20");
