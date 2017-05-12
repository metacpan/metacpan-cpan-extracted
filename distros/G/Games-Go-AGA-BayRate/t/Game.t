#===============================================================================
#
#  DESCRIPTION:  Tests for Games::Go::AGA::BayRate::Game
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@hellosix.com
#      CREATED:  05/24/2011 12:53:53 PM
#===============================================================================

use strict;
use warnings;

use Test::More tests => 49;  # last test to print

use Carp;

our $VERSION = '0.104'; # VERSION

sub in_range {
    my ($val, $expect, $range) = @_;

    return ($val < $expect + $range and
            $val > $expect - $range);
}

use_ok('Games::Go::AGA::BayRate::Game');

my $game = Games::Go::AGA::BayRate::Game->new (
    komi        => -8.5,           # Komi
    handicap    => 0,              # Actual handicap
    whiteWins   => 1,              # True if White wins
    white       => 'white player', # white player
    black       => 'black player', # black player
);


my $handicap = 0;
my $komi = -8.5;

foreach my $expect (
# handicapeqv, sigma_px
    [1.147750, 1.089811],   # handicap 0, komi -7.5
    [1.072050, 1.085515],   # handicap 0, komi -6.5
    [0.996350, 1.081519],   # handicap 0, komi -5.5
    [0.920650, 1.077823],   # handicap 0, komi -4.5
    [0.844950, 1.074427],   # handicap 0, komi -3.5
    [0.769250, 1.071330],   # handicap 0, komi -2.5
    [0.693550, 1.068534],   # handicap 0, komi -1.5
    [0.617850, 1.066036],   # handicap 0, komi -0.5
    [0.542150, 1.063839],   # handicap 0, komi  0.5
    [0.466450, 1.061941],   # handicap 0, komi  1.5
    [0.390750, 1.060342],   # handicap 0, komi  2.5
    [0.315050, 1.059044],   # handicap 0, komi  3.5
    [0.239350, 1.058045],   # handicap 0, komi  4.5
    [0.163650, 1.057346],   # handicap 0, komi  5.5
    [0.087950, 1.056946],   # handicap 0, komi  6.5
    [0.012250, 1.056846],   # handicap 0, komi  7.5
    ) {
    $komi = $game->get_komi + 1.0;
    $game->set_komi($komi);
    $game->set_handicap($handicap);
    $game->calc_handicapeqv;
    my $handicapeqv = $game->get_handicapeqv;
    my $sigma_px = $game->get_sigma_px;

    #printf "handi=%d komi=%4.1f => handicapeqv, sigma_px=%f, %f\n", $handicap, $komi, $handicapeqv, $sigma_px;
    ok(in_range($handicapeqv, $expect->[0], .00005), "handicapeqv(is $handicapeqv, expect $expect->[0])");
    ok(in_range($sigma_px, $expect->[1], .00005), "sigma_px   (is $sigma_px, expect $expect->[1])");
}

$handicap = 1;
foreach my $expect (
# handicapeqv, sigma_px
    [2.151400, 1.143754],   # handicap 2, komi -2
    [3.227100, 1.198501],   # handicap 3, komi -3
    [4.302800, 1.242478],   # handicap 4, komi -4
    [5.378500, 1.292154],   # handicap 5, komi -5
    [6.454200, 1.340881],   # handicap 6, komi -6
    [7.529900, 1.383428],   # handicap 7, komi -7
    [8.605600, 1.425955],   # handicap 8, komi -8
    [9.681300, 1.467792],   # handicap 9, komi -9
    ) {
    $handicap++;
    $komi = -$handicap;
    $game->set_komi($komi);
    $game->set_handicap($handicap);
    $game->calc_handicapeqv;
    my $handicapeqv = $game->get_handicapeqv;
    my $sigma_px = $game->get_sigma_px;

    #printf "handi=%d komi=%4.1f => handicapeqv, sigma_px=%f, %f\n", $handicap, $komi, $handicapeqv, $sigma_px;
    ok(in_range($handicapeqv, $expect->[0], .00005), "handicapeqv(is $handicapeqv, expect $expect->[0])");
    ok(in_range($sigma_px, $expect->[1], .00005), "sigma_px   (is $sigma_px, expect $expect->[1])");
}
