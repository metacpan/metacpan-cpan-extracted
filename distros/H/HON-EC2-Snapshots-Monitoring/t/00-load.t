#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'HON::EC2::Snapshots::Monitoring' ) || print "Bail out!\n";
}

diag( "Testing HON::EC2::Snapshots::Monitoring $HON::EC2::Snapshots::Monitoring::VERSION, Perl $], $^X" );
