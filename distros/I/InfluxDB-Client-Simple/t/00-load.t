#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'InfluxDB::Client::Simple' ) || print "Bail out!\n";
}

diag( "Testing InfluxDB::Client::Simple $InfluxDB::Client::Simple::VERSION, Perl $], $^X" );
