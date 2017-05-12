#!perl -T

use Test::More tests => 5;

BEGIN {
    use_ok( 'Hypatia' ) || print "Bail out!\n";
    use_ok('Hypatia::Base') || print "Bail out!\n";
    use_ok( 'Hypatia::DBI' ) || print "Bail out!\n";
    use_ok( 'Hypatia::Columns' ) || print "Bail out!\n";
    use_ok( 'Hypatia::DBI::Test::SQLite' ) or print "Bail out!\n";
}

diag( "Testing Hypatia $Hypatia::VERSION, Perl $], $^X" );