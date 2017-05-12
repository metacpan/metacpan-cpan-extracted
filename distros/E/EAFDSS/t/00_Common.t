use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
	use_ok('EAFDSS'); 
}

my(@drivers) = EAFDSS->available_drivers();
ok(@drivers,  "Found drivers");
