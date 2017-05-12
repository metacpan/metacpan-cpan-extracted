#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Job::Manager' ) || print "Bail out!
";
    use_ok( 'Job::Manager::Job' ) || print "Bail out!
";
    use_ok( 'Job::Manager::Worker' ) || print "Bail out!
";
}

diag( "Testing Job::Manager $Job::Manager::VERSION, Perl $], $^X" );
