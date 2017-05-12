#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'HTML::DataTable', 'loading HTML::DataTable' ) || print "Bail out!\n";
}

BEGIN {
    use_ok( 'HTML::DataTable::DBI', 'loading HTML::DataTable::DBI' ) || print "Bail out!\n";
}