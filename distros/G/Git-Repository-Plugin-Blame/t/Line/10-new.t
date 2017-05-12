#!perl -T

use strict;
use warnings;

use Git::Repository::Plugin::Blame::Line;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 8;


my $new_blame_line;
lives_ok(
	sub
	{
		$new_blame_line = Git::Repository::Plugin::Blame::Line->new(
			line_number       => 10,
			line              => 'Test code',
			commit_attributes => {},
			commit_id         => '7df7d2b1a4a0603b4ab51ccd44323c77d2551a7d',
		);
	},
	'Create a Git::Repository::Plugin::Blame::Line object.',
);

isa_ok(
	$new_blame_line,
	'Git::Repository::Plugin::Blame::Line',
	'Object',
);

dies_ok(
	sub
	{
		my $blame_line = Git::Repository::Plugin::Blame::Line->new(
			line              => 'Test code',
			commit_attributes => {},
			commit_id         => '7df7d2b1a4a0603b4ab51ccd44323c77d2551a7d',
		);
	},
	'"line_number" is a mandatory argument.',
);

dies_ok(
	sub
	{
		my $blame_line = Git::Repository::Plugin::Blame::Line->new(
			line_number       => 'A',
			line              => 'Test code',
			commit_attributes => {},
			commit_id         => '7df7d2b1a4a0603b4ab51ccd44323c77d2551a7d',
		);
	},
	'"line_number" must be an integer.',
);

dies_ok(
	sub
	{
		my $blame_line = Git::Repository::Plugin::Blame::Line->new(
			line_number       => 10,
			commit_attributes => {},
			commit_id         => '7df7d2b1a4a0603b4ab51ccd44323c77d2551a7d',
		);
	},
	'"line" is a mandatory argument.',
);

lives_ok(
	sub
	{
		my $blame_line = Git::Repository::Plugin::Blame::Line->new(
			line_number       => 10,
			line              => '',
			commit_attributes => {},
			commit_id         => '7df7d2b1a4a0603b4ab51ccd44323c77d2551a7d',
		);
	},
	'"line" can be empty.',
);

dies_ok(
	sub
	{
		my $blame_line = Git::Repository::Plugin::Blame::Line->new(
			line_number       => 10,
			line              => 'Test code',
			commit_id         => '7df7d2b1a4a0603b4ab51ccd44323c77d2551a7d',
		);
	},
	'"commit_attributes" is a mandatory argument.',
);

dies_ok(
	sub
	{
		my $blame_line = Git::Repository::Plugin::Blame::Line->new(
			line_number       => 10,
			line              => 'Test code',
			commit_attributes => {},
		);
	},
	'"commit_id" is a mandatory argument.',
);
