#!perl -T

use strict;
use warnings;

use Git::Repository::Plugin::Blame::Cache;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 6;


can_ok(
	'Git::Repository::Plugin::Blame::Cache',
	'get_blame_lines',
);

ok(
	defined(
		my $cache = Git::Repository::Plugin::Blame::Cache->new(
			repository => '/tmp/test',
		)
	),
	'Instantiated Git::Repository::Plugin::Blame::Cache object.',
);

my $test_file = 'test';
my $test_blame_lines =
[
	'test',
];

lives_ok(
	sub
	{
		$cache->set_blame_lines(
			file        => $test_file,
			blame_lines => $test_blame_lines,
		);
	},
	'Store blame lines.',
);

throws_ok(
	sub
	{
		$cache->get_blame_lines();
	},
	qr/\QThe "file" argument is mandatory\E/,
	'The "file" argument is mandatory',
);

my $retrieved_blame_lines;
lives_ok(
	sub
	{
		$retrieved_blame_lines = $cache->get_blame_lines(
			file => $test_file,
		);
	},
	'Retrieved cached blame lines.',
);

is_deeply(
	$retrieved_blame_lines,
	$test_blame_lines,
	'The cached blame lines match what was set in the cache.',
);
