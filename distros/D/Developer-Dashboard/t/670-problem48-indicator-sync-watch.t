use strict;
use warnings;

use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin;
use Test::More;

our $P48_WATCH_OPENDIR_CALLS = 0;
BEGIN {
    no warnings qw(redefine once);
    *CORE::GLOBAL::opendir = sub (*$) {
        $main::P48_WATCH_OPENDIR_CALLS++;
        return CORE::opendir( $_[0], $_[1] );
    };
}

my $repo_root = File::Spec->catdir( $FindBin::Bin, '..' );
require lib;
lib->import( File::Spec->catdir( $repo_root, 'lib' ) );
require Developer::Dashboard::IndicatorStore;
require Developer::Dashboard::PathRegistry;

for my $inventory_matches ( 0, 1 ) {
    for my $file_changed ( 0, 1 ) {
        for my $all_active_present ( 0, 1 ) {
            my $expected = $inventory_matches && !$file_changed && $all_active_present ? 1 : 0;
            is(
                Developer::Dashboard::IndicatorStore::_collector_inventory_is_unchanged(
                    $inventory_matches, $file_changed, $all_active_present,
                ),
                $expected,
                "collector inventory unchanged predicate: inventory=$inventory_matches file_changed=$file_changed active=$all_active_present",
            );
        }
    }
}

local $ENV{HOME} = tempdir( CLEANUP => 1 );
chdir $ENV{HOME} or die "Unable to enter test HOME '$ENV{HOME}': $!\n";
my $paths = Developer::Dashboard::PathRegistry->new;
my $store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $watcher = Local::Problem48Watcher->new;
$store->{_indicator_sync_watcher} = $watcher;
my @jobs = map {
    {
        name      => "watch-sync-$_",
        cwd       => 'home',
        code      => 'return 0;',
        indicator => { name => "watch-sync-$_", icon => 'x', priority => $_ },
    }
} 1 .. 8;

my $first = $store->sync_collectors( \@jobs, return_indicators => 1 );
is( scalar @{ $first->{indicators} }, 8, 'initial collector sync writes the inventory' );
is( $watcher->{configure_calls}, 1,
    'initial full sync installs a watch set for the validated inventory' );
my @indicator_roots = $paths->indicators_roots;
ok( grep( { $_ eq $indicator_roots[0] } @{ $watcher->{paths} } ),
    'watch set includes the indicator root directory' );

my $signature_calls = 0;
my $original_signature = \&Developer::Dashboard::IndicatorStore::_indicator_file_signature;
my $opendir_before = $P48_WATCH_OPENDIR_CALLS;
my $stable;
{
    no warnings 'redefine';
    local *Developer::Dashboard::IndicatorStore::_indicator_file_signature = sub {
        $signature_calls++;
        return $original_signature->(@_);
    };
    $stable = $store->sync_collectors(
        \@jobs,
        return_indicators            => 1,
        return_unchanged              => 1,
        skip_indicators_if_unchanged  => 1,
    );
}
is( $stable->{unchanged}, 1, 'an event-free watch set validates a stable sync' );
ok( !exists $stable->{indicators}, 'stable metadata-only result omits duplicate inventory data' );
is( $signature_calls, 0, 'stable watcher fast path skips per-file metadata stats' );
is( $P48_WATCH_OPENDIR_CALLS, $opendir_before,
    'stable watcher fast path skips directory enumeration' );

my $changed_name = 'watch-sync-3';
$store->set_indicator( $changed_name, status => 'fresh', icon => 'x', priority => 3 );
$watcher->signal_event;
$opendir_before = $P48_WATCH_OPENDIR_CALLS;
my $changed = $store->sync_collectors(
    \@jobs,
    return_indicators            => 1,
    return_unchanged              => 1,
    skip_indicators_if_unchanged  => 1,
);
ok( !$changed->{unchanged}, 'a queued event returns to the complete sync path' );
ok( $P48_WATCH_OPENDIR_CALLS > $opendir_before,
    'event invalidation performs a fresh directory inventory check' );
