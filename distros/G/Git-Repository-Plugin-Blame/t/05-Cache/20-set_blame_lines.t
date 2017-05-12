#!perl -T

use strict;
use warnings;

use Git::Repository::Plugin::Blame::Cache;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 6;


can_ok(
	'Git::Repository::Plugin::Blame::Cache',
	'set_blame_lines',
);

ok(
	defined(
		my $cache = Git::Repository::Plugin::Blame::Cache->new(
			repository => '/tmp/test',
		)
	),
	'Instantiated Git::Repository::Plugin::Blame::Cache object.',
);

throws_ok(
	sub
	{
		$cache->set_blame_lines(
			blame_lines => [],
		);
	},
	qr/\QThe "file" argument is mandatory\E/,
	'The argument "file" is required.',
);

throws_ok(
	sub
	{
		$cache->set_blame_lines(
			file => 'test',
		);
	},
	qr/\QThe "blame_lines" argument is mandatory\E/,
	'The argument "blame_lines" is required.',
);

throws_ok(
	sub
	{
		$cache->set_blame_lines(
			file        => 'test',
			blame_lines => '',
		);
	},
	qr/\QThe "blame_lines" argument must be an arrayref\E/,
	'The argument "blame_lines" must be an arrayref.',
);

lives_ok(
	sub
	{
		$cache->set_blame_lines(
			file        => 'test',
			blame_lines => [],
		);
	},
	'Store blame lines.',
);
