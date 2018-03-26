#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use lib 'lib/';
use lib 't/lib/';
use lib '../lib/';

plan tests => 1;

BEGIN {
    use_ok( 'Druid' ) || print "Bail out!\n";
}

diag( "Testing Druid $Druid::VERSION, Perl $], $^X" );
