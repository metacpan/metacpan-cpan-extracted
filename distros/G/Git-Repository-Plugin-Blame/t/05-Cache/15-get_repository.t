#!perl -T

use strict;
use warnings;

use Git::Repository::Plugin::Blame::Cache;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 3;


can_ok(
	'Git::Repository::Plugin::Blame::Cache',
	'get_repository',
);

my $TEST_REPOSITORY = 'test_repository';

ok(
	my $cache = Git::Repository::Plugin::Blame::Cache->new(
		repository => $TEST_REPOSITORY,
	),
	'Instantiate a new cache object.',
);

is(
	$cache->get_repository(),
	$TEST_REPOSITORY,
	'get_repository() returns the correct value.',
);
