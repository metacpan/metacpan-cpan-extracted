#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More tests => 2 + 27 + 1;
use Test::NoWarnings;

use Game::Life::NDim;
use Game::Life::NDim::Dim;

my $gof = Game::Life::NDim::game_of_life(dims => [2, 2], rand => 1);
my $life = Game::Life::NDim::Life->new( board => $gof->board, type => 0, position => Game::Life::NDim::Dim->new([0,0]) );

type();
transform();

sub type {
    diag "type";
    is($life->type, 0, 'Type is 0');
    is("$life", 0, 'Stringified is 0');
}

sub transform {
    diag "transform";
    my $gof = Game::Life::NDim::game_of_life(dims => [9, 9, 9], rand => 1);
    my $life = Game::Life::NDim::Life->new( board => $gof->board, type => 0, position => Game::Life::NDim::Dim->new([0,0,0]) );

    my @a;
    my $transform = $life->transformer();
    is_deeply( $a = $transform->(), [-1, -1, -1], '[-1, -1, -1]');
    is_deeply( $a = $transform->(), [ 0, -1, -1], '[ 0, -1, -1]');
    is_deeply( $a = $transform->(), [ 1, -1, -1], '[ 1, -1, -1]');
    is_deeply( $a = $transform->(), [-1,  0, -1], '[-1,  0, -1]');
    is_deeply( $a = $transform->(), [ 0,  0, -1], '[ 0,  0, -1]');
    is_deeply( $a = $transform->(), [ 1,  0, -1], '[ 1,  0, -1]');
    is_deeply( $a = $transform->(), [-1,  1, -1], '[-1,  1, -1]');
    is_deeply( $a = $transform->(), [ 0,  1, -1], '[ 0,  1, -1]');
    is_deeply( $a = $transform->(), [ 1,  1, -1], '[ 1,  1, -1]');
    is_deeply( $a = $transform->(), [-1, -1,  0], '[-1, -1,  0]');
    is_deeply( $a = $transform->(), [ 0, -1,  0], '[ 0, -1,  0]');
    is_deeply( $a = $transform->(), [ 1, -1,  0], '[ 1, -1,  0]');
    is_deeply( $a = $transform->(), [-1,  0,  0], '[-1,  0,  0]');
    is_deeply( $a = $transform->(), [ 1,  0,  0], '[ 1,  0,  0]');
    is_deeply( $a = $transform->(), [-1,  1,  0], '[-1,  1,  0]');
    is_deeply( $a = $transform->(), [ 0,  1,  0], '[ 0,  1,  0]');
    is_deeply( $a = $transform->(), [ 1,  1,  0], '[ 1,  1,  0]');
    is_deeply( $a = $transform->(), [-1, -1,  1], '[-1, -1,  1]');
    is_deeply( $a = $transform->(), [ 0, -1,  1], '[ 0, -1,  1]');
    is_deeply( $a = $transform->(), [ 1, -1,  1], '[ 1, -1,  1]');
    is_deeply( $a = $transform->(), [-1,  0,  1], '[-1,  0,  1]');
    is_deeply( $a = $transform->(), [ 0,  0,  1], '[ 0,  0,  1]');
    is_deeply( $a = $transform->(), [ 1,  0,  1], '[ 1,  0,  1]');
    is_deeply( $a = $transform->(), [-1,  1,  1], '[-1,  1,  1]');
    is_deeply( $a = $transform->(), [ 0,  1,  1], '[ 0,  1,  1]');
    is_deeply( @a = $transform->(), [ 1,  1,  1], '[ 1,  1,  1]');
    is_deeply( $transform->(), undef);
    exit;
}
