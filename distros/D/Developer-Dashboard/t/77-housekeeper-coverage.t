#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir tempfile);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Config;
use Developer::Dashboard::Collector;
use Developer::Dashboard::Housekeeper;

# Hermetic runtime rooted entirely under a throwaway HOME with a dedicated
# temp-state root, and the CWD moved inside it so config-layer discovery only
# ever sees this sandbox.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

my $is_root = ( $> == 0 );

# ---------------------------------------------------------------------------
# run(): default min_age_seconds versus an explicit override.
# ---------------------------------------------------------------------------
{
    my $keeper   = Developer::Dashboard::Housekeeper->new( paths => $paths );
    my $scan_tmp = tempdir( CLEANUP => 1 );

    my ( $default_run, $explicit_run );
    {
        no warnings qw(redefine once);
        local *File::Spec::tmpdir = sub { return $scan_tmp };
        $default_run  = $keeper->run;
        $explicit_run = $keeper->run( min_age_seconds => 0 );
    }
    is( $default_run->{min_age_seconds}, 3600, 'run defaults min_age_seconds to 3600 when the caller omits it' );
    is( $explicit_run->{min_age_seconds}, 0, 'run honours an explicit min_age_seconds override' );
    is( $default_run->{ok}, 1, 'run reports success for the default sweep over an empty sandbox' );
}

# ---------------------------------------------------------------------------
# _rotate_collector_logs(): falsy collectors list, non-hash and unnamed jobs,
# and rotation results that are present versus absent.
# ---------------------------------------------------------------------------
{
    my $empty_keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );
    $empty_keeper->{config} = Local::HKConfig->new(undef);
    my @none = $empty_keeper->_rotate_collector_logs( scanned => { collector_logs => 0 } );
    is( scalar @none, 0, '_rotate_collector_logs treats a false collectors list as an empty iteration' );

    my $mixed_keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );
    $mixed_keeper->{config} = Local::HKConfig->new(
        [
            'not-a-hash-job',
            {},
            { name => 'has_result', rotation => { lines => 1 } },
            { name => 'no_result',  rotation => { lines => 1 } },
        ]
    );
    $mixed_keeper->{collector_store} = Local::HKStore->new;
    my $scanned = { collector_logs => 0 };
    my @rotated = $mixed_keeper->_rotate_collector_logs( scanned => $scanned, now_epoch => 1_700_000_000 );
    is( scalar @rotated, 1, '_rotate_collector_logs collects only the jobs whose rotation returns a result' );
    is( $rotated[0]{name}, 'has_result', '_rotate_collector_logs keeps the rotation payload for a producing collector' );
    is( $scanned->{collector_logs}, 2, '_rotate_collector_logs scans both named collectors that declared rotation rules' );
}

# ---------------------------------------------------------------------------
# _cleanup_state_roots(): a missing base short-circuits, and a real base with a
# non-directory entry is skipped while active/stale directories are handled.
# ---------------------------------------------------------------------------
{
    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::PathRegistry::state_base_root = sub {
            return File::Spec->catdir( $home, 'no-such-state-base' );
        };
        my @removed = $keeper->_cleanup_state_roots(
            min_age_seconds => 0,
            scanned         => { state_roots => 0 },
        );
        is( scalar @removed, 0, '_cleanup_state_roots returns nothing when the state base directory is absent' );
    }

    my $state_base = $paths->state_base_root;
    my $plain_entry = File::Spec->catfile( $state_base, 'plain-entry-not-a-dir' );
    open my $plain_fh, '>', $plain_entry or die "Unable to write $plain_entry: $!";
    print {$plain_fh} "not a state root";
    close $plain_fh or die "Unable to close $plain_entry: $!";

    my $stale_dir = File::Spec->catdir( $state_base, 'stale-no-metadata' );
    make_path($stale_dir);
    utime time - 7200, time - 7200, $stale_dir or die "Unable to age $stale_dir: $!";

    my $scanned = { state_roots => 0 };
    my @removed = $keeper->_cleanup_state_roots( min_age_seconds => 60, scanned => $scanned );
    ok( -e $plain_entry, '_cleanup_state_roots leaves non-directory entries in the state base untouched' );
    ok( !-d $stale_dir, '_cleanup_state_roots removes an aged state root that carries no runtime metadata' );
    ok( $scanned->{state_roots} >= 1, '_cleanup_state_roots counts the directory entries it scans' );
}

