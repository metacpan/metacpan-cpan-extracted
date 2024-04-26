#! perl

use strict;
use warnings;

use Test::More 0.89;
use lib 't/lib';
use Test::LivesOK 'lives_ok';

use ExtUtils::Builder::Node;
use ExtUtils::Builder::Plan;
use ExtUtils::Builder::Action::Code;

our @triggered;
my @nodes = map {
	[
	+"foo$_" => ExtUtils::Builder::Node->new(
		target => "foo$_",
		dependencies => [],
		actions => [ ExtUtils::Builder::Action::Code->new(code => "push \@::triggered, $_" ) ],
	)
	]
} 0 .. 2;
my %nodes = map { @$_ } @nodes;

my $root = ExtUtils::Builder::Node->new(target => "foo", dependencies => [ map { "foo$_" } 0..2 ], actions => []);
my $plan;
lives_ok { $plan = ExtUtils::Builder::Plan->new(nodes => { %nodes, foo => $root }) } 'Plan could be created';

lives_ok { $plan->run('foo') } 'Executing gave no errors';

is_deeply(\@triggered, [ 0..2 ], 'All actions triggered');

my @order = qw/foo2 foo1 foo0/;
is_deeply([ $plan->node_names ], [ sort keys %nodes, $root->target ], 'Got expected nodes');

done_testing;