my ($changed_item) = grep { $_->{name} eq $changed_name } @{ $changed->{indicators} || [] };
is( $changed_item->{status}, 'fresh', 'event invalidation exposes the external status update' );

my $new_indicator = $store->set_indicator( 'watch-sync-manual', status => 'ok', icon => 'x' );
$watcher->signal_event;
my $inventory_change = $store->sync_collectors(
    \@jobs,
    return_indicators            => 1,
    return_unchanged              => 1,
    skip_indicators_if_unchanged  => 1,
);
ok( !$inventory_change->{unchanged}, 'directory creation event leaves the cached inventory path' );
ok( grep( { $_->{name} eq $new_indicator->{name} } @{ $inventory_change->{indicators} } ),
    'full reconciliation includes a newly created indicator directory' );
ok( $watcher->{configure_calls} >= 2,
    'reconciliation refreshes the watcher after filesystem inventory changes' );

my $missing_status_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my @missing_status_jobs = ({
    name      => 'watch-missing-status',
    cwd       => 'home',
    code      => 'return 0;',
    indicator => { name => 'watch-missing-status', icon => 'x', priority => 1 },
});
my $seeded_missing_status = $missing_status_store->sync_collectors(
    \@missing_status_jobs,
    return_indicators => 1,
);
my ($seeded_missing_item) = grep { $_->{name} eq 'watch-missing-status' }
  @{ $seeded_missing_status->{indicators} };
ok( $seeded_missing_item, 'separate inventory fixture seeds its configured indicator' );
my $stable_missing_status = $missing_status_store->sync_collectors(
    \@missing_status_jobs,
    return_indicators => 1,
    return_unchanged  => 1,
);
ok( $stable_missing_status->{unchanged},
    'stable collector inventory with all active indicators present takes the unchanged path' );
my @missing_status_roots = $paths->indicators_roots;
my $missing_status_root = $missing_status_roots[0];
my $missing_status_dir = File::Spec->catdir( $missing_status_root, 'watch-missing-status' );
my $missing_status_file = File::Spec->catfile( $missing_status_dir, 'status.json' );
unlink $missing_status_file or die "Unable to remove test indicator file '$missing_status_file': $!\n";
ok( -d $missing_status_dir, 'missing-status fixture preserves the inventoried indicator directory' );
my $repaired_missing_status = $missing_status_store->sync_collectors(
    \@missing_status_jobs,
    return_indicators => 1,
    return_unchanged  => 1,
);
ok( !$repaired_missing_status->{unchanged},
    'an inventoried active indicator with a missing status file is not classified as unchanged' );
ok( -f $missing_status_file,
    'collector synchronization recreates the missing status file without changing directory inventory' );
ok(
    ( grep { $_->{name} eq 'watch-missing-status' } @{ $repaired_missing_status->{indicators} || [] } ),
    'repaired synchronization returns the recreated active indicator',
);

my $failed_watcher = Local::Problem48Watcher->new( fail_configure => 1 );
my $failed_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
$failed_store->{_indicator_sync_watcher} = $failed_watcher;
my @failed_jobs = ({
    name      => 'watch-fallback',
    cwd       => 'home',
    code      => 'return 0;',
    indicator => { name => 'watch-fallback', icon => 'x', priority => 1 },
});
my @watcher_warnings;
my $failed_setup;
{
    local $SIG{__WARN__} = sub { push @watcher_warnings, @_ };
    $failed_setup = $failed_store->sync_collectors( \@failed_jobs, return_indicators => 1 );
}
like( join( '', @watcher_warnings ), qr/explicit test watch setup failure/,
    'watch setup failures are visible before portable fallback' );
ok( grep( { $_->{name} eq 'watch-fallback' } @{ $failed_setup->{indicators} } ),
    'watch setup failure still completes the portable reconciliation' );
ok( $failed_store->{_indicator_sync_watcher_unavailable},
    'failed native acceleration is disabled for later calls' );
ok( !$failed_store->{_indicator_sync_watcher},
    'the failed watcher handle is removed from the store' );

