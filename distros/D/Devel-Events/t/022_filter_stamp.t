# vim: set ts=2 sw=2 noet nolist :
use strict;
use warnings;

use Test::More 0.88;


my $m; use ok $m = "Devel::Events::Filter::Stamp";

my $time = time;
my %data = Devel::Events::Filter::Stamp::stamp_data();

is_deeply( [ sort keys %data ], [ sort qw/id time pid/ ], "keys" );

is( $data{id}, 1, "first ID" );

is( $data{pid}, $$, "pid" );

cmp_ok( $time - $data{time}, "<=", 2, "time is within range" );

%data = Devel::Events::Filter::Stamp::stamp_data();

is( $data{id}, 2, "ID incremented" );

# TODO
# test threads

done_testing;
