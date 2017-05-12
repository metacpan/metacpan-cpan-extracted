#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::WordToFind;

subtest 'Create WordToFind' => sub {
    my $word_to_find;
    lives_ok {
        $word_to_find = Game::WordBrain::WordToFind->new({
            num_letters => 5
        });
    } 'Lives through creation of word to find';

    isa_ok( $word_to_find, 'Game::WordBrain::WordToFind' );
    cmp_ok( $word_to_find->{num_letters}, '==', 5, 'Correct num_letters' );
};

done_testing;
