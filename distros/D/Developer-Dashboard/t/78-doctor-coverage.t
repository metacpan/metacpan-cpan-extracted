#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::InternalCLI;
use Developer::Dashboard::Doctor;

# Hermetic runtime rooted in a throwaway home. Config layers resolve from the
# deepest .developer-dashboard directory found walking up from the cwd, so we
# must chdir into the temp home for the registry to bind to it.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";
delete $ENV{RESULT} if exists $ENV{RESULT};

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $doctor = Developer::Dashboard::Doctor->new( paths => $paths );

# writes one file with the given body.
sub write_file {
    my ( $path, $body ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $body;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# A dashboard-managed PATH bootstrap line and a standard bash non-interactive
# early-return guard, reused across the shell-bootstrap fixtures.
my $dashboard_line = q{export PATH="$HOME/perl5/perlbrew/perls/perl-5.36/bin:$PATH"};
my $guard_line     = q{[ -z "$PS1" ] && return};

# ---------------------------------------------------------------------------
# A full run over a pristine home exercises the ordinary (non-defensive) side
# of the collector map, the ok flag, the hook decode, and the dedup loop.
# ---------------------------------------------------------------------------
{
    my $report = $doctor->run( fix => 0 );
    is( ref $report, 'HASH', 'run returns a structured report hash' );
    is( $report->{ok}, 0, 'run reports not-ok while managed helpers are unstaged' );
    ok( $report->{issue_count} > 0, 'run surfaces the missing managed helper issues' );
    is( $report->{hook_failures}, 0, 'run reports no hook failures when RESULT is unset' );
}

# ---------------------------------------------------------------------------
# _permission_issue_for_path guards an undef and an empty path explicitly.
# ---------------------------------------------------------------------------
{
    is( $doctor->_permission_issue_for_path(undef), undef, '_permission_issue_for_path returns undef for an undef path' );
    is( $doctor->_permission_issue_for_path(q{}),   undef, '_permission_issue_for_path returns undef for an empty path' );
}

# ---------------------------------------------------------------------------
# _doctor_hook_results treats a defined-but-empty RESULT as "no hooks".
# ---------------------------------------------------------------------------
{
    local $ENV{RESULT} = '';
    is_deeply( $doctor->_doctor_hook_results, {}, '_doctor_hook_results returns an empty hash for a blank RESULT' );
}

# ---------------------------------------------------------------------------
# run() with injected empty issues and a mix of passing/failing hooks drives
# the exit-code fallback, the collector fallback, and the middle ok condition.
# ---------------------------------------------------------------------------
{
    local $ENV{RESULT} = '{"good":{"exit_code":0},"bad":{"exit_code":2}}';
    no warnings 'redefine';
    local *Developer::Dashboard::Doctor::_audit_roots =
      sub { return ( { label => 'injected', path => '/injected', issues => undef } ) };
    local *Developer::Dashboard::Doctor::_helper_issues         = sub { return () };
    local *Developer::Dashboard::Doctor::_shell_bootstrap_issues = sub { return () };

    my $report = $doctor->run( fix => 0 );
    is( $report->{issue_count},   0, 'run collapses a root whose issues field is empty to zero issues' );
    is( $report->{hook_failures}, 1, 'run counts only the hook with a non-zero exit code' );
    is( $report->{ok},            0, 'run reports not-ok when a hook fails even without permission issues' );
}

# ---------------------------------------------------------------------------
# run() with no issues and no failing hooks reports ok, covering the fully
# clean ok condition.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::Doctor::_audit_roots =
      sub { return ( { label => 'clean', path => '/clean', issues => [] } ) };
    local *Developer::Dashboard::Doctor::_helper_issues         = sub { return () };
    local *Developer::Dashboard::Doctor::_shell_bootstrap_issues = sub { return () };

    my $report = $doctor->run( fix => 0 );
    is( $report->{ok},          1, 'run reports ok when there are neither issues nor failing hooks' );
    is( $report->{issue_count}, 0, 'run reports zero issues for a clean runtime' );
}

# ---------------------------------------------------------------------------
# _audit_roots skips a path-less root and a duplicate root path.
# ---------------------------------------------------------------------------
{
    my $dup = File::Spec->catdir( $home, 'dedup-root-absent' );
    no warnings 'redefine';
    local *Developer::Dashboard::Doctor::_known_roots = sub {
        return (
            { label => 'nopath', path => undef },
            { label => 'dup1',   path => $dup },
            { label => 'dup2',   path => $dup },
        );
    };
    my @reports = $doctor->_audit_roots( fix => 0 );
    is( scalar @reports, 1, '_audit_roots skips the path-less and duplicated roots, auditing each unique path once' );
    is( $reports[0]{label}, 'dup1', '_audit_roots audits the first occurrence of a duplicated root path' );
    ok( !$reports[0]{exists}, '_audit_roots marks an absent duplicate root as non-existent' );
}

# ---------------------------------------------------------------------------
# _helper_issue_for_path rejects a missing name or a missing path.
# ---------------------------------------------------------------------------
{
    my $name_err = eval { $doctor->_helper_issue_for_path( path => 'x' ); 1 } ? '' : $@;
    like( $name_err, qr/Missing helper audit name/, '_helper_issue_for_path dies without a helper name' );
    my $path_err = eval { $doctor->_helper_issue_for_path( name => 'jq' ); 1 } ? '' : $@;
    like( $path_err, qr/Missing helper audit path/, '_helper_issue_for_path dies without a helper path' );
}

# ---------------------------------------------------------------------------
# _helper_issue_for_path dies when a present helper file cannot be read.
# Root can read a 0000 file, so only assert the failure as a non-root user.
# ---------------------------------------------------------------------------
SKIP: {
    skip 'unreadable-file check is meaningless as root', 1 if $> == 0;
    my $unreadable = File::Spec->catfile( $home, 'unreadable-helper' );
    write_file( $unreadable, "some staged body\n" );
    chmod 0000, $unreadable or die "Unable to chmod $unreadable: $!";
    my $err = eval { $doctor->_helper_issue_for_path( name => 'jq', path => $unreadable ); 1 } ? '' : $@;
    like( $err, qr/Unable to read/, '_helper_issue_for_path dies when a staged helper cannot be opened for reading' );
    chmod 0600, $unreadable or die "Unable to restore $unreadable: $!";
}

# ---------------------------------------------------------------------------
# _helper_issue_for_path reports stale drift when the staged file is empty
# (the slurp yields a defined empty string that never matches the helper body).
# ---------------------------------------------------------------------------
{
    my $empty = File::Spec->catfile( $home, 'empty-helper' );
    write_file( $empty, q{} );
    my $issue = $doctor->_helper_issue_for_path( name => 'jq', path => $empty );
    ok( $issue, '_helper_issue_for_path reports drift for an empty staged helper file' );
    is( $issue->{current_mode}, 'stale', '_helper_issue_for_path classifies an empty helper as stale' );
}

# ---------------------------------------------------------------------------
# _helper_issues in fix mode, with restaging stubbed to a no-op, leaves the
# helpers unfixed (post-issue still present).
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::ensure_helpers = sub { return 1 };
    my @issues = $doctor->_helper_issues( fix => 1 );
    ok( scalar @issues, '_helper_issues finds missing managed helpers in a bare runtime' );
    ok( !$issues[0]{fixed}, '_helper_issues marks a helper unfixed when restaging leaves it missing' );
}

