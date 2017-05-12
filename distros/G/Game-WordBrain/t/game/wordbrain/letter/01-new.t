#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Letter;

subtest 'Create Letter' => sub {
    my $letter;
    lives_ok {
        $letter = Game::WordBrain::Letter->new({
            letter => 'a',
            row    => 1,
            col    => 3,
        });
    } 'Lives through creation of letter';

    isa_ok( $letter, 'Game::WordBrain::Letter' );

    cmp_ok( $letter->{letter}, 'eq', 'a', 'Correct letter' );
    cmp_ok( $letter->{row}, '==', 1, 'Correct row' );
    cmp_ok( $letter->{col}, '==', 3, 'Correct col' );
};

done_testing;