ok( !$store->_configure_indicator_sync_watcher( undef, \@jobs ),
    'watch configuration rejects a non-array root argument' );
ok( !$store->_configure_indicator_sync_watcher( \@indicator_roots, undef ),
    'watch configuration rejects a non-array job argument' );
my $no_inventory_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
$no_inventory_store->{_indicator_sync_watcher} = Local::Problem48Watcher->new;
ok( !$no_inventory_store->_configure_indicator_sync_watcher( \@indicator_roots, \@jobs ),
    'watch configuration requires a prior directory inventory signature' );

my $malformed_inventory_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
$malformed_inventory_store->{_indicator_sync_watcher} = Local::Problem48Watcher->new;
$malformed_inventory_store->{_indicator_sync_directory_inventory_signature}
  = Developer::Dashboard::JSON::json_encode( { invalid => 'inventory' } );
my $malformed_inventory_error;
eval {
    $malformed_inventory_store->_configure_indicator_sync_watcher( \@indicator_roots, \@jobs );
    1;
} or $malformed_inventory_error = $@;
like( $malformed_inventory_error, qr/inventory is not an array reference/,
    'watch configuration rejects a decoded non-array inventory' );

my $inventory_root = File::Spec->catdir( $ENV{HOME}, 'watch-inventory-root' );
my $inventory_child = File::Spec->catdir( $inventory_root, 'watch-child' );
make_path($inventory_child);
my $malformed_entries_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $malformed_entries_watcher = Local::Problem48Watcher->new;
$malformed_entries_store->{_indicator_sync_watcher} = $malformed_entries_watcher;
$malformed_entries_store->{_indicator_sync_directory_inventory_signature}
  = Developer::Dashboard::JSON::json_encode(
    [ 'bad-entry', [ undef, [] ], [ 'bad-root', 'bad-names' ],
      [ $inventory_root, [ undef, [], '', 'watch-child', 'missing-child' ] ] ]
  );
ok( !$malformed_entries_store->_configure_indicator_sync_watcher( [$inventory_root], \@jobs ),
    'malformed inventory entries safely reject a watch snapshot' );
is_deeply( $malformed_entries_watcher->{path_history}[-1], [ $inventory_root, $inventory_child ],
    'watch paths include only valid roots and existing indicator directories' );

my $watcher_new_unavailable_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
{
    no warnings qw(redefine once);
    local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return undef };
    is( $watcher_new_unavailable_store->_indicator_sync_watcher, undef,
        'store accepts an unavailable optional watcher' );
}
ok( $watcher_new_unavailable_store->{_indicator_sync_watcher_unavailable},
    'store memoizes an unavailable optional watcher' );
my $watcher_new_available_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $watcher_new_available = Local::Problem48Watcher->new;
{
    no warnings qw(redefine once);
    local *Developer::Dashboard::IndicatorStore::Watch::new = sub {
        return $watcher_new_available;
    };
    is( $watcher_new_available_store->_indicator_sync_watcher,
        $watcher_new_available,
        'store constructs and returns an available optional watcher' );
    is( $watcher_new_available_store->_indicator_sync_watcher,
        $watcher_new_available,
        'store reuses its constructed optional watcher' );
}

my @unknown_failure_warnings;
my $unknown_failure_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $unknown_failure_watcher = Local::Problem48Watcher->new;
{
    local $SIG{__WARN__} = sub { push @unknown_failure_warnings, @_ };
    $unknown_failure_store->_disable_indicator_sync_watcher($unknown_failure_watcher);
}
like( join( '', @unknown_failure_warnings ), qr/unknown filesystem watch error/,
    'watcher disable reports an explicit unknown-error diagnostic when none is supplied' );
my @empty_failure_warnings;
my $empty_failure_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $empty_failure_watcher = Local::Problem48Watcher->new;
$empty_failure_watcher->{last_error} = '';
{
    local $SIG{__WARN__} = sub { push @empty_failure_warnings, @_ };
    $empty_failure_store->_disable_indicator_sync_watcher($empty_failure_watcher);
}
like( join( '', @empty_failure_warnings ), qr/unknown filesystem watch error/,
    'an empty watcher diagnostic uses the explicit unknown-error message' );

