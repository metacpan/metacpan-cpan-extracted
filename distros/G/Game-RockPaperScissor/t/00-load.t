#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;

use Game::RockPaperScissor;


BEGIN {
    use_ok( 'Game::RockPaperScissor' ) || print "Bail out!\n";
}

diag( "Testing Game::RockPaperScissor $Game::RockPaperScissor::VERSION, Perl $], $^X" );

my $rps = Game::RockPaperScissor->new();
{
    my $game = {
        p1 => 'rock',
        p2 => 'scissor',
    };
    is( 1, $rps->get_result( $game ), "Win" );

}
{
    my $game2 = {
        p1 => 'rock',
        p2 => 'papaer',
    };
    is( -1, $rps->get_result( $game2 ), "Loose" );
}

{
    my $game3 = {
        p1 => 'scissor',
        p2 => 'scissor',
    };
    is( 0, $rps->get_result( $game3 ), "Tie" );
}

done_testing();