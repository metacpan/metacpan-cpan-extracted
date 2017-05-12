#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Prefix;

my $prefix = Game::WordBrain::Prefix->new;

subtest 'Not a real word' => sub {
    my $is_start_of_word;

    lives_ok {
        $is_start_of_word = $prefix->is_start_of_word( 'dddd' );
    } 'Lives through is_start_of_word';

    ok( !$is_start_of_word, 'Correctly not the start of a word' );
};

subtest 'Word <  prefix' => sub {
    my $is_start_of_word;

    lives_ok {
        $is_start_of_word = $prefix->is_start_of_word( 'ap' );
    } 'Lives through is_start_of_word';

    ok( $is_start_of_word, 'Correctly the start of a word' );
};

subtest 'Word == prefix' => sub {
    my $is_start_of_word;

    lives_ok {
        $is_start_of_word = $prefix->is_start_of_word( 'appl' );
    } 'Lives through is_start_of_word';

    ok( $is_start_of_word, 'Correctly the start of a word' );
};

subtest 'Word >  prefix' => sub {
    my $is_start_of_word;

    lives_ok {
        $is_start_of_word = $prefix->is_start_of_word( 'apple' );
    } 'Lives through is_start_of_word';

    ok( $is_start_of_word, 'Correctly the start of a word' );
};

done_testing;
