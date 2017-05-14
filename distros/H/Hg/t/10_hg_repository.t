use strict;
use warnings;
use 5.12.0;

use Test::More tests => 29;
use Test::Exception;

BEGIN { use_ok( 'Hg::Repository' ); }

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

    my $commit_repo_command = "$hg -R $test_repo commit -m '$message'";

    my $command_result;
    $command_result = `$commit_repo_command`;
}

init_test_repo;
throws_ok {
    my $repo = Hg::Repository->new(
        dir => $test_repo,
        hg => '/not/a/real/path',
    );
} qr/Can't find a working version of Mercurial at .*/, 
"The constructor fails when given a bad path to hg";

init_test_repo;
lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );
} 
"The constructor succeeds when given a good path to hg";

init_test_repo;
throws_ok {
    my $repo = Hg::Repository->new(
            dir => '/not/a/real/repo',
            hg => $hg,
        );
} qr/Can't find a Mercurial repository at .*/,
"The constructor fails when given a bad repository path";

init_test_repo;
lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );
}
"The constructor succeeds when given a good repository path";

lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );

    is( scalar(@{ $repo->revisions }), 0, "Revisions is an empty list" );
}
"Fetching empty revisions list doesn't throw any errors";

init_test_repo;
add_a_file;
commit_repo;
lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );

    my $revisions = $repo->revisions;

    is( scalar(@{ $revisions }), 1, "Revisions should have one element" );
    ok( $revisions->[0]->isa('Hg::Revision'), "Revisions should be Hg::Revision objects" );
}
"Fetching a single revision list doesn't throw any errors";

init_test_repo;
add_a_file;
commit_repo;
edit_a_file;
commit_repo;
lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );

    my $revisions = $repo->revisions;

    is( scalar(@{ $revisions }), 2, "Revisions should have two elements" );
    ok( $revisions->[0]->isa('Hg::Revision'), "Revisions should be Hg::Revision objects" );
    ok( $revisions->[1]->isa('Hg::Revision'), "Revisions should be Hg::Revision objects" );
}
"Fetching multiple revisions doesn't throw any errors";

init_test_repo;
add_a_file;
commit_repo 'Added';
edit_a_file;
commit_repo 'Edited';
lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );

    my $tip = $repo->tip;

    ok( $tip->isa('Hg::Revision'), "Tip is an Hg::Revision object" );
    is( $tip->description, 'Edited', "The tip description is correct" ); 
}
"Fetching the repository tip doesn't throw any errors";

init_test_repo;
add_a_file;
commit_repo 'Added';
edit_a_file;
commit_repo 'Edited';
update_repo 0;
lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );

    my $current = $repo->current;

    ok( $current->isa('Hg::Revision'), "Current is an Hg::Revision object" );
    is( $current->description, 'Added', "The current description is correct" ); 
}
"Fetching the current repository state doesn't throw any errors";

init_test_repo;
add_a_file;
commit_repo 'Added';
edit_a_file;
commit_repo 'Edited';
lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );

    my $rev = $repo->revision(0);

    ok( $rev->isa('Hg::Revision'), "Revision is an Hg::Revision object" );
    is( $rev->description, 'Added', "The revision description is correct" ); 
}
"Fetching a specific revision doesn't throw any errors";

init_test_repo;
add_a_file;
commit_repo 'Added';
edit_a_file;
commit_repo 'Edited';
lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );

    is( $repo->clean, 1, "The revision is being reported clean" ); 
    is( $repo->dirty, 0, "The revision is being reported not dirty" ); 
}
"Getting clean status doesn't throw any errors";

init_test_repo;
add_a_file;
commit_repo 'Added';
edit_a_file;
lives_ok {
    my $repo = Hg::Repository->new(
            dir => $test_repo,
            hg => $hg,
        );

    is( $repo->clean, 0, "The revision is being reported not clean" ); 
    is( $repo->dirty, 1, "The revision is being reported dirty" ); 
}
"Getting dirty status doesn't throw any errors";

done_testing;

