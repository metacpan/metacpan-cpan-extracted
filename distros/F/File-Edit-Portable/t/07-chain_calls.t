#!perl
use 5.006;
use strict;
use warnings;

use Test::More;

use_ok( 'File::Edit::Portable' ) || print "Bail out!\n";

my @data = File::Edit::Portable->new->read('t/base/unix.txt');
is (ref \@data, 'ARRAY', "chained calls through new return array");

done_testing();
