#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Feed::Pipe' );
}

diag( "Testing Feed::Pipe $Feed::Pipe::VERSION, Perl $], $^X" );
