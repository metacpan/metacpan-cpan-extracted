#!perl
use strict;
use warnings;
use Test2::V0;

use Log::Any::Adapter ( 'Stderr', log_level => 'warning' );
use Git::Hooks::Test ':all';
use English qw( -no_match_vars );    # Avoids regex performance penalty in perl 5.16 and earlier

my ( $repo, $clone, $T );

# Eliminate the effects of system wide and global configuration.
# https://metacpan.org/dist/Git-Repository/view/lib/Git/Repository/Tutorial.pod#Ignore-the-system-and-global-configuration-files
my %git_test_env = (
    LC_ALL              => 'C',
    GIT_CONFIG_NOSYSTEM => 1,
    XDG_CONFIG_HOME     => undef,
    HOME                => undef,
);

my %author_env = (
    GIT_AUTHOR_NAME     => 'My Self',
    GIT_AUTHOR_EMAIL    => 'myself@example.com',
    GIT_COMMITTER_NAME  => 'My Self',
    GIT_COMMITTER_EMAIL => 'myself@example.com',
);

my %env = ( %git_test_env, %author_env );

sub setup_repos {
    ( $repo, undef, $clone, $T ) = new_repos();

    install_hooks( $repo,  undef, qw/commit-msg/ );
    install_hooks( $clone, undef, qw/update pre-receive/ );
    return;
}

sub set_config {
    my ( $git, @pairs ) = @_;

    if ( !eval { $git->run( qw( config --remove-section githooks.checktrailers ), { env => \%env } ); 1 } ) {
        note 'There was no githooks.checktrailers section to remove.';
    }
    while ( my ( $option, $setting ) = splice @pairs, 0, 2 ) {
        $git->run( 'config', '--add', "githooks.checktrailers.$option", $setting, { env => \%env } );
    }
    return;
}

# Each -m becomes its own paragraph, which is how a real trailer is made. A
# single -m carrying an embedded newline makes the other shape: a line that
# looks like a trailer but which git does not read as one.
sub commit_ok {
    my ( $testname, @message ) = @_;
    return test_ok( $testname, $repo, 'commit', '--allow-empty', ( map { ( '-m', $_ ) } @message ), { env => \%env } );
}

sub commit_nok {
    my ( $testname, $regex, @message ) = @_;
    return test_nok_match( $testname, $regex, $repo, 'commit', '--allow-empty',
        ( map { ( '-m', $_ ) } @message ), { env => \%env } );
}

setup_repos();
$repo->run( qw/config githooks.plugin Git::MoreHooks::CheckTrailers/, { env => \%env } );

# REQUIREMENT: the plugin ships with no trailer names and must do nothing until
# a repository names its own. Checked first, and against the worst message, so
# that a default sneaking in later cannot pass unnoticed.
{
    set_config($repo);
    commit_ok( 'nothing configured, so nothing is denied', 'Initial commit', 'Co-Authored-By: Claude <x@y>' );
}

# deny
{
    set_config( $repo, deny => 'Co-Authored-By' );

    commit_nok( 'a denied trailer is rejected', qr/violates[ ]option[ ]'deny'/msx, 'Add a thing', 'Co-Authored-By: Claude <x@y>' );

    commit_nok(
        'odd case and spacing do not help',
        qr/violates[ ]option[ ]'deny'/msx,
        'Add a thing', 'co-authored-by :  Claude <x@y>'
    );

    commit_ok( 'an unrelated trailer passes', 'Add a thing', 'Signed-off-by: My Self <myself@example.com>' );
    commit_ok( 'and so does a message with no trailer at all', 'Add a thing' );

    # git does not read this as a trailer, but it will the moment the message is
    # reflowed or squash-merged, so it is reported -- in its own words.
    commit_nok(
        'a line that merely looks like the trailer is reported too',
        qr/does[ ]not[ ]read[ ]it[ ]as[ ]a[ ]trailer[ ]yet/msx,
        "Add a thing\nCo-Authored-By: Claude <x\@y>"
    );

    commit_ok( 'an indented line is prose, not a trailer', 'Add a thing', '    Co-Authored-By: Claude <x@y>' );
}

