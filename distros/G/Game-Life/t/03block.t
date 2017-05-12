#!/usr/bin/perl -w

#=============================================================================
#
# $Id: 03block.t,v 0.04 2001/07/04 02:49:35 mneylon Exp $
# $Revision: 0.04 $
# $Author: mneylon $
# $Date: 2001/07/04 02:49:35 $
# $Log: 03block.t,v $
# Revision 0.04  2001/07/04 02:49:35  mneylon
#
# Fixed distribution problem
#
# Revision 0.03  2001/07/04 02:28:10  mneylon
#
# Updated README for distribution
#
# Revision 0.02  2001/07/04 02:24:58  mneylon
#
# Test cases for Game::Life
#
#
#=============================================================================

use strict;
use Game::Life;

require 't/compare-boards.pl';

print "1..2\n";

my @starting = qw(
		  ....
		  .XX.
		  .XX.
		  .... );

my $game = Game::Life->new( 4 );
$game->place_text_points( 0, 0, 'X', @starting );
$game->process( 10 );
my @real_end = $game->get_text_grid( 'X', '.' );
print compare_boards( \@starting, \@real_end ) ? "ok 1\n" : "not ok 1\n";

@starting = qw(
		  ......
		  .XX...
		  .XX...
		  ...... );

$game = Game::Life->new( [6,4] );
$game->place_text_points( 0, 0, 'X', @starting );
$game->process( 10 );
@real_end = $game->get_text_grid( 'X', '.' );
print compare_boards( \@starting, \@real_end ) ? "ok 2\n" : "not ok 2\n";