# ---------------------------------------------------------------------------
# _helper_issues in fix mode with the real restager marks helpers as fixed and
# drives the matching-content return path.
# ---------------------------------------------------------------------------
{
    my @issues = $doctor->_helper_issues( fix => 1 );
    ok( scalar @issues, '_helper_issues still reports the pre-fix helper drift' );
    ok( ( grep { $_->{fixed} } @issues ), '_helper_issues marks restaged helpers as fixed after a real restage' );
}

# ---------------------------------------------------------------------------
# _audit_root fixes owner-only permission drift on a real tree, exercising the
# successful chmod side of the repair loop.
# ---------------------------------------------------------------------------
{
    my $tree = File::Spec->catdir( $home, 'audit-tree' );
    make_path($tree);
    my $wide_file = File::Spec->catfile( $tree, 'too-wide' );
    write_file( $wide_file, "x\n" );
    chmod 0666, $wide_file or die "Unable to chmod $wide_file: $!";
    chmod 0777, $tree      or die "Unable to chmod $tree: $!";

    my $report = $doctor->_audit_root( path => $tree, label => 'audit-tree', fix => 1 );
    ok( $report->{exists}, '_audit_root audits an existing runtime tree' );
    ok( $report->{issue_count} >= 1, '_audit_root discovers owner-only permission drift' );
    ok( ( grep { $_->{fixed} } @{ $report->{issues} } ), '_audit_root repairs permission drift when fix is requested' );
}

