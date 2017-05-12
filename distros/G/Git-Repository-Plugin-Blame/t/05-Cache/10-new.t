#!perl -T

use strict;
use warnings;

use Git::Repository::Plugin::Blame::Cache;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;


can_ok(
	'Git::Repository::Plugin::Blame::Cache',
	'new',
);

throws_ok(
	sub
	{
		Git::Repository::Plugin::Blame::Cache->new(
			repository => undef,
		),
	},
	qr/\QThe "repository" argument is mandatory\E/,
	'The argument "repository" is mandatory.',
);

my $cache;
lives_ok(
	sub
	{
		$cache = Git::Repository::Plugin::Blame::Cache->new(
			repository => '/tmp/test/',
		),
	},
	'Instantiate a new object.',
);

my $cache2;
lives_ok(
	sub
	{
		$cache2 = Git::Repository::Plugin::Blame::Cache->new(
			repository => '/tmp/test2/',
		),
	},
	'Instantiate a new object for a different repository.',
);

isnt(
	Scalar::Util::refaddr( $cache ),
	Scalar::Util::refaddr( $cache2 ),
	'The cache is not shared across repositories.',
);
