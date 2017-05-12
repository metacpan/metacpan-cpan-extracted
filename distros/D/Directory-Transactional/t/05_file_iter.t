#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::TempDir qw(scratch);

use ok 'Directory::Transactional::Stream';
use ok 'Directory::Transactional';

my $s = scratch();

$s->create_tree({
	# new state:
	'root/foo.txt'        => "les foo",
	'root/bar.txt'        => "the bar",
	'root/blah/gorch.txt' => "los gorch",
});

my $base = $s->base;

my $m = Directory::Transactional->new(
	root => $base->subdir("root"),
);

foreach my $depth ( 0, 1 ) {
	{
		my $paths = $m->file_stream(
			chunk_size => 2,
			depth_first => $depth,
		);

		ok( !$paths->is_done, "not done" );

		my @all = $paths->all;

		ok( $paths->is_done, "done" );

		is_deeply(
			[ sort @all ],
			[ sort 'foo.txt', 'bar.txt', 'blah', 'blah/gorch.txt' ],
			"breadth first traversal path set",
		);
	}

	{
		my $paths = $m->file_stream(
			chunk_size => 2,
			depth_first => $depth,
			only_files => 1,
		);

		ok( !$paths->is_done, "not done" );

		my @all = $paths->all;

		ok( $paths->is_done, "done" );

		is_deeply(
			[ sort @all ],
			[ sort 'foo.txt', 'bar.txt', 'blah/gorch.txt' ],
			"breadth first traversal path set",
		);
	}

	{
		my $paths = $m->file_stream(
			chunk_size => 2,
			depth_first => $depth,
			only_files => 1,
			dir => "blah",
		);

		ok( !$paths->is_done, "not done" );

		my @all = $paths->all;

		ok( $paths->is_done, "done" );

		is_deeply(
			[ sort @all ],
			[ sort 'blah/gorch.txt' ],
			"breadth first traversal path set",
		);
	}
}

{
	local $SIG{__WARN__} = sub {};
	undef $s; undef $s;
}
