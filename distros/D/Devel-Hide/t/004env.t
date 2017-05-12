
use strict;
use Test::More tests => 5;

use_ok('lib', 't');

# this script tests Devel::Hide respects environment variable DEVEL_HIDE_PM 

$ENV{DEVEL_HIDE_PM} = 'Q.pm R';
use_ok('Devel::Hide');

eval { require P }; 
ok(!$@, "P was loaded (as it should)");

eval { require Q }; 
like($@, qr/^Can't locate Q\.pm/, "Q not found (as it should)");

eval { require R }; 
like($@, qr/^Can't locate R\.pm/, "R not found (as it should)");
