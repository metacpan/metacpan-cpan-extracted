#!perl -T

# Test the common fuction. Anthony Fletcher

use 5;
use warnings;
use strict;
use Data::Dumper;

use Test::More tests => 4;

$| = 1;

# Tests
BEGIN { use_ok('File::Store'); }

# Test the routine.
my $obj;

ok($obj = new File::Store(), "constructor");
my $n = $obj->get('missing');
ok(!$n, "open new file");
is($obj->count(), 0, "store count correct " . __LINE__ );

#print Dumper $obj;

