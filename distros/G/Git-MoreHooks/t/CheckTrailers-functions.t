#!perl
## no critic (Subroutines::ProtectPrivateSubs)
## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars) -- the specifications under test are regex source, held as literal data
use strict;
use warnings;
use Test2::V0;

use Test::Requires::Git ();
use Test::Git           qw( test_repository );
use Git::Repository 'GitHooks';
use Git::MoreHooks::CheckTrailers ();

# We need Git which supports the --initial-branch parameter in init command.
Test::Requires::Git::test_requires_git '2.28.0';

# Eliminate the effects of system wide and global configuration.
# https://metacpan.org/dist/Git-Repository/view/lib/Git/Repository/Tutorial.pod#Ignore-the-system-and-global-configuration-files
my %git_test_env = (
    LC_ALL              => 'C',
    GIT_CONFIG_NOSYSTEM => 1,
    XDG_CONFIG_HOME     => undef,
    HOME                => undef,
);

my $PKG = 'Git::MoreHooks::CheckTrailers';

sub new_repo {
    my $r = test_repository(
        temp => [ CLEANUP => 1 ],
        init => [ '--initial-branch', 'main' ],
        git  => {},
    );
    $r->run( qw/config user.name My Self/,             { env => {%git_test_env} } );
    $r->run( qw/config user.email myself@example.com/, { env => {%git_test_env} } );
    return $r;
}

# Set the plugin's configuration from scratch.
#
# Both of Git::Hooks' caches have to go: get_config reads `git config` once per
# repository object, and the plugin caches its parsed specifications. Without
# clearing them a second configuration in one process would be answered from the
# first.
sub configure {
    my ( $git, @pairs ) = @_;

    # The section may not exist yet, and git says so loudly; that is not news.
    if ( !eval { $git->run( qw( config --remove-section githooks.checktrailers ), { env => {%git_test_env} } ); 1 } ) {
        note 'There was no githooks.checktrailers section to remove.';
    }
    while ( my ( $option, $setting ) = splice @pairs, 0, 2 ) {
        $git->run( 'config', '--add', "githooks.checktrailers.$option", $setting, { env => {%git_test_env} } );
    }

    delete $git->{'_plugin_githooks'}->{'config'};
    $PKG->can('_setup_config')->($git);
    return;
}

sub faults_of {
    my ($git) = @_;
    $git->{'_plugin_githooks'}->{'hookname'} //= 'commit-msg';
    my $faults = $git->get_faults() // q{};
    delete $git->{'_plugin_githooks'}->{'faults'};
    return $faults;
}

subtest 'Parse a specification' => sub {
    my @GOOD = (
        [ 'Co-Authored-By',                   'a bare token' ],
        [ 'co-authored-by',                   'a bare token, lower case' ],
        [ 'Signed-off-by Claude',             'a token and a literal value' ],
        [ 'Signed-off-by qr/claude|copilot/', 'a token and a value pattern' ],
        [ 'qr{^co-authored-by$} qr/./',       'patterns for both fields' ],
        [ 'AI-assisted-by   Claude Code',     'a value containing a space' ],
    );
    foreach my $case (@GOOD) {
        my ( $spec,   $what ) = @{$case};
        my ( $parsed, $why )  = Git::MoreHooks::CheckTrailers::_parse_spec($spec);
        is( $why, undef, "accepted: $what" );
        isnt( $parsed, undef, "...and returns a specification: $what" );
    }

    my @BAD = (
        [ 'Co-Authored-By qr/[unclosed/', 'an uncompilable pattern' ],
        [ 'qr/x/msx',                     'trailing flags, which would silently change the meaning' ],
        [ q{},                            'an empty specification' ],
        [ q{   },                         'only whitespace' ],
        [ 'Bad:Token x',                  'a colon in the token' ],
    );
    foreach my $case (@BAD) {
        my ( $spec,   $what ) = @{$case};
        my ( $parsed, $why )  = Git::MoreHooks::CheckTrailers::_parse_spec($spec);
        isnt( $why, undef, "rejected: $what" );
        is( $parsed, undef, "...and returns nothing: $what" );
    }

    done_testing;
};

