#!/usr/bin/perl -Tw
# enable taint mode & warnings

#########################

use Test::More tests => 8;
BEGIN { use_ok('Games::Tournament::BlackJack::Shoe') };

#########################

Games::Tournament::BlackJack::Shoe::setShoeSize(4);
is(Games::Tournament::BlackJack::Shoe::shoeSize, 4);

# check class of returned objects
$my_deck = openNewDeck(); # should be imported
$my_shoe = openNewShoe(); # same

isa_ok($my_deck, 'Games::Tournament::BlackJack::Shoe');
isa_ok($my_shoe, 'Games::Tournament::BlackJack::Shoe');

# ensure output is generated from sprintCards
my $output = '';
$output .= $my_deck->sprintCards();
isnt($output, '', "Output generated from printCards");

# ensure output is same when method is called with non-oo syntax
my $output2 = '';
$output2 .= Games::Tournament::BlackJack::Shoe::sprintCards($my_deck);
is($output2, $output, "Output generated from printCards");

# try calling with just an array of cards
$output3 .= Games::Tournament::BlackJack::Shoe::sprintCards('Ace_of_Spades', 'King_of_Hearts');
isnt($output3, '', "Output generated from printCards");

# ensure shuffle changes things
my $output4 = '';
$my_deck->shuffle();
$output4 .= $my_deck->sprintCards();
isnt($output, $output4, "Shuffle didn't change print output");

