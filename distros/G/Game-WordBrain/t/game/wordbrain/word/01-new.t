#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Letter;
use Game::WordBrain::Word;

subtest 'Create Word' => sub {
    my @letters;
    for my $letter (qw( a b c d e f )) {
        push @letters, Game::WordBrain::Letter->new({
            letter => $letter,
            row    => 1,
            col    => 1,
        });
    }

    my $word;
    lives_ok {
        $word = Game::WordBrain::Word->new({
            letters => \@letters,
        });
    } 'Lives through creation of word';

    isa_ok( $word, 'Game::WordBrain::Word' );
    is_deeply( $word->{letters}, \@letters, 'Correct letters' );
};

done_testing;
