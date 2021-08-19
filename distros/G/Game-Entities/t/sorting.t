#!/usr/bin/env perl

use Test::More;
use Game::Entities;
use List::Util 'shuffle';

# A pseudo-component
my $new = sub { bless \( my $x = $_[1] ), $_[0] };

subtest Comparator => sub {
    my $R = Game::Entities->new;

    srand 1234;
    my @shuffled = shuffle 1 .. 30;;

    for ( 0 .. $#shuffled ) {
        my $guid = $R->create;
        $R->add( $guid => A->$new( $shuffled[$_] ) );
        $R->add( $guid => B->$new( $shuffled[$_] ) ) unless $_ % 2;
        $R->add( $guid => C->$new( $shuffled[$_] ) ) unless $_ % 3;
    };

    # Sort B numerically
    $R->sort( B => sub { $$a <=> $$b } );

    $R->sort( A => 'B' ); # Sort A according to B
    $R->sort( C => 'B' ); # Sort C according to B

    is_deeply [ map ${ $_->[0] }, $R->view('A')->components ] => [
        2,
        3,
        5,
        6,
        7,
        8,
        9,
        11,
        12,
        15,
        16,
        18,
        21,
        28,
        29,
        4,
        17,
        19,
        20,
        27,
        22,
        13,
        30,
        1,
        14,
        26,
        25,
        10,
        24,
        23
    ] => 'Sorted component pool with subset';

    is_deeply [ map ${ $_->[0] }, $R->view('B')->components ] => [
        2,
        3,
        5,
        6,
        7,
        8,
        9,
        11,
        12,
        15,
        16,
        18,
        21,
        28,
        29
    ] => 'Sorted component pool numerically';

    is_deeply [ map ${ $_->[0] }, $R->view('C')->components ] => [
        5,
        8,
        16,
        28,
        29,
        4,
        17,
        13,
        22,
        10
    ] => 'Sorted component pool with superset';
};

subtest Prototype => sub {
    my $R = Game::Entities->new;

    srand 1234;
    my @shuffled = shuffle 1 .. 30;;

    for ( 0 .. $#shuffled ) {
        my $guid = $R->create;
        $R->add( $guid => A->$new( $shuffled[$_] ) );
        $R->add( $guid => B->$new( $shuffled[$_] ) ) unless $_ % 2;
        $R->add( $guid => C->$new( $shuffled[$_] ) ) unless $_ % 3;
    };

    # Sort B numerically
    $R->sort( B => sub ($$) { ${ $_[0] } <=> ${ $_[1] } } );

    $R->sort( A => 'B' ); # Sort A according to B
    $R->sort( C => 'B' ); # Sort C according to B

    is_deeply [ map ${ $_->[0] }, $R->view('A')->components ] => [
        2,
        3,
        5,
        6,
        7,
        8,
        9,
        11,
        12,
        15,
        16,
        18,
        21,
        28,
        29,
        4,
        17,
        19,
        20,
        27,
        22,
        13,
        30,
        1,
        14,
        26,
        25,
        10,
        24,
        23
    ] => 'Sorted component pool with subset';

    is_deeply [ map ${ $_->[0] }, $R->view('B')->components ] => [
        2,
        3,
        5,
        6,
        7,
        8,
        9,
        11,
        12,
        15,
        16,
        18,
        21,
        28,
        29
    ] => 'Sorted component pool numerically';

    is_deeply [ map ${ $_->[0] }, $R->view('C')->components ] => [
        5,
        8,
        16,
        28,
        29,
        4,
        17,
        13,
        22,
        10
    ] => 'Sorted component pool with superset';
};

done_testing;
