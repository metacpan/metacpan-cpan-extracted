#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Git::Glog' ) || print "Bail out!\n";
}

diag( "Testing Git::Glog $Git::Glog::VERSION, Perl $], $^X" );
