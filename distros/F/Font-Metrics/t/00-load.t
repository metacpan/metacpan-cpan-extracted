#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

use lib 'blib/lib', 'blib/arch';

plan tests => 1;

BEGIN {
    use_ok( 'Font::Metrics' ) || print "Bail out!\n";
}