# ---------------------------------------------------------------------------
# _cleanup_temp_files(): non-file candidates, fresh candidates, and successful
# removals all in one clean temp directory.
# ---------------------------------------------------------------------------
{
    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );
    my $tmp    = tempdir( CLEANUP => 1 );

    my $aged_ajax = File::Spec->catfile( $tmp, 'developer-dashboard-ajax-aged' );
    _write_file( $aged_ajax, 'aged ajax payload' );
    utime time - 7200, time - 7200, $aged_ajax or die "Unable to age $aged_ajax: $!";

    my $aged_result = File::Spec->catfile( $tmp, 'dashboard-result-aged' );
    _write_file( $aged_result, 'aged result payload' );
    utime time - 7200, time - 7200, $aged_result or die "Unable to age $aged_result: $!";

    my $fresh_ajax = File::Spec->catfile( $tmp, 'developer-dashboard-ajax-fresh' );
    _write_file( $fresh_ajax, 'fresh ajax payload' );

    my $ajax_dir = File::Spec->catdir( $tmp, 'developer-dashboard-ajax-dir' );
    make_path($ajax_dir);

    my @removed;
    {
        no warnings qw(redefine once);
        local *File::Spec::tmpdir = sub { return $tmp };
        @removed = $keeper->_cleanup_temp_files(
            min_age_seconds => 3600,
            scanned         => { ajax_temp_files => 0, result_temp_files => 0 },
        );
    }
    ok( !-e $aged_ajax,   '_cleanup_temp_files removes an aged ajax temp file' );
    ok( !-e $aged_result, '_cleanup_temp_files removes an aged runtime result temp file' );
    ok( -e $fresh_ajax,   '_cleanup_temp_files keeps a candidate that is not yet old enough' );
    ok( -d $ajax_dir,     '_cleanup_temp_files skips glob matches that are not plain files' );
    is( scalar @removed, 2, '_cleanup_temp_files reports exactly the two aged files it removed' );
}

# ---------------------------------------------------------------------------
# _cleanup_temp_files(): unlink failures for both temp-file kinds must die with
# the kind-specific label. Only reachable as a non-root user.
# ---------------------------------------------------------------------------
{
    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );

    my $ajax_tmp   = tempdir( CLEANUP => 1 );
    my $ajax_stuck = File::Spec->catfile( $ajax_tmp, 'developer-dashboard-ajax-stuck' );
    _write_file( $ajax_stuck, 'stuck ajax' );
    utime time - 7200, time - 7200, $ajax_stuck or die "Unable to age $ajax_stuck: $!";

    my $result_tmp   = tempdir( CLEANUP => 1 );
    my $result_stuck = File::Spec->catfile( $result_tmp, 'dashboard-result-stuck' );
    _write_file( $result_stuck, 'stuck result' );
    utime time - 7200, time - 7200, $result_stuck or die "Unable to age $result_stuck: $!";

    if ($is_root) {
        pass('_cleanup_temp_files unlink-failure ajax branch is skipped under root');
        pass('_cleanup_temp_files unlink-failure result branch is skipped under root');
    }
    else {
        chmod 0555, $ajax_tmp or die "Unable to chmod $ajax_tmp: $!";
        my $ajax_error = _capture_die(
            sub {
                no warnings qw(redefine once);
                local *File::Spec::tmpdir = sub { return $ajax_tmp };
                $keeper->_cleanup_temp_files(
                    min_age_seconds => 0,
                    scanned         => { ajax_temp_files => 0, result_temp_files => 0 },
                );
            }
        );
        chmod 0700, $ajax_tmp or die "Unable to restore $ajax_tmp: $!";
        like( $ajax_error, qr/Unable to remove stale Ajax temp file/, '_cleanup_temp_files dies with the ajax label when an aged ajax file cannot be unlinked' );

        chmod 0555, $result_tmp or die "Unable to chmod $result_tmp: $!";
        my $result_error = _capture_die(
            sub {
                no warnings qw(redefine once);
                local *File::Spec::tmpdir = sub { return $result_tmp };
                $keeper->_cleanup_temp_files(
                    min_age_seconds => 0,
                    scanned         => { ajax_temp_files => 0, result_temp_files => 0 },
                );
            }
        );
        chmod 0700, $result_tmp or die "Unable to restore $result_tmp: $!";
        like( $result_error, qr/Unable to remove stale runtime result temp file/, '_cleanup_temp_files dies with the runtime-result label when an aged result file cannot be unlinked' );
    }
}