my @rejected_warnings;
my $rejected_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $rejected_watcher = Local::Problem48Watcher->new( fail_configure => 1, fail_error => undef );
$rejected_store->{_indicator_sync_watcher} = $rejected_watcher;
{
    local $SIG{__WARN__} = sub { push @rejected_warnings, @_ };
    $rejected_store->sync_collectors( \@failed_jobs, return_indicators => 1 );
}
like( join( '', @rejected_warnings ), qr/watch backend rejected the inventory/,
    'watch setup rejection without a backend diagnostic has a visible fallback message' );

my $watch_roots_signature = $store->{_indicator_sync_watcher_roots_signature};
delete $store->{_indicator_sync_watcher_roots_signature};
ok( !$store->_collector_sync_files_unchanged( \@indicator_roots, \@jobs ),
    'a watch snapshot without a root signature cannot be reused' );
$store->{_indicator_sync_watcher_roots_signature} = $watch_roots_signature;
ok( !$store->_collector_sync_files_unchanged( [ @indicator_roots, '/different-root' ], \@jobs ),
    'a changed ordered root set cannot reuse the watch snapshot' );
my $watch_unchanged_calls = $watcher->{unchanged_calls};
my $watch_snapshot_signature = $store->{_indicator_sync_watcher_signature};
delete $store->{_indicator_sync_watcher_signature};
my $opendir_without_watch_signature = $P48_WATCH_OPENDIR_CALLS;
$store->_collector_sync_files_unchanged( \@indicator_roots, \@jobs );
ok( $P48_WATCH_OPENDIR_CALLS > $opendir_without_watch_signature,
    'missing watch signature falls back to complete portable validation' );
is( $watcher->{unchanged_calls}, $watch_unchanged_calls,
    'portable fallback does not poll a watcher without a matching signature' );
$store->{_indicator_sync_watcher_signature} = $watch_snapshot_signature;

my $read_failure_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $read_failure_watcher = Local::Problem48Watcher->new;
$read_failure_store->{_indicator_sync_watcher} = $read_failure_watcher;
$read_failure_store->sync_collectors( \@jobs, return_indicators => 1 );
$read_failure_watcher->signal_failure;
my @read_failure_warnings;
{
    local $SIG{__WARN__} = sub { push @read_failure_warnings, @_ };
    $read_failure_store->_collector_sync_files_unchanged( \@indicator_roots, \@jobs );
}
like( join( '', @read_failure_warnings ), qr/explicit test watch read failure/,
    'a watcher read failure is logged before portable validation' );
ok( $read_failure_store->{_indicator_sync_watcher_unavailable},
    'a watcher read failure disables the acceleration path' );

