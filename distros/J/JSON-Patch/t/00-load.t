#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'JSON::Patch' ) || print "Bail out!\n";
}

diag( "Testing JSON::Patch $JSON::Patch::VERSION, Perl $], $^X" );