# ---------------------------------------------------------------------------
# _shell_bootstrap_issues in fix mode with the rewrite stubbed to a no-op
# leaves the bootstrap issue unfixed.
# ---------------------------------------------------------------------------
{
    my $bashrc = File::Spec->catfile( $home, '.bashrc' );
    write_file( $bashrc, "# lead\n$guard_line\n$dashboard_line\n" );
    no warnings 'redefine';
    local *Developer::Dashboard::Doctor::_rewrite_bashrc_dashboard_lines = sub { return };
    my @issues = $doctor->_shell_bootstrap_issues( fix => 1 );
    ok( scalar @issues, '_shell_bootstrap_issues detects a dashboard line hidden behind the non-interactive guard' );
    ok( !$issues[0]{fixed}, '_shell_bootstrap_issues marks the issue unfixed when the rewrite leaves the line in place' );
    unlink $bashrc;
}

# ---------------------------------------------------------------------------
# _shell_bootstrap_issues in fix mode with the real rewrite marks the issue
# fixed once the dashboard line is moved ahead of the guard.
# ---------------------------------------------------------------------------
{
    my $bashrc = File::Spec->catfile( $home, '.bashrc' );
    write_file( $bashrc, "# lead\n$guard_line\n$dashboard_line\n" );
    my @issues = $doctor->_shell_bootstrap_issues( fix => 1 );
    ok( scalar @issues, '_shell_bootstrap_issues still reports the pre-fix bootstrap drift' );
    ok( $issues[0]{fixed}, '_shell_bootstrap_issues marks the issue fixed after a real rewrite' );
    unlink $bashrc;
}

# ---------------------------------------------------------------------------
# _bashrc_bootstrap_issue returns undef when the guard is absent.
# ---------------------------------------------------------------------------
{
    my $f = write_file( File::Spec->catfile( $home, 'bashrc-noguard' ), "$dashboard_line\n" );
    is( $doctor->_bashrc_bootstrap_issue( path => $f ), undef, '_bashrc_bootstrap_issue returns undef without a non-interactive guard' );
}

# ---------------------------------------------------------------------------
# _bashrc_bootstrap_issue returns undef when no dashboard-managed lines exist.
# ---------------------------------------------------------------------------
{
    my $f = write_file( File::Spec->catfile( $home, 'bashrc-noddlines' ), "# lead\n$guard_line\nexport EDITOR=vim\n" );
    is( $doctor->_bashrc_bootstrap_issue( path => $f ), undef, '_bashrc_bootstrap_issue returns undef when no dashboard lines are present' );
}

# ---------------------------------------------------------------------------
# _bashrc_bootstrap_issue reports an issue when a dashboard line sits after the
# guard, driving the found-position and after-guard branches.
# ---------------------------------------------------------------------------
{
    my $f = write_file( File::Spec->catfile( $home, 'bashrc-after-guard' ), "# lead\n$guard_line\n$dashboard_line\n" );
    my $issue = $doctor->_bashrc_bootstrap_issue( path => $f );
    ok( $issue, '_bashrc_bootstrap_issue reports a dashboard line hidden behind the guard' );
    is( $issue->{kind}, 'shell-bootstrap', '_bashrc_bootstrap_issue tags the shell bootstrap issue kind' );
}

# ---------------------------------------------------------------------------
# _bashrc_bootstrap_issue skips a dashboard line that is not actually present
# in the body (position -1), covering the defensive index guard.
# ---------------------------------------------------------------------------
{
    my $f = write_file( File::Spec->catfile( $home, 'bashrc-phantom' ), "# lead\n$guard_line\nexport EDITOR=vim\n" );
    no warnings 'redefine';
    local *Developer::Dashboard::Doctor::_dashboard_bashrc_lines = sub { return ('export PATH="not-present-in-body:$PATH"') };
    is( $doctor->_bashrc_bootstrap_issue( path => $f ), undef, '_bashrc_bootstrap_issue skips a reported dashboard line that is absent from the body' );
}

