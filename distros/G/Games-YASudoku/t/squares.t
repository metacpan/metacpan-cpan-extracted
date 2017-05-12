#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);

use_ok('Games::YASudoku::Square');


{
    my $square = Games::YASudoku::Square->new();
    
    is( $square->value, undef, 'Square init: value undef');
    is_deeply( $square->valid, [], 'Square init: valid returns an array ref');
}



{
    # add and remove nubmers from the set of valid numbers 
    my $square = Games::YASudoku::Square->new();

    # test adding numbers
    $square->valid_add(1);
    is_deeply( $square->valid, [1], 'Add number to valid set' );

    $square->valid_add(3);
    is_deeply( $square->valid, [1,3], 'Add number to valid set' );
    
    $square->valid_add(2);
    is_deeply( $square->valid, [1,2,3], 'Add number to valid set' );
    
    $square->valid_add(3);
    is_deeply( $square->valid, [1,2,3], 'Add a duplicate number to valid set' );

    # test removing numbers
    $square->valid_del(2);
    is_deeply( $square->valid, [1,3], 'Del number from valid set' );
    
    $square->valid_del(3);
    is_deeply( $square->valid, [1], 'Del number from valid set' );
    
    $square->valid_del(3);
    is_deeply( $square->valid, [1], 'Del number that does not exist in valid set' );
    
}

{
    # test the value of the square
    my $square = Games::YASudoku::Square->new();
    
    $square->value(2);
    is ( $square->value, 2, 'Set the value for the square');
    
    $square->value(4);
    is ( $square->value, 4, 'Set the value for the square to a new value');
}
