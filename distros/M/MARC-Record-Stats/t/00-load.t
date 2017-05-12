use Test::Most tests => 1;

BEGIN {
    use_ok( 'MARC::Record::Stats' ) || print "Bail out!";
}

diag( "Testing MARC::Record::Stats $MARC::Record::Stats::VERSION, Perl $], $^X" );
