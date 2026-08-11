#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Capture::Tiny qw(capture);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::UpdateManager;

# Hermetic runtime rooted at a temp HOME that is also the CWD, so the config
# layer stack resolves from the deepest .developer-dashboard directory below it
# and no user state can leak into the update-manager assertions.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths     = Developer::Dashboard::PathRegistry->new( home => $home );
my $files     = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config    = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $collector = Developer::Dashboard::Collector->new( paths => $paths );
my $runner    = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector,
    files      => $files,
    paths      => $paths,
);
my $updater = Developer::Dashboard::UpdateManager->new(
    config => $config,
    files  => $files,
    paths  => $paths,
    runner => $runner,
);

# --- _is_supported_update_script guard: the "!defined $path || $path eq ''" OR
# condition and its early-return branch. An undef path drives the left-true
# short-circuit; an empty-string path drives the left-false/right-true side. The
# valid-path side (both operands false) is already exercised by the wider suite.
is(
    $updater->_is_supported_update_script(undef),
    0,
    'an undefined update path is rejected, driving the left-true short-circuit of the guard condition',
);
is(
    $updater->_is_supported_update_script(''),
    0,
    'an empty-string update path is rejected, driving the left-false/right-true side of the guard condition',
);

# --- _is_supported_update_script runnable-file probe (the is_runnable_file
# ternary). A file whose name carries no recognised script extension bypasses the
# .pl and shell-script fast paths and only reaches the runnable-file probe, so an
# executable one must return true and a non-executable one must return false.
my $exec_no_ext = File::Spec->catfile( $home, 'runme' );
open my $exec_fh, '>', $exec_no_ext or die "Unable to write $exec_no_ext: $!";
print {$exec_fh} "#!/bin/sh\nexit 0\n";
close $exec_fh;
chmod 0755, $exec_no_ext or die "Unable to chmod $exec_no_ext: $!";
is(
    $updater->_is_supported_update_script($exec_no_ext),
    1,
    'an executable extensionless update file is supported through the runnable-file probe',
);

my $plain_no_run = File::Spec->catfile( $home, 'notes.txt' );
open my $plain_fh, '>', $plain_no_run or die "Unable to write $plain_no_run: $!";
print {$plain_fh} "just data, not runnable\n";
close $plain_fh;
chmod 0644, $plain_no_run or die "Unable to chmod $plain_no_run: $!";
is(
    $updater->_is_supported_update_script($plain_no_run),
    0,
    'a non-executable, non-script update file is not supported by the runnable-file probe',
);

# --- run(): the "opendir ... or die" failure side. updates_dir() resolves to
# <cwd>/updates; a directory that exists (so the -d guard passes) but is
# unreadable makes opendir fail for a non-root user, exercising the die branch.
my $updates_dir = $updater->updates_dir;
make_path($updates_dir) if !-d $updates_dir;
chmod 0000, $updates_dir or die "Unable to chmod $updates_dir: $!";
my $run_error = eval { $updater->run; 1 } ? '' : $@;
# Restore read access before asserting so cleanup and any later logic are safe
# regardless of the assertion outcome.
chmod 0755, $updates_dir or die "Unable to restore $updates_dir: $!";
like(
    $run_error,
    qr/Unable to open updates directory/,
    'run() dies when the updates directory exists but cannot be opened',
);

# --- run(): an update script that emits output. The output-print guard only
# fires when a script actually writes to stdout or stderr, and every other
# suite scenario runs silent scripts, so the printing side of the guard and the
# script-output round-trip into the result record are pinned here. (The
# defined-ness side of that guard is annotated uncoverable in the module
# because the stdout/stderr concatenation is always defined.) With no
# collectors running, the same call also drives run() into its
# nothing-to-restart hand-off.
my $noisy = File::Spec->catfile( $updates_dir, '10-noisy.sh' );
open my $noisy_fh, '>', $noisy or die "Unable to write $noisy: $!";
print {$noisy_fh} "#!/bin/sh\necho update-output-marker-stdout\necho update-output-marker-stderr >&2\nexit 0\n";
close $noisy_fh or die "Unable to close $noisy: $!";
chmod 0755, $noisy or die "Unable to chmod $noisy: $!";

my ( $run_stdout, $run_stderr, $run_results ) = capture { $updater->run };
like(
    $run_stdout,
    qr/update-output-marker-stdout/,
    'run() prints the captured update script stdout when the script produces output',
);
like(
    $run_stdout,
    qr/update-output-marker-stderr/,
    'run() folds the captured update script stderr into the printed output',
);
is( $run_stderr, '', 'run() writes nothing to stderr for a clean noisy script' );
is( scalar @{$run_results}, 1, 'run() records one result for the single update script' );
is( $run_results->[0]{exit_code}, 0, 'the noisy update script exits cleanly' );
like(
    $run_results->[0]{output},
    qr/update-output-marker-stdout/,
    'the result record carries the script output',
);

# --- _restart_collectors with nothing to restart: the early-return no-op.
# run() only reaches _restart_collectors with whatever collectors were running
# when the update started, so the empty-list case is pinned by direct call
# rather than left to incidental execution: it must return immediately without
# touching the runner or the collector config.
is_deeply(
    [ $updater->_restart_collectors ],
    [],
    '_restart_collectors returns immediately when no collector names are given',
);

done_testing;

__END__

=pod

=head1 NAME

t/62-updatemanager-coverage.t - branch and condition coverage closure for the update manager

=head1 PURPOSE

This test is the executable coverage contract for the update manager's guard
logic. It drives the small number of branch and condition outcomes in update
script classification and update execution that the higher-level update and CLI
tests never reach: the empty and undefined update-path rejections, the
extensionless runnable-file probe on both its true and false outcomes, the
error path taken when the updates directory exists but cannot be opened, the
output-printing side of the run cycle (a script that writes to stdout and
stderr must have that output printed and recorded in its result entry), and
the nothing-to-restart no-op of the collector restart hand-off.

=head1 WHY IT EXISTS

It exists because the update manager decides which files count as runnable
update scripts and coordinates directory scanning around collector shutdown, and
several of those decisions are one-line guards whose failure side is only
reachable with deliberately shaped input. Without this file those guard sides
sit uncovered, so a future refactor could silently invert a rejection or drop
the unreadable-directory failure without any test noticing. Keeping the missing
outcomes in a dedicated file makes the coverage gate honest rather than
depending on incidental execution from unrelated update tests.

=head1 WHEN TO USE

Use this file when changing update script classification, the runnable-file
probe used to decide whether an extensionless update file should run, or the
directory-scanning and error handling in the update manager's run cycle. If the
coverage gate reports an uncovered branch or condition in the update manager,
start here.

=head1 HOW TO USE

Run C<prove -lv t/62-updatemanager-coverage.t> while iterating on update-manager
guard logic, then keep it green under C<prove -lr t> and the coverage runs
before release. The test builds a fully hermetic runtime under a temporary HOME
so it needs no repository checkout state to pass.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the branch and condition
coverage gate all rely on this file to keep the update manager's guard outcomes
exercised end to end.

=head1 EXAMPLES

Example 1:

  prove -lv t/62-updatemanager-coverage.t

Run the dedicated update-manager coverage closure test by itself while changing
the behavior it protects.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
