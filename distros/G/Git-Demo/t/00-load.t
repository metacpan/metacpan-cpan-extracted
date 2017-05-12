#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Git::Demo' ) || print "Bail out!
";
}

diag( "Testing Git::Demo $Git::Demo::VERSION, Perl $], $^X" );
