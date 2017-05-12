#!perl -T

use strict;
use warnings;

use Git::Repository::Plugin::Blame::Line;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 3;


my $commit_id = '7df7d2b1a4a0603b4ab51ccd44323c77d2551a7d';
my $blame_line;
lives_ok(
	sub
	{
		$blame_line = Git::Repository::Plugin::Blame::Line->new(
			line_number       => 10,
			line              => 'Test code',
			commit_attributes => {},
			commit_id         => $commit_id,
		);
	},
	'Create a Git::Repository::Plugin::Blame::Line object.',
);

can_ok(
	$blame_line,
	'get_commit_id',
);

is(
	$blame_line->get_commit_id(),
	$commit_id,
	'The retrieved commit ID matches what was set with new().'
);
