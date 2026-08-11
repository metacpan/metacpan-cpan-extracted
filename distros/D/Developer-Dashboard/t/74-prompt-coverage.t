#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use lib 'lib';

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::Prompt;

# Hermetic runtime rooted in a throwaway HOME, with the current working
# directory moved inside it so the runtime-layer stack resolves from a clean
# temporary tree rather than the developer checkout.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "chdir $home: $!";

# Neutralise every prompt-affecting environment variable inherited from the
# harness so each scenario starts from a known-empty baseline.
delete @ENV{qw(TMUX DEVELOPER_DASHBOARD_TMUX_STATUS WORKSPACE_REF TICKET_REF)};

# build_stack()
# Purpose: construct a fresh paths/indicator/prompt stack bound to whatever
# DEVELOPER_DASHBOARD_STATE_ROOT is active in the current dynamic scope.
# Input: none.
# Output: (paths, indicator-store, prompt) three-element list.
sub build_stack {
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );
    my $ind    = Developer::Dashboard::IndicatorStore->new( paths => $paths );
    my $prompt = Developer::Dashboard::Prompt->new( paths => $paths, indicators => $ind );
    return ( $paths, $ind, $prompt );
}

# render_with($prompt, %args)
# Purpose: call render() with a localized, sanitized environment so the ticket
# and tmux-suppression branches are driven deterministically.
# Input: prompt object, render args, plus an optional env => { ... } override.
# Output: rendered prompt string.
sub render_with {
    my ( $prompt, %args ) = @_;
    my $env = delete $args{env} || {};
    local %ENV = %ENV;
    delete @ENV{qw(TMUX DEVELOPER_DASHBOARD_TMUX_STATUS WORKSPACE_REF TICKET_REF)};
    @ENV{ keys %$env } = values %$env;
    return $prompt->render(%args);
}

# write_file($path, $content)
# Purpose: write a small fixture file (git metadata / indicator JSON) verbatim.
# Input: path string and raw content string.
# Output: none.
sub write_file {
    my ( $path, $content ) = @_;
    open my $fh, '>:raw', $path or die "open $path: $!";
    print {$fh} $content;
    close $fh or die "close $path: $!";
    return;
}

# ---------------------------------------------------------------------------
# Scenario A: render() current-directory and ticket branches.
# Covers lines 37 (explicit cwd), 58 (WORKSPACE_REF/TICKET_REF ternaries) and 60
# (ticket push/no-push).
# ---------------------------------------------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
    my ( undef, undef, $prompt ) = build_stack();

    my $explicit = render_with(
        $prompt,
        cwd           => "$home/work",
        no_indicators => 1,
        env           => { TICKET_REF => 'T-1' },
    );
    like( $explicit, qr{\[~/work\]}, 'explicit cwd is honoured (line 37 left-true)' );
    like( $explicit, qr/🎫:T-1/, 'TICKET_REF becomes the ticket (line 58 defined-true, line 60 push)' );

    my $bare = render_with( $prompt, no_indicators => 1, env => {} );
    like( $bare, qr/Home: \Q$home\E/, 'falls back to cwd() when no cwd given (line 37 right-true)' );
    unlike( $bare, qr/🎫/, 'no ticket rendered when both refs unset (line 58 defined-false, line 60 no-push)' );

    my $empty_ws = render_with(
        $prompt,
        cwd           => "$home/work",
        no_indicators => 1,
        env           => { WORKSPACE_REF => '', TICKET_REF => 'T-2' },
    );
    like( $empty_ws, qr/🎫:T-2/, 'empty WORKSPACE_REF falls through to TICKET_REF (line 58 right-false)' );

    my $with_ws = render_with(
        $prompt,
        cwd           => "$home/work",
        no_indicators => 1,
        env           => { WORKSPACE_REF => 'ws-ref' },
    );
    like( $with_ws, qr/🎫:ws-ref/, 'non-empty WORKSPACE_REF wins (line 58 both-true)' );
}

