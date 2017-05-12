#!/usr/bin/perl

use strict;
use warnings;

use Games::Backgammon;

use Set::Scalar;
use Data::Dumper;
use Test::Exception;
local $Data::Dumper::Indent = undef;

our $GAME = Games::Backgammon->new(position => {whitepoints => {},
                                   blackpoints => {},
                                   atroll      => 'white'});

# [{at move points},{not at move points},[legal moves]]
use constant POSITION_AND_LEGAL_MOVES => (
    [1, 2, {1 => 1, 2 => 1},{},["2/off 1/off", "2/off"]],
    [5, 6, {1 => 1, 2 => 1},{},["2/off 1/off"]],
    [1, 1, {24 => 2},       {},["24/20", "24/21 24/23", "24/22(2)"]],
    [5, 6, {24 => 1}, {7 => 1}, ["24/18*/13", "24/13"]],
    [5, 6, {24 => 1}, {7 => 2}, ["24/13"]],
    [6, 6, {24 => 1}, {7 => 2}, []],
    [5, 6, {bar => 1},{6 => 1}, ["bar/19*/14", "bar/14"]],
    [3, 4, {bar => 1,6 => 1},{1 => 2, 2 => 2, 5 => 2, 6 => 2, 7 => 2, 23 => 2},
       ["bar/21 6/3"]],
);                                            

use Test::More tests => 8 * 8 + 8;

sub eq_move { eq_set([split ' ', shift], [split ' ', shift]) }

sub eq_move_list {
    my $m1 = Set::Scalar->new(@{$_[0]});
    my $m2 = Set::Scalar->new(@{$_[1]});
    is $m1->size, $m2->size, "Same size of both move lists"
    or diag "$m1 <=> $m2";
    
    foreach my $move1 ($m1->elements) {
        foreach my $move2 ($m2->elements) {
            next unless eq_move($move1, $move2);
            $m1->delete($move1);  # found 2 equal moves
            $m2->delete($move2);
        }
    }
    
    ok $m1->is_empty && $m2->is_empty, "Both move lists are equal"
    or diag "Couldn't find equivalent moves for $m1 <=> $m2\n".
            "(Original (@{$_[0]}) (@{$_[1]})" .
            "(ID: " . $GAME->position_id . ")";
}

foreach (POSITION_AND_LEGAL_MOVES) {
    my ($n1, $n2, $points_at_roll,$points_opponent,$legal_moves) = @$_;
    $GAME->set_position(whitepoints => $points_at_roll,
                        blackpoints => $points_opponent,
                        atroll      => 'white');
    eq_move_list([$GAME->legal_moves($n1,$n2)],$legal_moves);
    eq_move_list([$GAME->legal_moves($n2,$n1)],$legal_moves);


    $GAME->set_position(blackpoints => $points_at_roll,
                        whitepoints => $points_opponent,
                        atroll      => 'black');
    eq_move_list([$GAME->legal_moves($n1,$n2)],$legal_moves);
    eq_move_list([$GAME->legal_moves($n2,$n1)],$legal_moves);
}

dies_ok {$GAME->legal_moves(0,2)} "Should die with (0,2) roll";
dies_ok {$GAME->legal_moves(1,7)} "Should die with (1,7) roll";
dies_ok {$GAME->legal_moves()}    "Should die without a roll";
dies_ok {$GAME->legal_moves(2)}   "Should die with a (2,) roll";
dies_ok {$GAME->legal_moves(3.5,2)} "Should die with a (3.5,2) roll";
dies_ok {$GAME->legal_moves(2,3.5)} "Should die with a (2,3.5) roll";
dies_ok {$GAME->legal_moves("five","six")} "Should die with a ('five','six') roll";
dies_ok {$GAME->legal_moves(1,2,3)} "Should die with a (1,2,3) roll";
