#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Speller;

use Readonly;
Readonly my $VALID_WORD   => 'nerd';
Readonly my $INVALID_WORD => 'klsdjfseir';

subtest 'Spellcheck Valid Word' => sub {
    my $speller = Game::WordBrain::Speller->new();

    my $is_valid_word;
    lives_ok {
        $is_valid_word = $speller->is_valid_word( $VALID_WORD );
    } 'Lives through spellchecking word';


    ok( $is_valid_word, 'Correctly identifies valid word' );
};

subtest 'Spellcheck Invalid Word' => sub {
    my $speller = Game::WordBrain::Speller->new();

    my $is_valid_word;
    lives_ok {
        $is_valid_word = $speller->is_valid_word( $INVALID_WORD );
    } 'Lives through spellchecking word';


    ok( !$is_valid_word, 'Correctly identifies invalid word' );
};

done_testing;
