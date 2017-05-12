#!perl

# Note: cannot use -T here, Git::Repository uses environment variables directly.

use strict;
use warnings;

use Git::Repository ( 'Blame', 'Log' );
use Git::Repository::Plugin::Blame::Cache;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::Git;
use Test::Requires::Git;
use Test::More;
use Test::Type;


# Check there is a git binary available, or skip all.
test_requires_git( '1.5.0' );

plan( tests => 16 );

# Create a new, empty repository in a temporary location and return
# a Git::Repository object.
my $repository = Test::Git::test_repository();

my $work_tree = $repository->work_tree();
ok(
	defined( $work_tree ) && -d $work_tree,
	'Find the work tree for the temporary test repository.',
);

# Set up the default author.
$ENV{'GIT_AUTHOR_NAME'} = 'Author1';
$ENV{'GIT_AUTHOR_EMAIL'} = 'author1@example.com';
$ENV{'GIT_COMMITTER_NAME'} = 'Author1';
$ENV{'GIT_COMMITTER_EMAIL'} = 'author1@example.com';

# Create a new file.
my $test_file = $work_tree . '/README';
ok(
	open( my $fh, '>', $test_file ),
	'Create test file.'
) || diag( "Failed to open $test_file for writing: $!" );
print $fh "Test 1.\n";
print $fh "Test 2.\n";
print $fh "Test 3.\n";
close( $fh );

# Add the file to git.
lives_ok(
	sub
	{
		$repository->run( 'add', $test_file );
	},
	'Add test file to the Git index.',
);
lives_ok(
	sub
	{
		$repository->run( 'commit', '-m "First commit."' );
	},
	'Commit to Git.',
);
ok(
	my ( $log ) = $repository->log( '-1' ),
	'Retrieve the log of the commit.',
);
ok(
	defined( my $commit1_id = $log->commit() ),
	'Retrieve the commit ID.',
);

# Modify the file.
ok(
	open( $fh, '>', $test_file ),
	'Modify test file.'
) || diag( "Failed to open $test_file for writing: $!" );
print $fh "Test 1.\n";
print $fh "Test 2.a.\n";
print $fh "Test 2.b.\n";
print $fh "Test 3.\n";
close( $fh );

# Commit the changes to git.
lives_ok(
	sub
	{
		$repository->run( 'commit', '-m "Second commit."', '-a' );
	},
	'Commit to Git.',
);
ok(
	( $log ) = $repository->log( '-1' ),
	'Retrieve the log of the commit.',
);
ok(
	defined( my $commit2_id = $log->commit() ),
	'Retrieve the commit ID.',
);

# Get the blame information.
my $blame_lines;
lives_ok(
	sub
	{
		$blame_lines = $repository->blame( $test_file );
	},
	'Retrieve git blame information.',
);

ok_arrayref(
	$blame_lines,
	name => 'Blame information',
);

is(
	scalar( @$blame_lines ),
	4,
	'Verify the number of lines with blame information',
);

# Test the blame lines.
my $expected_commit_ids =
[
	$commit1_id,
	$commit2_id,
	$commit2_id,
	$commit1_id,
];

subtest(
	'The blame lines match expected information.',
	sub
	{
		plan( tests => 4 * scalar( @$blame_lines ) );
		my $count = 0;
		foreach my $blame_line ( @$blame_lines )
		{
			$count++;
			note( "Check line $count:" );
			isa_ok(
				$blame_line,
				'Git::Repository::Plugin::Blame::Line',
				"Blame information for line $count",
			);
			is(
				$blame_line->get_line_number(),
				$count,
				'The line number is correctly set on the object.',
			);

			my $commit_attributes = $blame_line->get_commit_attributes();
			ok(
				defined( $commit_attributes ),
				'The commit attributes are defined.',
			);

			is(
				$blame_line->get_commit_id(),
				$expected_commit_ids->[ $count - 1 ],
				'The commit ID reported by git blame is correct.',
			);

		}
	}
);

subtest(
	'Verify caching without arguments passed.',
	sub
	{
		plan( tests => 6 );

		# Make sure the cache is empty.
		ok(
			defined(
				my $cache = Git::Repository::Plugin::Blame::Cache->new(
					repository => $repository->work_tree(),
					blame_args =>
					{
						ignore_whitespace => 0,
					}
				)
			),
			'Instantiated cache object for the repository.',
		);
		ok(
			!defined(
				$cache->get_blame_lines( file => $test_file )
			),
			"The cache is empty for file '$test_file'.",
		) || diag( 'Cache: ', explain( $cache ) );

		# Call blame() again with cache enabled, which should populate the cache.
		ok(
			$repository->blame(
				$test_file,
				use_cache => 1,
			),
			'Call blame() with cache enabled.',
		);

		# Make sure the cache was populated.
		my $cached_blame_lines;
		ok(
			defined(
				$cached_blame_lines = $cache->get_blame_lines( file => $test_file )
			),
			"The cache is not empty for file '$test_file'.",
		) || diag( 'Cached blame lines: ', explain( $cached_blame_lines ) );
		is_deeply(
			$cached_blame_lines,
			$blame_lines,
			"The cached blame lines for file '$test_file' match the non-cached version.",
		) || diag( 'Cached: ', explain( $cached_blame_lines ), "\n", 'Non-cached: ', explain( $blame_lines ) );

		# Make sure the serialization worked as expected.
		is(
			$cache->{'serialized_blame_args'},
			'ignore_whitespace=0',
			'The serialization key accounts for the lack of arguments.',
		);
	}
);

subtest(
	'Verify caching with arguments passed.',
	sub
	{
		plan( tests => 6 );

		# Make sure the cache is empty.
		ok(
			defined(
				my $cache = Git::Repository::Plugin::Blame::Cache->new(
					repository => $repository->work_tree(),
					blame_args =>
					{
						ignore_whitespace => 1,
					}
				)
			),
			'Instantiated cache object for the repository.',
		);
		ok(
			!defined(
				$cache->get_blame_lines( file => $test_file ),
			),
			"The cache is empty for file '$test_file'.",
		) || diag( explain( $cache ) );

		# Call blame() again with cache enabled, which should populate the cache.
		ok(
			$repository->blame(
				$test_file,
				use_cache         => 1,
				ignore_whitespace => 1,
			),
			'Call blame() with use_cache=1 and ignore_whitespace=1.',
		);

		# Make sure the cache was populated.
		my $cached_blame_lines;
		ok(
			defined(
				$cached_blame_lines = $cache->get_blame_lines( file => $test_file ),
			),
			"The cache is not empty for file '$test_file'.",
		) || diag( 'Cached blame lines: ', explain( $cached_blame_lines ) );
		is_deeply(
			$cached_blame_lines,
			$blame_lines,
			"The cached blame lines for file '$test_file' match the non-cached version.",
		) || diag( 'Cached: ', explain( $cached_blame_lines ), "\n", 'Non-cached: ', explain( $blame_lines ) );

		# Make sure the serialization worked as expected.
		is(
			$cache->{'serialized_blame_args'},
			'ignore_whitespace=1',
			'The serialization key accounts for ignore_whitespace=1.',
		);
	}
);
