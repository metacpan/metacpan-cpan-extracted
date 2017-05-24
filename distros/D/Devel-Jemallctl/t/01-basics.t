#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;
use Devel::Jemallctl;

plan tests => 1;

my $stats= Devel::Jemallctl::refresh_and_get_stats;
my @expected= qw/
    stats.allocated
    stats.active
    stats.metadata
    stats.resident
    stats.retained
    stats.mapped
    stats.cactive
/;
my $ok= 1; $ok &&= exists $stats->{$_} for @expected;
ok($ok);
