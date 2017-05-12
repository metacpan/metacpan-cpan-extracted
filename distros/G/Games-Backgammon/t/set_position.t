#!/usr/bin/perl

use strict;
use warnings;

use Games::Backgammon;

use Test::More tests => 181;
use Test::Differences;
use Test::Exception;

use Data::Dumper;

use constant IDEAL_40 => {3 => 1, 4 => 1, 5 => 3, 6 => 3};
use constant IDEAL_79 => {4 => 3, 5 => 5, 6 => 7};

use constant TWENTY_CHECKERS => {
    whitepoints => {1 => 1, 2 => 19},
    blackpoints => {6 => 1},
    atroll      => 'black'
};

use constant DEFAULT_BOARDS => (
    {whitepoints => {off => 15}, blackpoints => {off => 15}, atroll => 'black'},
    {whitepoints => {},          blackpoints => {},          atroll => 'black'},
    {whitepoints => {off => 15}, blackpoints => {off => 15}},
    {atroll => 'black'},
    {},
);

use constant STARTING_POS => (
    map {($_ . "points" => {6 => 5, 8 => 3, 13 => 5, 24 => 2})} qw/white black/
);
use constant BOTH_PLAYERS_WITH_CLOSED_BOARD_AND_ON_BAR => (
    map {$_ . "points" => {map({$_ => 2} (1 .. 7)), bar => 1}} qw/white black/,
);

foreach my $atroll ('BLACK', 'WHITE') {

    my $game = Games::Backgammon->new(
        position => {
          whitepoints => {%{IDEAL_40()}, bar => 1},
          blackpoints => IDEAL_79(),
          atroll      => $atroll
        }
    );
    
    eq_or_diff {$game->whitepoints}, 
               {off => 15-9, bar => 1, %{IDEAL_40()}}, 
               "White points in ideal 40";
    eq_or_diff {$game->blackpoints}, 
               IDEAL_79,
               "Black points in ideal 79";

    is $game->atroll, lc($atroll), "$atroll was at roll and should be lc now";

    my %white = $game->whitepoints;
    my %black = $game->blackpoints;

    for (1 .. 24, 'off', 'bar') {
        is $game->whitepoints($_), ($white{$_} || 0), "Point $_ of white";
        is $game->blackpoints($_), ($black{$_} || 0), "Point $_ of black";
    }
      
}

foreach my $pos (DEFAULT_BOARDS) {
    my $game = Games::Backgammon->new(position => $pos);
    eq_or_diff {$game->whitepoints}, {off => 15}, "White points at default";
    eq_or_diff {$game->blackpoints}, {off => 15}, "Black points at default";
    is $game->atroll, 'black', "Black is at roll by default";
}

for ("X", "weiss", "", undef) {
    dies_ok {Games::Backgammon->new(position => {STARTING_POS, atroll => $_})}
            "Should die if neither white nor black is at roll, but " . Dumper($_);
}

foreach my $atroll (qw/black white/) {
    for my $point (1 .. 24) {
        my %p = (
            whitepoints => {$point => 1},
            blackpoints => {25 - $point => 1},
            atroll      => $atroll
        );
        dies_ok {Games::Backgammon->new(position => \%p)}
                "Should die if both have a checker at the $point, $atroll atroll";
    }
}

for (qw/black white/) {
    my %p = (BOTH_PLAYERS_WITH_CLOSED_BOARD_AND_ON_BAR, atroll => $_);
    dies_ok {Games::Backgammon->new(position => \%p)}
            "Should die if both have a checker on the bar against bothside closed boards ($_ atroll)";
}

throws_ok {Games::Backgammon->new(position => {whitepoints => {blabla => 1}})}
        qr/unknown/i,
        "Should die with unkown points";

throws_ok {Games::Backgammon->new(position => TWENTY_CHECKERS)}
        qr/illegal\s*position/i,
        "More than 15 checkers should result in an illegal position";