# THE CONTRACT. Every row here is a message shape that Git::Message -- which
# Git::Hooks::CheckLog uses -- gets wrong, or one that could tempt a hand-written
# parser. The second row is the regression test for the whole design: a body
# line above the trailers makes a stricter parser report no trailers at all,
# while git reads both and GitHub mints a contributor from the first.
subtest 'Trailers, as git itself reads them' => sub {
    my $git = new_repo();
    configure( $git, deny => 'Co-Authored-By' );

    my @CASES = (
        [ 'a trailer in its own paragraph', "Fix\n\nCo-Authored-By: C <x\@y>\n", ['Co-Authored-By'], 0 ],
        [
            'a body line above two trailers',
            "Fix\n\nSome body.\nCo-Authored-By: C <x\@y>\nSigned-off-by: M <m\@e>\n",
            [ 'Co-Authored-By', 'Signed-off-by' ], 0
        ],
        [ 'a space before the colon',       "Fix\n\nco-authored-by :  C <x\@y>\n",       ['co-authored-by'], 0 ],
        [ 'a value folded over two lines',  "Fix\n\nAI-assisted-by: Claude\n  folded\n", ['AI-assisted-by'], 0 ],
        [ 'a trailer glued to the title',   "Fix\nCo-Authored-By: C <x\@y>\n",           [],                 1 ],
        [ 'underscores, which git ignores', "Fix\n\nCo_Authored_By: C <x\@y>\n",         [],                 0 ],
        [ 'an indented line',               "Fix\n\n    Co-Authored-By: C <x\@y>\n",     [],                 0 ],
        [ 'a message of one line',          "AI-assisted-by: Claude Code\n",             [],                 0 ],
    );

    foreach my $case (@CASES) {
        my ( $what, $msg, $tokens, $suspects ) = @{$case};
        my $trailers = Git::MoreHooks::CheckTrailers::_trailers( $git, $msg );
        is( [ map { $_->{'token'} } @{$trailers} ], $tokens, "git reads the right trailers: $what" );

        my $found = Git::MoreHooks::CheckTrailers::_suspect_lines( $git, $msg, $trailers );
        is( scalar @{$found}, $suspects, "...and the right number of suspect lines: $what" );
    }

    # A folded trailer must not be reported twice -- once as a real trailer and
    # again as a suspect line, because unfolding changes its value.
    my $folded = Git::MoreHooks::CheckTrailers::_trailers( $git, "Fix\n\nAI-assisted-by: Claude\n  folded\n" );
    is( $folded->[0]->{'value'}, 'Claude folded', 'a folded value is unfolded' );

    done_testing;
};

subtest 'Deny' => sub {
    my $git = new_repo();

    configure( $git, deny => 'Co-Authored-By' );
    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix\n\nCo-Authored-By: C <x\@y>\n" ),
        1, 'a denied trailer is one error' );
    like( faults_of($git), qr/violates[ ]option[ ]'deny'/msx, '...reported as a deny violation' );

    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix\n\nco-authored-by :  C <x\@y>\n" ),
        1, 'case and spacing do not help' );
    faults_of($git);

    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix\n\nSigned-off-by: M <m\@e>\n" ),
        0, 'an unrelated trailer passes' );

    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix\nCo-Authored-By: C <x\@y>\n" ),
        1, 'a line git does not read as a trailer is still reported' );
    like( faults_of($git), qr/does[ ]not[ ]read[ ]it[ ]as[ ]a[ ]trailer[ ]yet/msx, '...and said to be only a suspect' );

    # A sign-off by a person is what a DCO wants; a sign-off by a program is what
    # the Linux kernel forbids. Only the second is rejected.
    configure( $git, deny => 'Signed-off-by qr/(?i:claude|copilot)/' );
    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix\n\nSigned-off-by: Mikko <m\@cpan.org>\n" ),
        0, 'a human sign-off passes a value pattern' );
    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix\n\nSigned-off-by: Claude <noreply\@anthropic.com>\n" ),
        1, '...and a program sign-off does not' );
    faults_of($git);

    configure( $git, deny => 'Co-Authored-By', deny => 'Generated-By' );
    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix\n\nCo-Authored-By: C <x\@y>\nGenerated-By: G\n" ),
        2, 'two denied trailers are two errors' );
    my $faults = faults_of($git);
    like( $faults, qr/Co-Authored-By/msx, '...and both appear in the report' );
    like( $faults, qr/Generated-By/msx,   '...both of them' );

    done_testing;
};

subtest 'Require' => sub {
    my $git = new_repo();
    configure( $git, require => 'AI-assisted-by' );

    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix\n\nAI-assisted-by: Claude Code\n" ),
        0, 'the required trailer is present' );

    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix thing\n" ), 1, 'and its absence is an error' );
    like( faults_of($git), qr/does[ ]not[ ]have[ ]a[ ]trailer/msx, '...saying it is missing' );

    # The mistake worth its own message.
    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix\nAI-assisted-by: Claude Code\n" ),
        1, 'written, but where git cannot see it' );
    like( faults_of($git), qr/paragraph[ ]of[ ]its[ ]own/msx, '...and says to put a blank line before it' );

    configure( $git, require => 'AI-assisted-by qr/claude/' );
    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix\n\nAI-assisted-by: Some Other Tool\n" ),
        1, 'a value the repository does not accept' );
    like( faults_of($git), qr/value[ ]this[ ]repository[ ]does[ ]not[ ]accept/msx, '...reported as such' );

    # A commit kind with no footer of its own is not a place to disclose anything.
    configure( $git, require => 'AI-assisted-by' );
    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Revert \"Fix\"\n\nThis reverts commit 1234567.\n" ),
        0, 'a revert is exempt by default' );
    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "fixup! Fix thing\n" ), 0, 'a fixup is exempt by default' );

    configure( $git, require => 'AI-assisted-by', 'require-skip' => 'none' );
    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "fixup! Fix thing\n" ),
        1, 'and require-skip = none exempts nothing' );
    faults_of($git);

    done_testing;
};

