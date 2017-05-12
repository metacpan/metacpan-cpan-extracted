#!perl -T

use strict;
use warnings;

use Git::Repository::Plugin::Blame::Line;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 3;


my $line_number = 10;
my $blame_line;
lives_ok(
	sub
	{
		$blame_line = Git::Repository::Plugin::Blame::Line->new(
			line_number       => $line_number,
			line              => 'Test code',
			commit_attributes => {},
			commit_id         => '7df7d2b1a4a0603b4ab51ccd44323c77d2551a7d',
		);
	},
	'Create a Git::Repository::Plugin::Blame::Line object.',
);

can_ok(
	$blame_line,
	'get_line_number',
);

is(
	$blame_line->get_line_number(),
	$line_number,
	'The retrieved line number matches what was set with new().'
);
