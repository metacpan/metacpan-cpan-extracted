#===============================================================================
#
#  DESCRIPTION:  Tests for Games::Go::AGA::BayRate::Player
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@hellosix.com
#      CREATED:  05/24/2011 12:53:53 PM
#===============================================================================

use strict;
use warnings;

use Test::More tests => 8;                      # last test to print

our $VERSION = '0.104'; # VERSION

sub in_range {
    my ($val, $expect, $range) = @_;

    return ($val < $expect + $range and
            $val > $expect - $range);
}

use_ok('Games::Go::AGA::BayRate::Player');

my $player = Games::Go::AGA::BayRate::Player->new (
        seed    => -48,     # Initial rating
        sigma   => 2,       # Standard deviation of rating
        rating  => 1.5,     # Current rating in the iteration
        id      => 'player 0',
        index   => -1,      # Index of the GSL vector element that corresponds to the rating of this player
);

# try initial sigma for ranks from 48k to 12d
foreach my $expect (
    5.491812,   # 48k
    4.512207,   # 38k
    3.544011,   # 28k
    2.599999,   # 18k
    1.720464,   #  8k
    1.166191,   #  2d
    1.000000,   # 12d
    ) {
    my $sigma = $player->calc_init_sigma;
    # printf "seed %f => sigma %f\n", $player->get_seed, $sigma;
    ok(in_range($sigma, $expect, .00005), "calc_init_sigma(is $sigma, expect $expect)");
    $player->set_seed($player->get_seed + 10);
}



