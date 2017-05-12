#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::CleanupTask' ) || print "Bail out!\n";
}

diag( "Testing File::CleanupTask $File::CleanupTask::VERSION, Perl $], $^X" );