# A sign-off by a person is exactly what a DCO wants. A sign-off by a program is
# what the Linux kernel forbids. Only the second is rejected.
{
    set_config( $repo, deny => 'Signed-off-by qr/(?i:claude|copilot)/' );

    commit_ok( 'a human sign-off passes', 'Add a thing', 'Signed-off-by: My Self <myself@example.com>' );
    commit_nok(
        'a program sign-off does not',
        qr/violates[ ]option[ ]'deny'/msx,
        'Add a thing',
        'Signed-off-by: Claude <noreply@anthropic.com>'
    );
}

# require
{
    set_config( $repo, require => 'AI-assisted-by' );

    commit_ok( 'the required trailer is present', 'Add a thing', 'AI-assisted-by: Claude Code' );
    commit_nok( 'its absence is rejected', qr/does[ ]not[ ]have[ ]a[ ]trailer/msx, 'Add a thing' );
    commit_nok(
        'and so is writing it where git cannot see it',
        qr/paragraph[ ]of[ ]its[ ]own/msx,
        "Add a thing\nAI-assisted-by: Claude Code"
    );

    # A merge has no footer of its own, so requiring a disclosure of one would
    # make every merge fail. Exempt by default.
    $repo->run( qw/checkout -q -b side/,     { env => \%env } );
    $repo->run( qw(commit --allow-empty -m), 'Side work', '-m', 'AI-assisted-by: Claude Code', { env => \%env } );
    $repo->run( qw/checkout -q master/,      { env => \%env } );
    test_ok( 'a merge commit is exempt from require', $repo, 'merge', '--no-ff', '--no-edit', 'side', { env => \%env } );

    # The literal value 'undef' clears a repeated option, which is how a
    # repository that does not want a mandatory trailer says so.
    $repo->run( qw/config --add githooks.checktrailers.require undef/, { env => \%env } );
    commit_ok( 'require = undef clears the requirement', 'Add a thing' );
}

# order
{
    set_config( $repo, order => 'AI-assisted-by', order => 'Signed-off-by' );

    commit_ok(
        'the configured order is accepted',
        'Add a thing',
        'AI-assisted-by: Claude Code',
        'Signed-off-by: My Self <myself@example.com>'
    );

    # One paragraph, so both trailers share a block and their order is the order
    # they were written in.
    commit_nok(
        'the reverse order is rejected',
        qr/must[ ]come[ ]before/msx,
        'Add a thing', "Signed-off-by: My Self <myself\@example.com>\nAI-assisted-by: Claude Code"
    );
}

# The bypass exists and is documented behaviour, so it is asserted rather than
# left to be discovered.
{
    set_config( $repo, deny => 'Co-Authored-By' );
    test_ok(
        'commit --no-verify bypasses the hook',
        $repo, 'commit', '--allow-empty', '--no-verify', '-m', 'Add a thing', '-m',
        'Co-Authored-By: Claude <x@y>',
        { env => \%env }
    );
}

# THE SERVER SIDE, which is the real gate: rebase, filter-branch and
# non-interactive cherry-pick never run commit-msg, and --no-verify is always
# available, so a client-side check alone cannot hold a branch.
{
    set_config( $repo, deny => 'Co-Authored-By' );
    $clone->run( qw/config githooks.plugin Git::MoreHooks::CheckTrailers/, { env => \%env } );
    set_config( $clone, deny => 'Co-Authored-By' );

    test_nok_match(
        'the push of a denied trailer is rejected',
        qr/violates[ ]option[ ]'deny'/msx,
        $repo, 'push', 'clone', 'master', { env => \%env }
    );

    # Two offending commits in one push must both be named: the server walks
    # every commit the reference brings, and the faults accumulate.
    $repo->run( qw(commit --allow-empty --no-verify -m), 'Another thing', '-m', 'Co-Authored-By: Claude <x@y>', { env => \%env } );
    test_nok_match(
        'both offending commits are named in one rejection',
        qr/(?:violates[ ]option[ ]'deny'.*){2}/msx,
        $repo, 'push', 'clone', 'master', { env => \%env }
    );

    # And a history with nothing to object to goes through. An orphan branch,
    # because by now every commit on master carries a denied trailer -- the
    # first one deliberately, to prove the plugin was inert before it was
    # configured.
    $repo->run( qw/checkout -q --orphan clean-branch/, { env => \%env } );
    $repo->run( qw(commit --allow-empty -m), 'A clean thing', { env => \%env } );
    test_ok( 'a clean history pushes', $repo, 'push', 'clone', 'clean-branch', { env => \%env } );
}

done_testing();
