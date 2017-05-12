######################################################################
# Test suite for Games::Blackjack
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);

BEGIN { use_ok('Games::Blackjack') };

######################################################################
# Play a forged game
######################################################################
# Create new shoe of cards
my $shoe = Games::Blackjack::Shoe->new(nof_decks => 4);

    # Create two hands, player/dealer
my $player = Games::Blackjack::Hand->new(shoe => $shoe);
my $dealer = Games::Blackjack::Hand->new(shoe => $shoe);

push @{$dealer->{cards}}, ["Spade", "10"];
push @{$dealer->{cards}}, ["Spade", "10"];
push @{$dealer->{cards}}, ["Spade", "10"];

push @{$player->{cards}}, ["Heart", "A"];
push @{$player->{cards}}, ["Heart", "10"];

ok($dealer->busted());
ok(!$player->busted());
ok(!$dealer->blackjack());
ok($player->blackjack());

is($player->count("soft"), 21);
is($player->count("hard"), 11);
ok(!defined $dealer->count("soft"));
ok(!defined $dealer->count("hard"));

SKIP:
{
    #skip "Skipping until Q::S 2.02 bug is fixed (see Changes)", 1;

######################################################################
# Q::S 2.02 bug
######################################################################
    # Create new shoe of cards
my $shoe = Games::Blackjack::Shoe->new(nof_decks => 4);

    # Create player hand
my $player = Games::Blackjack::Hand->new(shoe => $shoe);

    # Forge A-4-A into player's hand
$player->{cards} = [['Spades', 'A'], ['Spades', '4'], ['Spades', 'A']];
my $count = 0;

    # Do this a number of times since Q:S seems to randomize results
for(1..10) {
    my $soft = $player->count("soft");
    $count += $soft;
}
is($count, 160);
}
