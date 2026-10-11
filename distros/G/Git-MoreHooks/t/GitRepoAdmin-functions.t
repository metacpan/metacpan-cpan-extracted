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
use Log::Any::Adapter ( 'Stdout', log_level => 'debug' );
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

    # A missing VERSION file means .git-repo-admin has not been installed in
    # this repository yet, which is ordinary: the config enabling this plugin is
    # tracked, so it reaches a clone before anybody runs client-hooks.sh
    # --install. This used to die, and because the plugin runs from post-merge
    # it died on `git pull`.
    $T->child('VERSION')->remove;
    my $missing_file = dies { Git::MoreHooks::GitRepoAdmin::_current_version( 'dummy', $T ) };
    is( $missing_file,                                                 undef, 'No exception when the VERSION file is absent' );
    is( Git::MoreHooks::GitRepoAdmin::_current_version( 'dummy', $T ), undef, 'No version when the VERSION file is absent' );

    my $no_dir      = Path::Tiny->tempdir( TMPDIR => 1, )->child('never-created');
    my $missing_dir = dies { Git::MoreHooks::GitRepoAdmin::_current_version( 'dummy', $no_dir ) };
    is( $missing_dir,                                                       undef, 'No exception when the directory is absent' );
    is( Git::MoreHooks::GitRepoAdmin::_current_version( 'dummy', $no_dir ), undef, 'No version when the directory is absent' );

    done_testing;
};

subtest 'Internal sub _new_version' => sub {
    my ( $repo, undef, undef, undef ) = new_repos();

    # The same defect in a different spelling: `cat-file` exits non-zero for a
    # path a branch does not carry, and Git::Repository turns that into a die.
    # A branch without .git-repo-admin/VERSION is not an error either -- it may
    # simply predate the hooks.
    my $missing = dies {
        Git::MoreHooks::GitRepoAdmin::_new_version( $repo, 'refs/heads/nosuchbranch', '.git-repo-admin' );
    };
    is( $missing, undef, 'No exception when the ref does not exist' );
    is( Git::MoreHooks::GitRepoAdmin::_new_version( $repo, 'refs/heads/nosuchbranch', '.git-repo-admin' ),
        undef, 'No version when the ref does not exist' );

    done_testing;
};

# Inadequate testing.
subtest 'Hook function check_affected_refs_client_side' => sub {
    my ( $repo, undef, $clone, $tempdir ) = new_repos();
    my $repodir         = $tempdir->child('repo');
    my $is_squash_merge = 0;
    my $git             = Git::Repository->new( work_tree => $repodir );

    # A repository without a .git-repo-admin directory used to make this throw,
    # out of an unguarded slurp of a VERSION file that is not there. It no
    # longer does: the state means "not installed here yet", which arrives in
    # every clone before anybody runs client-hooks.sh --install, and this hook
    # runs from post-merge, so throwing meant `git pull` died.
    my $client_error = dies {
        Git::MoreHooks::GitRepoAdmin::check_affected_refs_client_side( $git, $is_squash_merge );
    };
    is( $client_error, undef, 'No exception when the repo has no dir .git-repo-admin' );

    # It reports through $git->fault instead, which is what gives the user a
    # message rather than a stack trace.
    is( Git::MoreHooks::GitRepoAdmin::check_affected_refs_client_side( $git, $is_squash_merge ),
        1, 'Reports a problem instead of dying' );

    done_testing;
};

subtest 'Hook function check_affected_refs_server_side' => sub {
    my ( $repo, undef, $clone, $tempdir ) = new_repos();
    my $repodir = $tempdir->child('repo');
    my $git     = Git::Repository->new( work_tree => $repodir );

    # This subtest used to call the CLIENT side function, so the server side one
    # had never been exercised at all.
    my $server_error = dies {
        Git::MoreHooks::GitRepoAdmin::check_affected_refs_server_side($git);
    };
    is( $server_error, undef, 'No exception when the repo has no dir .git-repo-admin' );

    is( Git::MoreHooks::GitRepoAdmin::check_affected_refs_server_side($git), 1, 'Reports a problem instead of dying' );

    done_testing;
};

done_testing;
