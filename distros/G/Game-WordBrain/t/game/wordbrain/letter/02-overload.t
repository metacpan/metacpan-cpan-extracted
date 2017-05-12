#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Letter;

subtest 'Stringify' => sub {
    my $letter = Game::WordBrain::Letter->new({
        letter => 'a',
        row    => 1,
        col    => 3,
    });

    cmp_ok( "$letter", 'eq', 'a', 'Correct stringified value' );
};

subtest 'Equality' => sub {
    subtest 'Equal' => sub {
        my @letters;
        for my $letter_num ( 0, 1 ) {
            push @letters, Game::WordBrain::Letter->new({
                letter => 'a',
                row    => 1,
                col    => 3,
            });
        }

        cmp_ok( $letters[0], '==', $letters[1], 'Correct equality' );
    };

    subtest 'Different letter' => sub {
        my $letter_1 = Game::WordBrain::Letter->new({
            letter => 'a',
            row    => 1,
            col    => 3,
        });

        my $letter_2 = Game::WordBrain::Letter->new({
            letter => 'b',
            row    => 1,
            col    => 3,
        });

        ok( !( $letter_1 == $letter_2 ), 'Correctly unequal' );
    };

    subtest 'Different row' => sub {
        my $letter_1 = Game::WordBrain::Letter->new({
            letter => 'a',
            row    => 1,
            col    => 3,
        });

        my $letter_2 = Game::WordBrain::Letter->new({
            letter => 'a',
            row    => 2,
            col    => 3,
        });

        ok( !( $letter_1 == $letter_2 ), 'Correctly unequal' );
    };

    subtest 'Different col' => sub {
        my $letter_1 = Game::WordBrain::Letter->new({
            letter => 'a',
            row    => 1,
            col    => 3,
        });

        my $letter_2 = Game::WordBrain::Letter->new({
            letter => 'a',
            row    => 1,
            col    => 2,
        });

        ok( !( $letter_1 == $letter_2 ), 'Correctly unequal' );
    };
};

done_testing;
