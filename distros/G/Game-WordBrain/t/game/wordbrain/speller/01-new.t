#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Speller;

use Cwd qw( abs_path );
use Readonly;
Readonly my $MY_ABS_PATH      => abs_path( __FILE__ );
Readonly my $PATH_TO_WORDLIST => substr( $MY_ABS_PATH, 0, length( $MY_ABS_PATH ) - length( '/t/game/wordbrain/speller/01-new.t')) . '/words.txt';


subtest 'Construct Speller With No Args' => sub {
    my $speller;
    lives_ok {
        $speller = Game::WordBrain::Speller->new();
    } 'Lives through creation of speller';

    isa_ok( $speller, 'Game::WordBrain::Speller' );
    cmp_ok( $speller->{word_list}, 'eq', 'Game::WordBrain::WordList', 'Correct word_list' );
    cmp_ok( $speller->{_words_cache}{nerd}, '==', 1, 'Something populated the _words_cache' );
};

subtest 'Construct Speller with word_list specified' => sub {
    my $speller;
    lives_ok {
        $speller = Game::WordBrain::Speller->new({
            word_list => $PATH_TO_WORDLIST,
        });
    } 'Lives through creation of speller';

    isa_ok( $speller, 'Game::WordBrain::Speller' );
    cmp_ok( $speller->{word_list}, 'eq', $PATH_TO_WORDLIST, 'Correct word_list' );
    cmp_ok( $speller->{_words_cache}{nerd}, '==', 1, 'Something populated the _words_cache' );

};

done_testing;