subtest 'Order' => sub {
    my $git = new_repo();
    configure( $git, order => 'AI-assisted-by', order => 'Signed-off-by' );

    is(
        Git::MoreHooks::CheckTrailers::message_errors(
            $git, undef, "Fix\n\nAI-assisted-by: Claude Code\nSigned-off-by: M <m\@e>\n"
        ),
        0,
        'the configured order is accepted'
    );

    is(
        Git::MoreHooks::CheckTrailers::message_errors(
            $git, undef, "Fix\n\nSigned-off-by: M <m\@e>\nAI-assisted-by: Claude Code\n"
        ),
        1,
        'and the reverse is not'
    );
    like( faults_of($git), qr/must[ ]come[ ]before/msx, '...naming which must come first' );

    is(
        Git::MoreHooks::CheckTrailers::message_errors(
            $git, undef, "Fix\n\nAI-assisted-by: Claude Code\nReviewed-by: R\nSigned-off-by: M <m\@e>\n"
        ),
        0,
        'a trailer nobody ordered is ignored'
    );

    # '*' is how "the sign-off comes last" is said.
    configure( $git, order => q{*}, order => 'Signed-off-by' );
    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, "Fix\n\nSigned-off-by: M <m\@e>\nReviewed-by: R\n" ),
        1, 'the wildcard puts everything else first' );
    faults_of($git);

    done_testing;
};

# Requirement: the plugin ships with no trailer names and must do nothing until a
# repository names its own. There is no settled spelling for a disclosure
# trailer, so a default would be an opinion the plugin has no business holding.
subtest 'Inert until configured' => sub {
    my $git = new_repo();
    configure($git);

    my $everything = "Fix\n\nCo-Authored-By: C <x\@y>\nGenerated-By: G\nSigned-off-by: Claude <n\@a.com>\n";
    is( Git::MoreHooks::CheckTrailers::message_errors( $git, undef, $everything ),
        0, 'a message full of forbidden trailers passes when nothing is configured' );
    is( faults_of($git), q{}, '...and nothing is reported' );

    done_testing;
};

subtest 'Commit kinds' => sub {
    my $git = new_repo();
    configure( $git, require => 'X' );

    is( Git::MoreHooks::CheckTrailers::_commit_kinds( $git, undef, "Revert \"Fix\"\n\nThis reverts commit abc1234.\n" ),
        ['revert'], 'a revert is recognised from its message' );
    is( Git::MoreHooks::CheckTrailers::_commit_kinds( $git, undef, "squash! Fix\n" ), ['fixup'], 'so is a squash' );
    is( Git::MoreHooks::CheckTrailers::_commit_kinds( $git, undef, "Fix thing\n" ),   [], 'an ordinary commit is no kind at all' );

    done_testing;
};

# The once-only report of an interpret-trailers failure is held per repository
# and not in a package variable. A package variable outlives the invocation in
# any interpreter that handles more than one, and the second repository would
# then never be told that the plugin could not do its job.
#
# This exercises the scoping and the clearing, which is what the fix changed.
# The failure path itself stays untested: `git interpret-trailers --parse`
# cannot be made to fail from here -- it warns and exits 0 even for a bogus
# trailer.* configuration -- so provoking it would need the git call mocked.
subtest 'the once-only interpret-trailers report is per repository' => sub {
    my $first = test_repository( temp => [ CLEANUP => 1 ], init => ['--initial-branch=main'] );
    my $other = test_repository( temp => [ CLEANUP => 1 ], init => ['--initial-branch=main'] );

    $first->cache('checktrailers')->{'announced_no_interpret_trailers'} = 1;

    ok( $first->cache('checktrailers')->{'announced_no_interpret_trailers'},  'set for the first repository' );
    ok( !$other->cache('checktrailers')->{'announced_no_interpret_trailers'}, 'and not for a second one in the same interpreter' );

    Git::MoreHooks::CheckTrailers::_setup_config($first);
    ok(
        !$first->cache('checktrailers')->{'announced_no_interpret_trailers'},
        '_setup_config clears it, so one invocation cannot silence the next'
    );

    done_testing;
};

done_testing();