# ---------------------------------------------------------------------------
# _state_root_has_live_collectors(): a live pidfile, and a mixture of skipped,
# empty, non-numeric and dead pidfiles that all resolve to "no live collector".
# ---------------------------------------------------------------------------
{
    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );

    my $live_root = File::Spec->catdir( $home, 'live-root' );
    make_path( File::Spec->catdir( $live_root, 'collectors' ) );
    _write_file( File::Spec->catfile( $live_root, 'collectors', 'live.pid' ), "$$\n" );
    ok( $keeper->_state_root_has_live_collectors($live_root), '_state_root_has_live_collectors returns true when a pidfile points at a live process' );

    my $dead_pid = fork();
    die "fork failed: $!" if !defined $dead_pid;
    if ( !$dead_pid ) { exit 0 }
    waitpid( $dead_pid, 0 );

    my $mixed_root = File::Spec->catdir( $home, 'mixed-root' );
    my $mixed_collectors = File::Spec->catdir( $mixed_root, 'collectors' );
    make_path($mixed_collectors);
    make_path( File::Spec->catdir( $mixed_collectors, 'skip.pid' ) );          # a directory, not a file
    _write_file( File::Spec->catfile( $mixed_collectors, 'empty.pid' ), '' );  # empty -> undef pid
    _write_file( File::Spec->catfile( $mixed_collectors, 'bad.pid' ), "abc\n" );
    _write_file( File::Spec->catfile( $mixed_collectors, 'dead.pid' ), "$dead_pid\n" );
    ok( !$keeper->_state_root_has_live_collectors($mixed_root), '_state_root_has_live_collectors returns false when no pidfile resolves to a live process' );
}

# ---------------------------------------------------------------------------
# _state_root_has_live_collectors(): unreadable collectors directory and an
# unreadable pidfile both surface explicit read failures. Non-root only.
# ---------------------------------------------------------------------------
{
    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );

    my $opendir_root = File::Spec->catdir( $home, 'opendir-fail-root' );
    my $opendir_collectors = File::Spec->catdir( $opendir_root, 'collectors' );
    make_path($opendir_collectors);

    my $open_root = File::Spec->catdir( $home, 'open-fail-root' );
    my $open_collectors = File::Spec->catdir( $open_root, 'collectors' );
    make_path($open_collectors);
    my $unreadable_pid = File::Spec->catfile( $open_collectors, 'locked.pid' );
    _write_file( $unreadable_pid, "12345\n" );

    if ($is_root) {
        pass('_state_root_has_live_collectors opendir failure branch is skipped under root');
        pass('_state_root_has_live_collectors pidfile read failure branch is skipped under root');
    }
    else {
        chmod 0100, $opendir_collectors or die "Unable to chmod $opendir_collectors: $!";
        my $opendir_error = _capture_die( sub { $keeper->_state_root_has_live_collectors($opendir_root) } );
        chmod 0700, $opendir_collectors or die "Unable to restore $opendir_collectors: $!";
        like( $opendir_error, qr/Unable to read .*collectors/, '_state_root_has_live_collectors dies when the collectors directory cannot be opened' );

        chmod 0000, $unreadable_pid or die "Unable to chmod $unreadable_pid: $!";
        my $open_error = _capture_die( sub { $keeper->_state_root_has_live_collectors($open_root) } );
        chmod 0600, $unreadable_pid or die "Unable to restore $unreadable_pid: $!";
        like( $open_error, qr/Unable to read .*locked\.pid/, '_state_root_has_live_collectors dies when a pidfile cannot be read' );
    }
}

