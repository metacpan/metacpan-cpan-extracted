#!/usr/bin/perl

use strict;
use warnings;

$| = 1;

use Math::Random::MT::Auto qw(shuffle);

MAIN:
{
    my $deck = shuffle(0..51);
    my @cards = qw(A 1 2 3 4 5 6 7 8 9 10 J Q K);
    my @suits = qw(C D H S);

    print('My hand: ');
    for my $card (0 .. 4) {
        print($cards[$$deck[$card] % 13], '-', $suits[$$deck[$card] / 13], '  ');
    }
    print("\n\n");

    print('Your hand: ');
    for my $card (5 .. 9) {
        print($cards[$$deck[$card] % 13], '-', $suits[$$deck[$card] / 13], '  ');
    }
    print("\n");
}

exit(0);

# EOF
