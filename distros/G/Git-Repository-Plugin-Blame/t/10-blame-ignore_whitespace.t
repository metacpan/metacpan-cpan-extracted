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

# Declare the list of tests to run.
my $tests =
[
	{
		name     => 'Test blame without ignore_whitespace argument.',
		options  => {},
		expected => [ 'Author1', 'Author2', 'Author1' ],
	},
	{
		name     => 'Test blame with ignore_whitespace=0.',
		options  => { ignore_whitespace => 0 },
		expected => [ 'Author1', 'Author2', 'Author1' ],
	},
	{
		name     => 'Test blame with ignore_whitespace=1.',
		options  => { ignore_whitespace => 1 },
		expected => [ 'Author1', 'Author1', 'Author1' ],
	},
];

plan( tests => 3 + scalar( @$tests ) );

# Create a new, empty repository in a temporary location and return
# a Git::Repository object.
my $repository = Test::Git::test_repository();

my $work_tree = $repository->work_tree();
ok(
	defined( $work_tree ) && -d $work_tree,
	'Find the work tree for the temporary test repository.',
);

# Name of the test file to use.
my $test_file = $work_tree . '/README';

subtest(
	'Commit new test file.',
	sub
	{
		plan( tests => 3 );

		# Set up the first author.
		local $ENV{'GIT_AUTHOR_NAME'} = 'Author1';
		local $ENV{'GIT_AUTHOR_EMAIL'} = 'author1@example.com';
		local $ENV{'GIT_COMMITTER_NAME'} = 'Author1';
		local $ENV{'GIT_COMMITTER_EMAIL'} = 'author1@example.com';

		# Create a new file.
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
	}
);

subtest(
	'Edit test file with only whitespace modifications.',
	sub
	{
		plan( tests => 2 );

		# Switch to editing the file with a different author.
		local $ENV{'GIT_AUTHOR_NAME'} = 'Author2';
		local $ENV{'GIT_AUTHOR_EMAIL'} = 'author2@example.com';
		local $ENV{'GIT_COMMITTER_NAME'} = 'Author2';
		local $ENV{'GIT_COMMITTER_EMAIL'} = 'author2@example.com';

		# Modify the file.
		ok(
			open( my $fh, '>', $test_file ),
			'Modify test file.'
		) || diag( "Failed to open $test_file for writing: $!" );
		print $fh "Test 1.\n";
		print $fh "Test 2.     \n";
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
	}
);

foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 4 );

			# Get the blame information.
			my $blame_lines;
			lives_ok(
				sub
				{
					$blame_lines = $repository->blame(
						$test_file,
						%{ $test->{'options'} },
					);
				},
				'Retrieve git blame information.',
			);

			is(
				scalar( @$blame_lines ),
				3,
				'Verify the number of lines with blame information',
			);

			ok(
				defined(
					my $authors = [ map { $_->get_commit_attributes()->{'author'} } @$blame_lines ]
				),
				'Prepare the list of authors found in the git blame output.',
			);

			is_deeply(
				$authors,
				$test->{'expected'},
				'The reported authors match the expected results.',
			) || diag( 'Found: ', explain( $authors ), 'Expected: ', explain( $test->{'expected'} ) );
		}
	);
}