# ---------------------------------------------------------------------------
# _bashrc_bootstrap_issue rejects a missing path.
# ---------------------------------------------------------------------------
{
    my $err = eval { $doctor->_bashrc_bootstrap_issue(); 1 } ? '' : $@;
    like( $err, qr/Missing bashrc audit path/, '_bashrc_bootstrap_issue dies without a path' );
}

# ---------------------------------------------------------------------------
# _rewrite_bashrc_dashboard_lines returns early when the guard is absent.
# ---------------------------------------------------------------------------
{
    my $f = write_file( File::Spec->catfile( $home, 'rewrite-noguard' ), "$dashboard_line\n" );
    is( $doctor->_rewrite_bashrc_dashboard_lines($f), undef, '_rewrite_bashrc_dashboard_lines returns when the guard is absent' );
}

# ---------------------------------------------------------------------------
# _rewrite_bashrc_dashboard_lines returns early when there are no dashboard
# lines to move.
# ---------------------------------------------------------------------------
{
    my $f = write_file( File::Spec->catfile( $home, 'rewrite-noddlines' ), "$guard_line\nexport EDITOR=vim\n" );
    is( $doctor->_rewrite_bashrc_dashboard_lines($f), undef, '_rewrite_bashrc_dashboard_lines returns when there are no dashboard lines' );
}

