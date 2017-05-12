#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Letter;
use Game::WordBrain::WordToFind;
use Game::WordBrain;

subtest 'Construct Game' => sub {
    my $word_to_find1 = Game::WordBrain::WordToFind->new({ num_letters => 5 });
    my $word_to_find2 = Game::WordBrain::WordToFind->new({ num_letters => 5 });

    my @letters = (
        Game::WordBrain::Letter->new({ letter => 'a', row => 0, col => 0 }),
        Game::WordBrain::Letter->new({ letter => 'b', row => 0, col => 1 }),
        Game::WordBrain::Letter->new({ letter => 'c', row => 0, col => 2 }),
        Game::WordBrain::Letter->new({ letter => 'd', row => 1, col => 0 }),
        Game::WordBrain::Letter->new({ letter => 'e', row => 1, col => 1 }),
        Game::WordBrain::Letter->new({ letter => 'f', row => 1, col => 2 }),
        Game::WordBrain::Letter->new({ letter => 'g', row => 2, col => 0 }),
        Game::WordBrain::Letter->new({ letter => 'h', row => 2, col => 1 }),
        Game::WordBrain::Letter->new({ letter => 'i', row => 2, col => 2 }),
    );

    my $game;
    lives_ok {
        $game = Game::WordBrain->new({
            letters       => \@letters,
            words_to_find => [ $word_to_find1, $word_to_find2 ],
        });
    } 'Lives through creation of Game';

    isa_ok( $game, 'Game::WordBrain' );
    is_deeply( $game->{letters}, \@letters, 'Correct letters' );
    is_deeply( $game->{words_to_find}, [ $word_to_find1, $word_to_find2 ], 'Correct words_to_find' );
    ok( exists $game->{solutions}, 'solutions exists' );
    isa_ok( $game->{speller}, 'Game::WordBrain::Speller' );
    isa_ok( $game->{prefix}, 'Game::WordBrain::Prefix' );
};

done_testing;
