#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);

use_ok('Games::YASudoku::Board');


{
    my $square = Games::YASudoku::Board->new();
    isa_ok( $square, 'Games::YASudoku::Board', 'Correct object created');
}



{
    # add and remove nubmers from the set of valid numbers 
    my $board = Games::YASudoku::Board->new();

    is( @{$board}, 81, 'make sure board has correct number of squares');

    my $row = $board->get_row( 2 );
    is( @{$row}, 9, 'make sure there are nine elements in a row');

    my $rows = $board->get_rows;
    is( @{$rows}, 9, 'make sure there are nine rows');

    my $col = $board->get_col( 2 );
    is( @{$col}, 9, 'make sure there are nine elements in a column');

    my $cols = $board->get_cols;
    is( @{$cols}, 9, 'make sure there are nine columns');

    my $grp = $board->get_grp( 2 );
    is( @{$grp}, 9, 'make sure there are nine elements in a group');
    
    my $grps = $board->get_grps;
    is( @{$grps}, 9, 'make sure there are nine groups');

}


{
    # test get_element_membership
    my $board = Games::YASudoku::Board->new();
    my $element = $board->[ 73 ];

    my $memberships = $board->get_element_membership( $element );
    is( @{$memberships}, 3, 'An element is a member of three groups');

    # now check that we got the right elements
}

{

    my $board = Games::YASudoku::Board->new();
    $board->[2]->value( 3 );
    $board->[3]->value( 7 );
    $board->[8]->value( 8 );
    $board->[12]->value( 2 );
    $board->[13]->value( 4 );
    $board->[15]->value( 9 );
    $board->[17]->value( 1 );
    $board->[22]->value( 6 );
    $board->[29]->value( 8 );
    $board->[30]->value( 4 );
    $board->[37]->value( 1 );
    $board->[38]->value( 5 );
    $board->[42]->value( 3 );
    $board->[43]->value( 8 );
    $board->[50]->value( 7 );
    $board->[51]->value( 4 );
    $board->[58]->value( 5 );
    $board->[63]->value( 9 );
    $board->[65]->value( 7 );
    $board->[67]->value( 8 );
    $board->[68]->value( 6 );
    $board->[72]->value( 6 );
    $board->[77]->value( 2 );
    $board->[78]->value( 1 );

    warn "Starting Board";
    warn $board->show_board;

    foreach my $element ( @{ $board } ){
        for my $i ( 1 .. 9 ) {
            $element->valid_add( $i );
	}
    }

    my $passes = $board->run_board;

    warn "Solved in $passes passes";
    warn $board->show_board;
}