# ---------------------------------------------------------------------------
# _rewrite_bashrc_dashboard_lines with content ahead of the guard preserves the
# leading block while moving the dashboard line ahead of the guard.
# ---------------------------------------------------------------------------
{
    my $f = write_file(
        File::Spec->catfile( $home, 'rewrite-leading' ),
        "# leading comment\nexport EDITOR=vim\n$guard_line\n$dashboard_line\n",
    );
    $doctor->_rewrite_bashrc_dashboard_lines($f);
    my $rewritten = $doctor->_slurp_text_file($f);
    my $guard_pos = index( $rewritten, '[ -z' );
    my $path_pos  = index( $rewritten, 'export PATH=' );
    ok( $path_pos >= 0 && $path_pos < $guard_pos, '_rewrite_bashrc_dashboard_lines moves the dashboard line ahead of the guard while keeping leading content' );
    like( $rewritten, qr/# leading comment/, '_rewrite_bashrc_dashboard_lines preserves the leading content block' );
}

# ---------------------------------------------------------------------------
# _rewrite_bashrc_dashboard_lines with the guard at the very start leaves no
# leading block, exercising the empty-before branch.
# ---------------------------------------------------------------------------
{
    my $f = write_file( File::Spec->catfile( $home, 'rewrite-guard-first' ), "$guard_line\n$dashboard_line\n" );
    $doctor->_rewrite_bashrc_dashboard_lines($f);
    my $rewritten = $doctor->_slurp_text_file($f);
    my $guard_pos = index( $rewritten, '[ -z' );
    my $path_pos  = index( $rewritten, 'export PATH=' );
    ok( $path_pos >= 0 && $path_pos < $guard_pos, '_rewrite_bashrc_dashboard_lines moves the dashboard line ahead of a guard that starts the file' );
}

# ---------------------------------------------------------------------------
# _rewrite_bashrc_dashboard_lines dies when the target cannot be reopened for
# writing. Root bypasses the read-only bit, so only assert as a non-root user.
# ---------------------------------------------------------------------------
SKIP: {
    skip 'read-only write check is meaningless as root', 1 if $> == 0;
    my $f = write_file( File::Spec->catfile( $home, 'rewrite-readonly' ), "$guard_line\n$dashboard_line\n" );
    chmod 0444, $f or die "Unable to chmod $f: $!";
    my $err = eval { $doctor->_rewrite_bashrc_dashboard_lines($f); 1 } ? '' : $@;
    like( $err, qr/Unable to write/, '_rewrite_bashrc_dashboard_lines dies when the bashrc cannot be reopened for writing' );
    chmod 0644, $f or die "Unable to restore $f: $!";
}

# ---------------------------------------------------------------------------
# _dashboard_bashrc_lines tolerates an undef body and extracts lines from text.
# ---------------------------------------------------------------------------
{
    is_deeply( [ $doctor->_dashboard_bashrc_lines(undef) ], [], '_dashboard_bashrc_lines returns no lines for undef text' );
    my @lines = $doctor->_dashboard_bashrc_lines("# lead\n$dashboard_line\nexport EDITOR=vim\n");
    is_deeply( \@lines, [$dashboard_line], '_dashboard_bashrc_lines extracts dashboard-managed lines from a body' );
}

# ---------------------------------------------------------------------------
# _is_dashboard_bashrc_line recognizes the managed bootstrap lines and rejects
# blank, undef, and unrelated lines.
# ---------------------------------------------------------------------------
{
    is( $doctor->_is_dashboard_bashrc_line(undef), 0, '_is_dashboard_bashrc_line rejects an undef line' );
    is( $doctor->_is_dashboard_bashrc_line(q{}),   0, '_is_dashboard_bashrc_line rejects an empty line' );
    is( $doctor->_is_dashboard_bashrc_line('export EDITOR=vim'), 0, '_is_dashboard_bashrc_line rejects an unrelated export line' );
    is( $doctor->_is_dashboard_bashrc_line('export PERLBREW_HOME="/home/x/perl5/perlbrew"'), 1, '_is_dashboard_bashrc_line recognizes the PERLBREW_HOME line' );
    is( $doctor->_is_dashboard_bashrc_line($dashboard_line), 1, '_is_dashboard_bashrc_line recognizes the perlbrew PATH line' );
}

# ---------------------------------------------------------------------------
# _bash_noninteractive_guard_offsets tolerates undef and unmatched text.
# ---------------------------------------------------------------------------
{
    is_deeply( [ $doctor->_bash_noninteractive_guard_offsets(undef) ], [ undef, undef ], '_bash_noninteractive_guard_offsets returns undef offsets for undef text' );
    is_deeply( [ $doctor->_bash_noninteractive_guard_offsets("export EDITOR=vim\n") ], [ undef, undef ], '_bash_noninteractive_guard_offsets returns undef offsets when no guard matches' );
    my ( $start, $end ) = $doctor->_bash_noninteractive_guard_offsets("# lead\n$guard_line\n");
    ok( defined $start && defined $end, '_bash_noninteractive_guard_offsets returns real offsets when the guard matches' );
}

# ---------------------------------------------------------------------------
# _slurp_text_file dies on an unreadable path and returns an empty string body
# for an empty file (the defined-empty ternary path).
# ---------------------------------------------------------------------------
{
    my $missing = File::Spec->catfile( $home, 'no-such-dir', 'no-such-file' );
    my $err = eval { $doctor->_slurp_text_file($missing); 1 } ? '' : $@;
    like( $err, qr/Unable to read/, '_slurp_text_file dies when the file cannot be opened for reading' );

    my $empty = write_file( File::Spec->catfile( $home, 'slurp-empty' ), q{} );
    is( $doctor->_slurp_text_file($empty), q{}, '_slurp_text_file returns an empty string for an empty file' );
}

done_testing;

__END__

=head1 NAME

t/78-doctor-coverage.t - branch and condition coverage for the runtime doctor

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::Doctor>. It drives the doctor's permission audit,
managed-helper drift audit, shell-bootstrap audit, and their repair paths so
every reachable branch and condition in the module is exercised, while the
genuinely unreachable file-system failure sides stay annotated in the module
itself.

=head1 WHY IT EXISTS

The doctor is mostly defensive plumbing: guards for missing arguments, empty
inputs, absent guards, duplicate roots, and file-system errors. Those branches
are hard to reach from the higher-level C<dashboard doctor> command, so a
dedicated test builds the exact fixtures - unreadable files, read-only
rewrites, empty helper bodies, injected roots, and passing/failing hook
payloads - that make each side execute. Keeping them here stops the module's
100% branch and condition coverage from silently regressing.

=head1 WHEN TO USE

Use this file when changing the runtime permission policy, the managed-helper
drift audit, the bash bootstrap rewrite, the doctor report shape, or the set of
roots that C<dashboard doctor> audits and repairs.

=head1 HOW TO USE

Run C<prove -lv t/78-doctor-coverage.t> while iterating on the module, then
confirm branch and condition coverage with
C<HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t> and keep the whole suite
green before release. The two file-permission assertions self-skip when run as
root, where the read/write bits do not bite.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the Devel::Cover gate
all rely on this file to keep the doctor's defensive branches honest.

=head1 EXAMPLES

Example 1:

  prove -lv t/78-doctor-coverage.t

Run the focused doctor coverage test by itself while changing the module.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/78-doctor-coverage.t

Exercise the same test while collecting coverage for the doctor module.

Example 3:

  prove -lr t

Put the change back through the entire repository suite before release.

=cut
