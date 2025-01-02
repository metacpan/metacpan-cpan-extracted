#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Game::Floppy' ) || print "Bail out!\n";
}

diag( "Testing Game::Floppy $Game::Floppy::VERSION, Perl $], $^X" );
