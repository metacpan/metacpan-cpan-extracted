#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Letter;
use Game::WordBrain::Word;
use Game::WordBrain::Solution;

subtest 'Create a Solution' => sub {
    my @word1_letters;
    for my $letter (qw( a b c d e f )) {
        push @word1_letters, Game::WordBrain::Letter->new({
            letter => $letter,
            row    => 1,
            col    => 1,
        });
    }

    my $word1 = Game::WordBrain::Word->new({
        letters => \@word1_letters,
    });

    my @word2_letters;
    for my $letter (qw( g h i j k )) {
        push @word2_letters, Game::WordBrain::Letter->new({
            letter => $letter,
            row    => 1,
            col    => 1,
        });
    }

    my $word2 = Game::WordBrain::Word->new({
        letters => \@word2_letters,
    });

    my @word3_letters;
    for my $letter (qw( l m n o p q r s t )) {
        push @word3_letters, Game::WordBrain::Letter->new({
            letter => $letter,
            row    => 1,
            col    => 1,
        });
    }

    my $word3 = Game::WordBrain::Word->new({
        letters => \@word3_letters,
    });

    my $solution;
    lives_ok {
        $solution = Game::WordBrain::Solution->new({
            words => [ $word1, $word2, $word3 ]
        });
    } 'Lives through creation of solution';

    isa_ok( $solution, 'Game::WordBrain::Solution' );
    is_deeply( $solution->{words}, [ $word1, $word2, $word3 ], 'Correct words' );
};

done_testing;
