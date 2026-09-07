#!perl
## no critic (Subroutines::ProtectPrivateSubs)
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use File::Spec ();
use File::Temp ();
use Git::Repository;
use Git::Hooks::Test ':all';
use Log::Any::Adapter            ( 'Stdout', log_level => 'debug' );
use Git::MoreHooks::GitRepoAdmin ();

subtest 'Internal sub _current_version' => sub {
    my $T = Path::Tiny->tempdir( TMPDIR => 1, );

    my @data = ( "# This is comment\n", "\n", "1\n", );
    $T->child('VERSION')->spew(@data);

    is( Git::MoreHooks::GitRepoAdmin::_current_version( 'dummy', $T ), 1, 'Right version' );

    @data = ( "1 # version number not readable on a line with other text\n", );
    $T->child('VERSION')->spew(@data);
    is( Git::MoreHooks::GitRepoAdmin::_current_version( 'dummy', $T ), undef, 'Fails to read' );

    @data = ( '123', );
    $T->child('VERSION')->spew(@data);
    is( Git::MoreHooks::GitRepoAdmin::_current_version( 'dummy', $T ), 123, 'Read when no linefeed after' );

    @data = ( "1F\n", );
    $T->child('VERSION')->spew(@data);
    is( Git::MoreHooks::GitRepoAdmin::_current_version( 'dummy', $T ), undef, 'No read when not decimal number' );

    done_testing;
};

# Inadequate testing.
subtest 'Hook function check_affected_refs_client_side' => sub {
    my ( $repo, undef, $clone, $tempdir ) = new_repos();
    my $repodir = $tempdir->child('repo');
    my $is_squash_merge = 0;
    my $git = Git::Repository->new(work_tree => $repodir);
    like(
        dies { Git::MoreHooks::GitRepoAdmin::check_affected_refs_client_side($git, $is_squash_merge) },
        qr//msx,
        'Dies because repo does not have dir .git-repo-admin'
    );
    done_testing;
};

subtest 'Hook function check_affected_refs_server_side' => sub {
    my ( $repo, undef, $clone, $tempdir ) = new_repos();
    my $repodir = $tempdir->child('repo');
    my $git = Git::Repository->new(work_tree => $repodir);
    like(
        dies { Git::MoreHooks::GitRepoAdmin::check_affected_refs_client_side($git) },
        qr//msx,
        'Dies because repo does not have dir .git-repo-admin'
    );
    done_testing;
};

done_testing;