# ---------------------------------------------------------------------------
# Scenario B: _tmux_status_active() environment matrix.
# Covers lines 132, 136, 137, 138.
# ---------------------------------------------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
    my ( undef, undef, $prompt ) = build_stack();

    my $active = sub {
        my (%set) = @_;
        local %ENV = %ENV;
        delete @ENV{qw(TMUX DEVELOPER_DASHBOARD_TMUX_STATUS WORKSPACE_REF TICKET_REF)};
        @ENV{ keys %set } = values %set;
        return $prompt->_tmux_status_active;
    };

    is( $active->(), 0, 'no TMUX means inactive (line 132 left-true)' );
    is( $active->( TMUX => '' ), 0, 'empty TMUX means inactive (line 132 right-true)' );
    is(
        $active->( TMUX => 'x', DEVELOPER_DASHBOARD_TMUX_STATUS => '1' ),
        1, 'DDTS=1 owns the strip (line 136 all-true)',
    );
    is(
        $active->( TMUX => 'x', DEVELOPER_DASHBOARD_TMUX_STATUS => '0' ),
        0, 'DDTS=0 falls through (line 136 outer right-false; 137/138 left-false)',
    );
    is(
        $active->(
            TMUX                            => 'x',
            DEVELOPER_DASHBOARD_TMUX_STATUS => '',
            WORKSPACE_REF                   => '',
            TICKET_REF                      => '',
        ),
        0, 'empty markers stay inactive (lines 136/137/138 right-false)',
    );
    is(
        $active->( TMUX => 'x', WORKSPACE_REF => 'ws' ),
        1, 'WORKSPACE_REF activates the strip (line 137 both-true)',
    );
    is(
        $active->( TMUX => 'x', TICKET_REF => 'tk' ),
        1, 'TICKET_REF activates the strip (line 138 both-true)',
    );
}

