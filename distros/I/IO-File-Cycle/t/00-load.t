#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IO::File::Cycle' ) || print "Bail out!\n";
}

diag( "Testing IO::File::Cycle $IO::File::Cycle::VERSION, Perl $], $^X" );
