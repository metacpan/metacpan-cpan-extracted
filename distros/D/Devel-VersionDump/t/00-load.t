#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Devel::VersionDump' ) || print "Bail out!
";
}

diag( "Testing Devel::VersionDump $Devel::VersionDump::VERSION, Perl $], $^X" );
