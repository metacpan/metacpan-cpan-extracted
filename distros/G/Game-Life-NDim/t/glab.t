#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More tests => 5 + 11 + 1;
use Test::NoWarnings;
use Test::Warn;

use Game::Life::NDim::Board;

my $board = Game::Life::NDim::Board->new( dims => Game::Life::NDim::Dim->new([1,1]) );

stringify();
looping();
surround();
get_life();
diag "end";

sub looping {
    diag 'looping';
    my $count = 0;
    $board->reset;

    $count++ while (ref $board->next_life);

    is($count, 4, "2 x 2 board has 4 lives");
}

sub stringify {
    diag 'stringify';
    is("$board", "0 0\n0 0\n", "Stringify");
}

sub surround {
    diag 'surround';
    my $board = Game::Life::NDim::Board->new( dims => Game::Life::NDim::Dim->new([9]) );
    my $life  = $board->get_life([5]);
    is((scalar @{ $life->surround }), 2, "1D is surrounded by 2 cells");

    $board = Game::Life::NDim::Board->new( dims => Game::Life::NDim::Dim->new([9, 9]) );
    $life  = $board->get_life([5, 5]);
    is((scalar @{ $life->surround }), 8, "2D is surrounded by 8 cells");

    $board = Game::Life::NDim::Board->new( dims => Game::Life::NDim::Dim->new([9, 9, 9]) );
    $life  = $board->get_life([5, 5, 5]);
    is((scalar @{ $life->surround }), 26, "3D is surrounded by 26 cells");

    # general formula surrounding cells = n^3 - 1
}

sub get_life {
    diag 'get_life';
    my $board = Game::Life::NDim::Board->new( dims => Game::Life::NDim::Dim->new([9,9]) );

    is_deeply($board->get_life([0,0]), $board->items->[0][0], '');
    is_deeply($board->get_life([0,1]), $board->items->[0][0], '');
    is_deeply($board->get_life([0,2]), $board->items->[0][0], '');
    is_deeply($board->get_life([1,0]), $board->items->[0][0], '');
    is_deeply($board->get_life([1,1]), $board->items->[0][0], '');
    is_deeply($board->get_life([1,2]), $board->items->[0][0], '');
    is_deeply($board->get_life([2,0]), $board->items->[0][0], '');
    is_deeply($board->get_life([2,1]), $board->items->[0][0], '');
    is_deeply($board->get_life([2,2]), $board->items->[0][0], '');

    $board->wrap(0);
    #warning_like {eval{ $board->get_life([0, -1]) }} qr/^Cannot get game position from/, 'wrap request should fail with error';
    eval{ $board->get_life([0, -1]) };
    ok($@, "Get an error when not in wrap mode and using a wrap position");
    $board->wrap(1);
    is_deeply($board->get_life([0,-1]), $board->items->[0][-1], 'Wrap mode on gets wraped cell');

}
