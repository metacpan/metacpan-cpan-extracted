use Test::More tests => 1;

BEGIN {
    use_ok( 'Disk::SMART' ) || print "Bail out!\n";
}

diag( "Testing Disk::SMART $Disk::SMART::VERSION, Perl $], $^X" );