# ---------------------------------------------------------------------------
# _read_state_metadata(): a readable metadata file returns its hash, an
# unreadable one dies. Non-root only for the failure path.
# ---------------------------------------------------------------------------
{
    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );

    my $ok_dir = File::Spec->catdir( $home, 'metadata-ok' );
    make_path($ok_dir);
    _write_file( File::Spec->catfile( $ok_dir, 'runtime.json' ), '{"runtime_root":"/somewhere"}' );
    my $metadata = $keeper->_read_state_metadata($ok_dir);
    is( ref $metadata, 'HASH', '_read_state_metadata returns the decoded metadata hash for a readable file' );
    is( $metadata->{runtime_root}, '/somewhere', '_read_state_metadata preserves the recorded runtime root' );

    my $locked_dir = File::Spec->catdir( $home, 'metadata-locked' );
    make_path($locked_dir);
    my $locked_meta = File::Spec->catfile( $locked_dir, 'runtime.json' );
    _write_file( $locked_meta, '{"runtime_root":"/blocked"}' );

    if ($is_root) {
        pass('_read_state_metadata read failure branch is skipped under root');
    }
    else {
        chmod 0000, $locked_meta or die "Unable to chmod $locked_meta: $!";
        my $error = _capture_die( sub { $keeper->_read_state_metadata($locked_dir) } );
        chmod 0600, $locked_meta or die "Unable to restore $locked_meta: $!";
        like( $error, qr/Unable to read .*runtime\.json/, '_read_state_metadata dies when the metadata file cannot be read' );
    }
}

# ---------------------------------------------------------------------------
# _only_missing_tree_errors(): every branch of the classification logic.
# ---------------------------------------------------------------------------
{
    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );
    ok( $keeper->_only_missing_tree_errors(undef), '_only_missing_tree_errors treats a non-array error value as benign' );
    ok( $keeper->_only_missing_tree_errors( [] ), '_only_missing_tree_errors treats an empty error array as benign' );
    ok( !$keeper->_only_missing_tree_errors( [undef] ), '_only_missing_tree_errors rejects an error entry that carries no message' );
    ok(
        $keeper->_only_missing_tree_errors( [ { '/gone' => 'No such file or directory' } ] ),
        '_only_missing_tree_errors accepts pure ENOENT removal races',
    );
    ok(
        !$keeper->_only_missing_tree_errors( [ { '/nope' => 'Permission denied' } ] ),
        '_only_missing_tree_errors rejects a non-ENOENT removal failure',
    );
}

# ---------------------------------------------------------------------------
# _remove_tree(): a real success, a benign ENOENT-only failure that is
# tolerated, and a genuine failure that dies.
# ---------------------------------------------------------------------------
{
    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );

    my $target = File::Spec->catdir( $home, 'remove-me' );
    make_path($target);
    is_deeply(
        $keeper->_remove_tree( $target, 'state-root' ),
        { kind => 'state-root', path => $target },
        '_remove_tree returns a summary payload for a successful removal',
    );

    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::Housekeeper::remove_tree = sub {
            my ( $path, $opts ) = @_;
            ${ $opts->{error} } = [ { $path => 'No such file or directory' } ];
            return 0;
        };
        is_deeply(
            $keeper->_remove_tree( File::Spec->catdir( $home, 'raced' ), 'state-root' ),
            { kind => 'state-root', path => File::Spec->catdir( $home, 'raced' ) },
            '_remove_tree tolerates an ENOENT-only removal race and still returns a payload',
        );
    }

    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::Housekeeper::remove_tree = sub {
            my ( $path, $opts ) = @_;
            ${ $opts->{error} } = [ { $path => 'Permission denied' } ];
            return 0;
        };
        my $error = _capture_die( sub { $keeper->_remove_tree( File::Spec->catdir( $home, 'blocked' ), 'state-root' ) } );
        like( $error, qr/Unable to remove stale state-root/, '_remove_tree dies when remove_tree reports a non-ENOENT failure' );
    }
}

