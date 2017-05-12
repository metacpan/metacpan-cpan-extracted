use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More; 

BEGIN {
    use_ok( 'JQuery::DataTables::Request' ) || print "Bail out!\n";
}

diag( "Testing JQuery::DataTables::Request $JQuery::DataTables::Request::VERSION, Perl $], $^X" );

done_testing;
