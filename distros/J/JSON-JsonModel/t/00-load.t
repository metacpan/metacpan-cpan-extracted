#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'JSON::JsonModel' ) || print "Bail out!\n";
}

diag( "Testing JSON::JsonModel $JSON::JsonModel::VERSION, Perl $], $^X" );