# ---------------------------------------------------------------------------
# Lazy accessors construct their helper on first use and cache it afterwards.
# ---------------------------------------------------------------------------
{
    my $store_keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );
    my $store_first  = $store_keeper->_collector_store;
    isa_ok( $store_first, 'Developer::Dashboard::Collector', '_collector_store constructs a collector store on first use' );
    is( $store_keeper->_collector_store, $store_first, '_collector_store caches the constructed collector store' );

    my $config_keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );
    my $config_first  = $config_keeper->_config;
    isa_ok( $config_first, 'Developer::Dashboard::Config', '_config constructs a config loader on first use' );
    is( $config_keeper->_config, $config_first, '_config caches the constructed config loader' );
}

done_testing;

# _write_file($path, $content)
# Writes a small fixture file for the housekeeper coverage scenarios.
# Input: destination path string and content string.
# Output: nothing; dies on any I/O failure.
sub _write_file {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return;
}

# _capture_die($code)
# Runs a coderef and returns the exception it raised, or the empty string.
# Input: coderef expected to die.
# Output: exception string ($@) or ''.
sub _capture_die {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : $@;
}

{
    package Local::HKConfig;

    # new($collectors)
    # Builds a stand-in config whose collector list is fully controlled.
    # Input: collectors value (array reference, undef, or any scalar).
    # Output: blessed Local::HKConfig instance.
    sub new { my ( $class, $collectors ) = @_; return bless { collectors => $collectors }, $class; }

    # collectors()
    # Returns the injected collector list verbatim.
    # Input: none.
    # Output: the stored collectors value.
    sub collectors { return $_[0]->{collectors}; }
}

{
    package Local::HKStore;

    # new()
    # Builds a stand-in collector store for rotation-result coverage.
    # Input: none.
    # Output: blessed Local::HKStore instance.
    sub new { return bless {}, shift; }

    # rotate_log($name, $rotation, %args)
    # Returns a rotation payload only for the collector named has_result.
    # Input: collector name, rotation hash reference, and passthrough args.
    # Output: rotation payload hash reference, or nothing.
    sub rotate_log {
        my ( $self, $name, $rotation, %args ) = @_;
        return { kind => 'collector-log-rotation', name => $name } if $name eq 'has_result';
        return;
    }
}

__END__

=pod

=head1 NAME

t/77-housekeeper-coverage.t - branch and condition coverage closure for the temp-state housekeeper

=head1 PURPOSE

This test drives the remaining branch and condition edges of
C<Developer::Dashboard::Housekeeper> that the higher-level command and
collector flows never reach: the default retention window, collector-log
rotation over malformed job lists, stale state-root scanning, dashboard-owned
temp-file cleanup, live-collector pidfile inspection, runtime metadata reads,
removal-error classification, and the lazily constructed collector/config
helpers.

=head1 WHY IT EXISTS

The housekeeper is the only runtime component that deletes files from the
shared temp area, so each of its guard clauses is a safety boundary: skipping
non-directory entries, refusing to treat a non-ENOENT removal failure as
benign, and dying loudly when a pidfile or metadata file it expected to read
cannot be opened. Those edges are easy to regress and impossible to observe
from a green end-to-end run, so they need direct, deterministic exercise with
crafted directory trees, permission-tightened files, and injected config and
storage doubles.

=head1 WHEN TO USE

Use this file when changing the housekeeper's retention defaults, its
state-root staleness rules, its temp-file cleanup patterns, its collector-log
rotation wiring, or the private helpers that read pidfiles and runtime
metadata.

=head1 HOW TO USE

Run C<prove -lv t/77-housekeeper-coverage.t> while iterating, and include it in
the coverage gate run so the housekeeper stays at full branch and condition
coverage. The permission-dependent failure paths only execute as a non-root
user; under root those assertions self-skip with a passing note.

=head1 WHAT USES IT

The repository test suite, the TDD loop for housekeeper changes, and the
Devel::Cover branch/condition gate all rely on this file to keep the cleanup
service's guard clauses honest.

=head1 EXAMPLES

Example 1:

  prove -lv t/77-housekeeper-coverage.t

Run the housekeeper coverage closure test on its own while changing the module.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Run it inside the full suite while collecting the coverage the gate checks.

=cut
