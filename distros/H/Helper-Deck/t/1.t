use common::sense;

use Test::More tests => 22;

use Helper::Deck;

my $d1 = Helper::Deck->new;
isa_ok($d1,'Helper::Deck');

can_ok($d1,'roll');
my $roll1 = $d1->roll(6);
ok(($roll1 == 1 || $roll1 == 2 || $roll1 == 3 || $roll1 == 4 || $roll1 == 5 || $roll1 ==6),"Completed fair 6-sided die roll [${roll1}] .");

can_ok($d1, 'random_nick');
ok(length($d1->random_nick(('ace','bae','boo','nat'))) == 3,'Completed random nick selection.');
ok(length($d1->random_nick(('mike','mark','jule','john'))) == 4,'Completed random name selection.');

can_ok($d1, 'random_scenario');
my %scene1 = $d1->random_scenario(
    settings => [ 'the beach', 'the Yaht' ],
    objectives => [ 'get suntan', 'go swimming' ],
    antagonists => [ 'gull', 'kid' ],
    complications => [ 'very thirsty', 'very drunk' ],
);

ok($scene1{setting} eq 'the beach' || $scene1{setting} eq 'the Yaht', 'Scenario has the correct setting.');
ok($scene1{objective} eq 'get suntan' || $scene1{objective} eq 'go swimming', 'Scenario has the correct objective.');
ok($scene1{antagonist} eq 'gull' || $scene1{antagonist} eq 'kid', 'Scenario has the correct antagonist.');
ok($scene1{complication} eq 'very thirsty' || $scene1{complication} eq 'very drunk', 'Scenario has the correct complication.');

can_ok($d1, 'build_deck');
my $deck1 = $d1->build_deck;
my $card_count = 0;
foreach my $card (@{$deck1}) {
	$card_count++;
}

ok($card_count == 52, 'Deck has been built.');

can_ok($d1, 'shuffle_deck');
$deck1 = $d1->shuffle_deck($deck1);
ok($deck1->[0]->{'face'} ne 'Two' || $deck1->[0]->{'suit'} ne 'Spades' || $deck1->[-1]->{'face'} ne 'Ace' || $deck1->[-1]->{'suit'} ne 'Diamonds', 'Deck shuffled.');

can_ok($d1, 'top_card');
my $card1 = $d1->top_card($deck1);
ok(exists($card1->{'face'}) && exists($card1->{'suit'}), 'Top card drawn.');

can_ok($d1, 'card_to_string');
ok($d1->card_to_string($card1) =~ m/\sof\s/, 'Card illustrated as string.');

ok(scalar @{$d1->draw($deck1, 5)} == 5, 'Hand of cards drawn.');

can_ok($d1,'calculate_odds');
ok($d1->calculate_odds($deck1,$card1) eq '0 in 46', 'Calculated odds.');