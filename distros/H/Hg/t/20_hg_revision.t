use strict;
use warnings;
use 5.12.0;

use Test::More tests => 10;
use Test::Exception;

BEGIN { 
	use_ok( 'Hg::Repository' );
	use_ok( 'Hg::Revision' );
}

my $test_repo = '/tmp/perl-hg-test';
my $hg        = `which hg`;
chomp $hg;

sub init_test_repo {
    my $clean_repo_command = "rm -rf $test_repo";
    my $mkdir_command      = "mkdir -p $test_repo";
    my $repo_init_command  = "( cd $test_repo; $hg init )";

    my $command_result;
    $command_result = `$clean_repo_command`;
    $command_result = `$mkdir_command`;
    $command_result = `$repo_init_command`;
}

sub add_a_file {
    my $create_file_command = "echo 'Foo Bar Baz' > $test_repo/test_file";
    my $add_file_command    = "$hg -R $test_repo add $test_repo/test_file";

    my $command_result;
    $command_result = `$create_file_command`;
    $command_result = `$add_file_command`;
}

sub edit_a_file {
    my $edit_file_command = "echo 'New Content' > $test_repo/test_file";

    my $command_result;
    $command_result = `$edit_file_command`;
}

sub update_repo {
    my $revision = shift || 0;

    my $update_command = "$hg -R $test_repo update -r $revision";

    my $command_result;
    $command_result = `$update_command`;
}

sub commit_repo {
    my $message = shift || 'Test Commit';

    my $commit_repo_command = "$hg -R $test_repo commit -m '$message' -u 'Test Author'";

    my $command_result;
    $command_result = `$commit_repo_command`;
}

dies_ok {
	my $rev = Hg::Repository->new(
			node => '44f022d9c12867b5bc83ab29f41a33750fdf12d5',
		);
}
"The constructor dies when a repository isn't provided";

init_test_repo;
add_a_file;
commit_repo;
dies_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );

	my $rev = Hg::Repository->new(
			repository => $repo,
		);
}
"The constructor dies when a node isn't provided";

init_test_repo;
add_a_file;
commit_repo;
lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );

	my $rev = $repo->tip;
}
"The constructor doesn't throw an error";

init_test_repo;
add_a_file;
commit_repo;
lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );

	my $rev = $repo->tip;

	is( $rev->author      , 'Test Author' , 'Author is correct' );
	is( $rev->branch      , 'default'     , 'Branch is correct' );
	is( $rev->description , 'Test Commit' , 'Description is correct' );
	is( $rev->number      , 0             , 'Revision number is correct' );
}
"Getting attributes doesn't throw an error";

done_testing;