# ---------------------------------------------------------------------------
# Scenario C: _indicator_parts() colour/status rendering.
# Covers lines 101/102/103 (argument defaults), 114 (compact icon/label
# fallback condition), 116 and 117 (colour selection).
# ---------------------------------------------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
    my ( undef, $ind, $prompt ) = build_stack();

    $ind->set_indicator( 'i-ok',      icon   => '📦',      status => 'ok' );
    $ind->set_indicator( 'i-missing', label  => 'Missing', status => 'missing' );
    $ind->set_indicator( 'i-cyan',    label  => '' );                       # no status, no icon
    $ind->set_indicator( 'i-stale',   icon   => '🌟',      status => 'pending', stale => 1 );

    my $colored = render_with(
        $prompt,
        color => 1,
        mode  => 'compact',
        cwd   => "$home/work",
        env   => {},
    );
    like( $colored, qr/\e\[32m/, 'ok status renders green (line 117 ok/clean branch, line 116 truthy status)' );
    like( $colored, qr/\e\[31m/, 'missing status renders red (line 117 missing branch, line 114 label first char)' );
    like( $colored, qr/\e\[36m/, 'statusless indicator renders cyan (line 117 else branch, line 116 falsy status)' );
    like( $colored, qr/\e\[33m/, 'stale indicator renders yellow (line 117 stale branch)' );

    my @default_parts = $prompt->_indicator_parts();
    is( scalar @default_parts, 4, 'default-argument _indicator_parts still yields every part (lines 101/102/103 defaults)' );
}

# ---------------------------------------------------------------------------
# Scenario C2: a nameless indicator record leaves the label undef so the
# extended-mode defined() guard fires. Covers line 113.
# ---------------------------------------------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
    my ( $paths, undef, $prompt ) = build_stack();

    my $dir = File::Spec->catdir( $paths->indicators_root, 'nameless' );
    mkdir $dir or die "mkdir $dir: $!";
    write_file( File::Spec->catfile( $dir, 'status.json' ), '{"status":"pending"}' );

    my @parts = $prompt->_indicator_parts( mode => 'extended' );
    is( scalar @parts, 1, 'nameless indicator still produces one extended part (line 113 defined-guard)' );
    is( $parts[0], '', 'nameless indicator with an undef label collapses to empty text' );
}

# ---------------------------------------------------------------------------
# Scenario D: tmux status-line width folding plus _strip_ansi().
# Covers lines 84, 151, 152, 153, 167 and 184.
# ---------------------------------------------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
    my ( undef, $ind, $prompt ) = build_stack();
    $ind->set_indicator( 'router', icon => '📶', status => 'ok', label => 'Router' );

    my $plain = $prompt->render_tmux_status();
    like( $plain, qr/🕒/, 'default tmux status carries the timestamp (line 151/152/153 false; line 167 zero-width; line 84 kept)' );

    my $wide = $prompt->render_tmux_status( color => 1, max_age => 100, width => 200 );
    like( $wide, qr/🕒/, 'wide status keeps everything on the top line (line 151/152 true; line 153 both-true; line 167 fits)' );

    my $bad_width = $prompt->render_tmux_status( width => 'abc' );
    like( $bad_width, qr/🕒/, 'non-numeric width is ignored (line 153 numeric right-false)' );

    my $narrow = $prompt->render_tmux_status( width => 3 );
    like( $narrow, qr/🕒/, 'narrow width folds overflow onto a second line (line 167 overflow branch)' );
    like( $narrow, qr/\n/, 'narrow width actually produced a folded second line' );

    my $top_line = $prompt->render_tmux_status( line => 'top', width => 200 );
    ok( defined $top_line, 'explicit top-line request returns a value' );

    is( Developer::Dashboard::Prompt::_strip_ansi(undef), '', '_strip_ansi(undef) yields empty text (line 184 undef side)' );
    is( Developer::Dashboard::Prompt::_strip_ansi("\e[32mgreen\e[0m"), 'green', '_strip_ansi removes SGR escapes (line 184 defined side)' );
}

# ---------------------------------------------------------------------------
# Scenario E: git metadata resolution.
# Covers lines 196, 202, 205, 222, 228 and 231.
# ---------------------------------------------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
    my ( undef, undef, $prompt ) = build_stack();

    my $base = tempdir( CLEANUP => 1 );

    # Ordinary repository with a symbolic ref HEAD.
    my $ok = File::Spec->catdir( $base, 'ok' );
    mkdir $ok                                    or die "mkdir $ok: $!";
    mkdir File::Spec->catdir( $ok, '.git' )      or die "mkdir ok/.git: $!";
    write_file( File::Spec->catfile( $ok, '.git', 'HEAD' ), "ref: refs/heads/main\n" );
    is( $prompt->_git_branch($ok), 'main', 'symbolic HEAD resolves to a branch (line 196 both-true, line 205 defined)' );

    is( $prompt->_git_branch(undef), undef, 'undef project root yields no branch (line 196 falsy root)' );
    is(
        $prompt->_git_branch( File::Spec->catdir( $base, 'absent' ) ),
        undef, 'a non-directory project root yields no branch (line 196 not-a-dir)',
    );

    # Empty HEAD file -> readline returns undef.
    my $empty_head = File::Spec->catdir( $base, 'empty-head' );
    mkdir $empty_head                               or die "mkdir $empty_head: $!";
    mkdir File::Spec->catdir( $empty_head, '.git' ) or die "mkdir empty-head/.git: $!";
    write_file( File::Spec->catfile( $empty_head, '.git', 'HEAD' ), '' );
    is( $prompt->_git_branch($empty_head), undef, 'an empty HEAD yields no branch (line 205 undef side)' );

    # Unreadable HEAD -> open() fails even though -f is true.
    my $noread_head = File::Spec->catdir( $base, 'noread-head' );
    mkdir $noread_head                               or die "mkdir $noread_head: $!";
    mkdir File::Spec->catdir( $noread_head, '.git' ) or die "mkdir noread-head/.git: $!";
    my $nrhead = File::Spec->catfile( $noread_head, '.git', 'HEAD' );
    write_file( $nrhead, "ref: refs/heads/x\n" );
    chmod 0000, $nrhead;
    is( $prompt->_git_branch($noread_head), undef, 'an unreadable HEAD yields no branch (line 202 open-fail side)' );
    chmod 0644, $nrhead;

    # _git_metadata_dir argument guard.
    is( $prompt->_git_metadata_dir(undef), undef, 'undef metadata root returns undef (line 222 undef side)' );
    is( $prompt->_git_metadata_dir(''),    undef, 'empty metadata root returns undef (line 222 empty-string side)' );
    like( $prompt->_git_metadata_dir($ok), qr/\.git/, 'a real .git directory resolves (line 222 defined-non-empty)' );

    # Worktree-style .git file with a gitdir pointer.
    my $realgit = File::Spec->catdir( $base, 'realgit' );
    mkdir $realgit or die "mkdir $realgit: $!";
    write_file( File::Spec->catfile( $realgit, 'HEAD' ), "ref: refs/heads/feature\n" );
    my $wt = File::Spec->catdir( $base, 'wt' );
    mkdir $wt or die "mkdir $wt: $!";
    write_file( File::Spec->catfile( $wt, '.git' ), "gitdir: $realgit\n" );
    is( $prompt->_git_branch($wt), 'feature', 'a worktree .git file resolves the branch (line 228 open-ok, line 231 defined)' );

    # Empty .git file -> readline returns undef.
    my $empty_git = File::Spec->catdir( $base, 'empty-git' );
    mkdir $empty_git or die "mkdir $empty_git: $!";
    write_file( File::Spec->catfile( $empty_git, '.git' ), '' );
    is( $prompt->_git_metadata_dir($empty_git), undef, 'an empty .git file returns undef (line 231 undef side)' );

    # Unreadable .git file -> open() fails even though -f is true.
    my $noread_git = File::Spec->catdir( $base, 'noread-git' );
    mkdir $noread_git or die "mkdir $noread_git: $!";
    my $nggit = File::Spec->catfile( $noread_git, '.git' );
    write_file( $nggit, "gitdir: $realgit\n" );
    chmod 0000, $nggit;
    is( $prompt->_git_metadata_dir($noread_git), undef, 'an unreadable .git file returns undef (line 228 open-fail side)' );
    chmod 0644, $nggit;
}

