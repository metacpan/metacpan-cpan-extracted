#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IBM::StorageSystem' ) || print "Bail out!\n";
}

diag( "Testing IBM::StorageSystem $IBM::StorageSystem::VERSION, Perl $], $^X" );
