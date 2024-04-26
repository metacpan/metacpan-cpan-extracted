#!perl

use strict;
use warnings;

use Test::More 0.89;
use lib 't/lib';
use Test::LivesOK 'lives_ok';

use ExtUtils::Builder::Planner;

my $planner = ExtUtils::Builder::Planner->new;
$planner->load_module("Callback");

our @triggered;

$planner->add_foo($_) for 0..2;

$planner->create_node(
	target => 'foo',
	dependencies => [ map { "foo$_" } 0..2 ],
	phony => 1,
);

my $plan = $planner->materialize;

lives_ok { $plan->run('foo') } 'Executing gave no errors';

is_deeply(\@triggered, [ 0..2 ], 'All actions triggered');

my %nodes;
my @order = qw/foo2 foo1 foo0/;
is_deeply([ $plan->node_names ], [ qw/foo foo0 foo1 foo2/ ], 'Got expected nodes');

done_testing;

