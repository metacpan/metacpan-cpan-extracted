#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'FileCache::Appender' ) || print "Bail out!\n";
}

diag( "Testing FileCache::Appender $FileCache::Appender::VERSION, Perl $], $^X" );
