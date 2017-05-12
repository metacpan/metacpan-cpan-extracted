#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Letter;
use Game::WordBrain::Word;

subtest 'Call ->word' => sub {
    my @letters;
    for my $letter (qw( a b c d e f )) {
        push @letters, Game::WordBrain::Letter->new({
            letter => $letter,
            row    => 1,
            col    => 1,
        });
    }

    my $word = Game::WordBrain::Word->new({
        letters => \@letters,
    });

    cmp_ok( $word->word, 'eq', 'abcdef', 'Correct word' );
};

done_testing;
