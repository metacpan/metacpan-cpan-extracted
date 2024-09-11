#! perl

use strict;
use warnings;

use File::Temp 'tempdir';
use Test::More 0.89;
use lib 't/lib';
use Test::LivesOK 'lives_ok';

use ExtUtils::Builder::Node;
use ExtUtils::Builder::Plan;
use ExtUtils::Builder::Action::Code;

our @triggered;
{
local @triggered;
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

lives_ok { $plan->run('foo', quiet => 1) } 'Executing gave no errors';

is_deeply(\@triggered, [ 0..2 ], 'All actions triggered');

my @order = qw/foo2 foo1 foo0/;
is_deeply([ $plan->node_names ], [ sort keys %nodes, $root->target ], 'Got expected nodes');

}

{
local @triggered;

my $dir = tempdir(TMPDIR => 1, CLEANUP => 1);

chdir $dir;

my %nodes = map {
	+"foo$_" => ExtUtils::Builder::Node->new(
		target => "foo$_",
		dependencies => [],
		actions => [ ExtUtils::Builder::Action::Code->new(code => "open my \$fh, '>', 'foo$_'" ) ],
	)
} 0 .. 2;

my $root = ExtUtils::Builder::Node->new(target => "foo", dependencies => [ map { "foo$_" } 0..2 ], actions => [
	ExtUtils::Builder::Action::Code->new(code => "open my \$fh, '>', 'foo'; push \@::triggered, 'foo'" ),
]);
my $plan;
lives_ok { $plan = ExtUtils::Builder::Plan->new(nodes => { %nodes, foo => $root }) } 'Plan could be created';
lives_ok { $plan->run('foo', quiet => 1) } 'Executing gave no errors';
is_deeply(\@triggered, [ 'foo' ], 'Have one foo');

lives_ok { $plan->run('foo', quiet => 1) } 'Executing gave no errors';
is_deeply(\@triggered, [ 'foo' ], 'Have one foo');

my $now = time;
utime $now, $now + 120, 'foo2';

lives_ok { $plan->run('foo', quiet => 1) } 'Executing gave no errors';
is_deeply(\@triggered, [ 'foo', 'foo' ], 'Have two foos');

}

done_testing;