my $native_watcher = Developer::Dashboard::IndicatorStore::Watch->new;
SKIP: {
    skip 'native XS inotify backend is unavailable in the standard test image', 5 if !$native_watcher;
    my $native_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
    $native_store->{_indicator_sync_watcher} = $native_watcher;
    my @native_jobs = map {
        {
            name      => "native-watch-$_",
            cwd       => 'home',
            code      => 'return 0;',
            indicator => { name => "native-watch-$_", icon => 'x', priority => $_ },
        }
    } 1 .. 3;
    my $native_seed = $native_store->sync_collectors( \@native_jobs, return_indicators => 1 );
    my $native_seed_count = scalar grep { ($_->{name} || '') =~ /\Anative-watch-/ }
      @{ $native_seed->{indicators} };
    is( $native_seed_count, 3,
        'native watcher integrates with initial indicator reconciliation' );

    my $native_signature_calls = 0;
    my $native_original_signature = \&Developer::Dashboard::IndicatorStore::_indicator_file_signature;
    my $native_opendir_before = $P48_WATCH_OPENDIR_CALLS;
    my $native_stable;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::IndicatorStore::_indicator_file_signature = sub {
            $native_signature_calls++;
            return $native_original_signature->(@_);
        };
        $native_stable = $native_store->sync_collectors(
            \@native_jobs,
            return_indicators           => 1,
            return_unchanged             => 1,
            skip_indicators_if_unchanged => 1,
        );
    }
    is( $native_stable->{unchanged}, 1,
        'native event-free watch validates the stable indicator sync' );
    is( $native_signature_calls, 0,
        'native stable sync performs no per-file status metadata stats' );
    is( $P48_WATCH_OPENDIR_CALLS, $native_opendir_before,
        'native stable sync performs no directory enumeration' );

    my $native_changed_name = 'native-watch-2';
    $native_store->set_indicator( $native_changed_name, status => 'native-fresh', icon => 'x' );
    my $native_changed = $native_store->sync_collectors(
        \@native_jobs,
        return_indicators           => 1,
        return_unchanged             => 1,
        skip_indicators_if_unchanged => 1,
    );
    my ($native_changed_item) = grep { $_->{name} eq $native_changed_name }
      @{ $native_changed->{indicators} || [] };
    is( $native_changed_item->{status}, 'native-fresh',
        'native filesystem event forces reconciliation of the changed status' );
}

done_testing;

package Local::Problem48Watcher;

sub new {
    my ( $class, %args ) = @_;
    return bless {
        configure_calls => 0,
        event           => 0,
        paths           => [],
        path_history    => [],
        fail_configure  => $args{fail_configure} || 0,
        fail_error      => exists $args{fail_error} ? $args{fail_error} : 'explicit test watch setup failure',
        unchanged_calls => 0,
    }, $class;
}
sub configure {
    my ( $self, $signature, $paths ) = @_;
    $self->{configure_calls}++;
    if ( $self->{fail_configure} ) {
        $self->{last_error} = $self->{fail_error};
        return 0;
    }
    $self->{signature} = $signature;
    $self->{paths} = [ @{$paths} ];
    push @{ $self->{path_history} }, [ @{$paths} ];
    $self->{event} = 0;
    return 1;
}
sub unchanged {
    my ( $self, $signature ) = @_;
    $self->{unchanged_calls}++;
    return 0 if !defined $self->{signature} || $self->{signature} ne $signature;
    return 0 if delete $self->{event};
    return 1;
}
sub signal_event { $_[0]{event} = 1; return 1 }
sub signal_failure { $_[0]{event} = 1; $_[0]{last_error} = 'explicit test watch read failure'; return 1 }
sub last_error { return $_[0]{last_error} }
sub close { $_[0]{signature} = undef; $_[0]{paths} = []; return 1 }

__END__

=pod

=head1 NAME

670-problem48-indicator-sync-watch.t - verify event-driven sync freshness

=head1 PURPOSE

Checks that a matching event-free filesystem watch can skip repeated stable
directory and file-stat checks, while any event returns synchronization to the
existing complete validator.

=head1 WHY IT EXISTS

The Problem 48 stable status response already reuses serialized output only
after proving that collector settings, indicator directories, and persisted
status files remain unchanged. A watcher is acceptable only if it preserves
that cross-process freshness guarantee and does not hide new or changed files.

=head1 WHEN TO USE

Run this test when changing the event-aware path in
C<Developer::Dashboard::IndicatorStore>.

=head1 HOW TO USE

  d2 docker compose run --rm --no-deps dev prove -lv t/670-problem48-indicator-sync-watch.t

=head1 WHAT USES IT

The standard repository test suite runs this contract test. Production
indicator synchronization uses the same path when the optional native watcher
is available.

=head1 EXAMPLES

The test seeds eight collectors, counts directory and file-signature checks on
a stable sync, then injects file-change and directory-creation events and
confirms the full reconciliation returns fresh records. It also removes a
status file while retaining its inventoried directory, then verifies the
active collector is repaired instead of being classified unchanged. When FFI
is available, it repeats the stable and external-write checks with the real
Linux watcher.

=cut