done_testing;

__END__

=pod

=head1 NAME

t/74-prompt-coverage.t - branch and condition coverage closure for the prompt renderer

=head1 PURPOSE

This test drives every remaining branch and condition side of the prompt
renderer module so its Devel::Cover report reaches full branch and condition
coverage alongside the statement and subroutine coverage the wider suite already
provides. It exercises current-directory and ticket selection, tmux status
suppression, indicator colour and label formatting, tmux status-line width
folding, ANSI stripping, and git metadata resolution for both ordinary
repositories and worktree pointer files.

=head1 WHY IT EXISTS

The prompt renderer accumulated defensive fallbacks and multi-way conditionals
that the general suite executed only on their common side: an explicit working
directory, a present ticket reference, numeric tmux widths, well-formed
indicator records, and readable git metadata. The rarely taken sides -- an
undefined ticket, an empty or unreadable HEAD, a non-numeric width, a nameless
indicator record, a zero width, and a worktree gitdir file -- were never
reached, leaving branch and condition gaps. This test reproduces each of those
sides directly so the renderer's edge handling stays verified and cannot silently
rot, and so the coverage gate keeps reporting full branch and condition coverage.

=head1 WHEN TO USE

Use this file when changing prompt shape, indicator ordering or colour rules,
the tmux status-line folding logic, ticket-reference selection, or the direct
git-metadata reading that backs branch display. Re-run it whenever a coverage
report shows a new uncovered branch or condition in the prompt renderer.

=head1 HOW TO USE

Run C<prove -lv t/74-prompt-coverage.t> while iterating, and confirm it stays
green under C<prove -lr t>. Under the coverage gate it closes the renderer's
branch and condition columns; the two genuinely unreachable sides (a working
directory function that never returns false, and defined guards over values that
are never undef) are annotated in the module as uncoverable rather than tested.

=head1 WHAT USES IT

The repository test suite, the Devel::Cover coverage gate, and developers doing
prompt-focused changes use this file to keep the renderer's edge-case behavior
exercised end to end.

=head1 EXAMPLES

Example 1:

  prove -lv t/74-prompt-coverage.t

Run this focused prompt-coverage test on its own while iterating.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

Example 3:

  cover -delete
  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
  cover -report text -select_re '^lib/' -coverage branch -coverage condition

Confirm the prompt renderer reports full branch and condition coverage under the
gate after any change here.

=cut
