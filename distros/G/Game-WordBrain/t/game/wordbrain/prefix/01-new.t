#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Prefix;

use Cwd qw( abs_path );
use Readonly;
Readonly my $MY_ABS_PATH      => abs_path( __FILE__ );
Readonly my $PATH_TO_WORDLIST => substr( $MY_ABS_PATH, 0, length( $MY_ABS_PATH ) - length( '/t/game/wordbrain/prefix/01-new.t')) . '/words.txt';

subtest "Construct Prefix With No Args" => sub {
    my $prefix;
    lives_ok {
        $prefix = Game::WordBrain::Prefix->new();
    } 'Lives through creation of Prefix';

    isa_ok( $prefix, 'Game::WordBrain::Prefix' );
    cmp_ok( $prefix->{max_prefix_length},  '==', 8, 'Correct default max_prefix_length' );
    cmp_ok( $prefix->{word_list},          'eq', 'Game::WordBrain::WordList', 'Correct word_list' );
    cmp_ok( $prefix->{_prefix_cache}{fro}, '==', 1, 'Something populated the _prefix_cache' );
};

subtest 'Construct Prefix With max_prefix_length and word_list specified' => sub {
    my $max_prefix_length = 4;

    note( "Path to Word List: $PATH_TO_WORDLIST" );

    my $prefix;
    lives_ok {
        $prefix = Game::WordBrain::Prefix->new({
            max_prefix_length => $max_prefix_length,
            word_list         => $PATH_TO_WORDLIST,
        });
    } 'Lives through creation of Prefix';

    isa_ok( $prefix, 'Game::WordBrain::Prefix' );
    cmp_ok( $prefix->{max_prefix_length},  '==', $max_prefix_length, 'Correct max_prefix_length' );
    cmp_ok( $prefix->{word_list},          'eq', $PATH_TO_WORDLIST, 'Correct word_list' );
    cmp_ok( $prefix->{_prefix_cache}{fro}, '==', 1, 'Something populated the _prefix_cache' );
};

done_testing;
