use strict;
use warnings;

use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin;
use Errno qw(EACCES EIO ENOTDIR);
use Test::More;

our %P48_SYNC_DIR_ROOT_BY_FD;
our ( $P48_SYNC_FAIL_OPENDIR, $P48_SYNC_FAIL_READDIR, $P48_SYNC_FAIL_CLOSEDIR );
BEGIN {
    no warnings 'redefine';
    *CORE::GLOBAL::opendir = sub (*$) {
        my $root = $_[1];
        if ( defined $main::P48_SYNC_FAIL_OPENDIR && $root eq $main::P48_SYNC_FAIL_OPENDIR ) {
            $! = Errno::EACCES();
            return 0;
        }
        my $opened = CORE::opendir( $_[0], $root );
        $main::P48_SYNC_DIR_ROOT_BY_FD{ fileno( $_[0] ) } = $root if $opened;
        return $opened;
    };
    *CORE::GLOBAL::readdir = sub (*) {
        my ($handle) = @_;
        my $root = $main::P48_SYNC_DIR_ROOT_BY_FD{ fileno($handle) };
        if ( defined $main::P48_SYNC_FAIL_READDIR && defined $root && $root eq $main::P48_SYNC_FAIL_READDIR ) {
            $! = Errno::EIO();
            return;
        }
        return CORE::readdir($handle);
    };
    *CORE::GLOBAL::closedir = sub (*) {
        my ($handle) = @_;
        my $fd = fileno($handle);
        my $root = defined $fd ? delete $main::P48_SYNC_DIR_ROOT_BY_FD{$fd} : undef;
        if ( defined $main::P48_SYNC_FAIL_CLOSEDIR && defined $root && $root eq $main::P48_SYNC_FAIL_CLOSEDIR ) {
            CORE::closedir($handle) or return 0;
            $! = Errno::EIO();
            return 0;
        }
        return CORE::closedir($handle);
    };
}

my $repo_root = File::Spec->catdir( $FindBin::Bin, '..' );
require lib;
lib->import( File::Spec->catdir( $repo_root, 'lib' ) );
require Developer::Dashboard::IndicatorStore;
require Developer::Dashboard::PathRegistry;

local $ENV{HOME} = tempdir( CLEANUP => 1 );
chdir $ENV{HOME} or die "Unable to enter test HOME '$ENV{HOME}': $!\n";

my $paths = Developer::Dashboard::PathRegistry->new;
my $store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
# This file verifies the portable metadata/stat validator and its path-cache
# counters. Keep the optional native watcher disabled so these assertions stay
# deterministic on systems where FFI::Platypus is installed.
$store->{_indicator_sync_watcher_unavailable} = 1;
my @jobs = map {
    {
        name      => "p48-sync-$_",
        cwd       => 'home',
        code      => 'return 0;',
        indicator => { name => "p48-sync-$_", icon => 'x', priority => $_ },
    }
} 1 .. 12;

my $seeded = $store->sync_collectors( \@jobs, return_indicators => 1 );
is( scalar @{ $seeded->{indicators} }, 12,
    'initial sync creates all collector-backed indicators' );

my $original_roots = \&Developer::Dashboard::PathRegistry::indicators_roots;
my $original_uncached_read = \&Developer::Dashboard::IndicatorStore::_read_indicator_file_uncached;
my $original_local_indicator = \&Developer::Dashboard::IndicatorStore::_local_indicator;
my $original_nearest_inherited = \&Developer::Dashboard::IndicatorStore::_nearest_inherited_indicator;
my $original_sync_plan = \&Developer::Dashboard::IndicatorStore::_collector_sync_plan;
my $root_discoveries = 0;
my $local_lookups = 0;
my $inherited_lookups = 0;
my $sync_plan_calls = 0;
my %file_reads;
{
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::indicators_roots = sub {
        $root_discoveries++;
        return $original_roots->(@_);
    };
    local *Developer::Dashboard::IndicatorStore::_read_indicator_file_uncached = sub {
        my ( $self, $file ) = @_;
        $file_reads{$file}++;
        return $original_uncached_read->(@_);
    };
    local *Developer::Dashboard::IndicatorStore::_local_indicator = sub {
        $local_lookups++;
        return $original_local_indicator->(@_);
    };
    local *Developer::Dashboard::IndicatorStore::_nearest_inherited_indicator = sub {
        $inherited_lookups++;
        return $original_nearest_inherited->(@_);
    };
    local *Developer::Dashboard::IndicatorStore::_collector_sync_plan = sub {
        $sync_plan_calls++;
        return $original_sync_plan->(@_);
    };
    my $synced = $store->sync_collectors( \@jobs, return_indicators => 1 );
    is( scalar @{ $synced->{indicators} }, 12,
        'steady-state sync returns the full indicator inventory' );
}
is( $root_discoveries, 1,
    'steady-state sync resolves indicator roots once and shares that snapshot' );
is( $local_lookups, 0,
    'single-root sync reuses the existing lookup as its local indicator state' );
is( $inherited_lookups, 0,
    'single-root sync skips an impossible inherited-layer lookup' );
is( $sync_plan_calls, 0,
    'unchanged collector config and indicator files reuse the completed sync plan' );
is( scalar keys %file_reads, 0,
    'steady-state sync validates file metadata without rereading unchanged JSON' );
my $duplicate_reads = scalar grep { $_ != 1 } values %file_reads;
ok( !$duplicate_reads,
    'a stable sync performs no duplicate physical status-file reads' );

my $original_json_decode = \&Developer::Dashboard::IndicatorStore::json_decode;
my $stable_status_decodes = 0;
my $stable_status_sync;
{
    no warnings 'redefine';
    local *Developer::Dashboard::IndicatorStore::json_decode = sub {
        $stable_status_decodes++;
        return $original_json_decode->(@_);
    };
    $stable_status_sync = $store->sync_collectors(
        \@jobs,
        return_indicators                 => 1,
        return_unchanged                  => 1,
        skip_indicators_if_unchanged      => 1,
    );
}
is( $stable_status_sync->{unchanged}, 1,
    'metadata-only stable sync reports an unchanged indicator inventory' );
ok( !exists $stable_status_sync->{indicators},
    'metadata-only stable sync omits records when the caller has a response cache' );
is( $stable_status_decodes, 0,
    'metadata-only stable sync validates persisted records without decoding JSON' );

my $original_catfile = File::Spec->can('catfile');
my $status_path_joins = 0;
my @stable_roots = $paths->indicators_roots;
{
    local $store->{_indicator_status_paths_cache} = undef;
    no warnings 'redefine';
    local *File::Spec::catfile = sub {
        $status_path_joins++;
        return $original_catfile->(@_);
    };
    ok(
        $store->_collector_sync_files_unchanged( \@stable_roots, \@jobs ),
        'first stable status metadata validation succeeds'
    );
    is( $status_path_joins, 12,
        'the first metadata validation constructs one status path per inventory entry' );
    ok(
        $store->_collector_sync_files_unchanged( \@stable_roots, \@jobs ),
        'repeated stable status metadata validation succeeds'
    );
}
is( $status_path_joins, 12,
    'repeated stable validation reuses precomputed status-file paths' );

my $cached_inventory_signature = $store->{_indicator_sync_directory_inventory_signature};
my $status_paths_cache_signature = Developer::Dashboard::JSON::json_encode(
    { roots => \@stable_roots, inventory => $cached_inventory_signature } );
$status_path_joins = 0;
{
    local $store->{_indicator_status_paths_cache} = {
        cache_signature => $status_paths_cache_signature,
        paths_by_name   => [],
    };
    no warnings 'redefine';
    local *File::Spec::catfile = sub {
        $status_path_joins++;
        return $original_catfile->(@_);
    };
    ok(
        $store->_collector_sync_files_unchanged( \@stable_roots, \@jobs ),
        'metadata validation rebuilds malformed cached status-path maps'
    );
}
is( $status_path_joins, 12,
    'a malformed status-path map is replaced with one path per inventory entry' );

$status_path_joins = 0;
{
    local $store->{_indicator_status_paths_cache} = {
        paths_by_name => {},
    };
    no warnings 'redefine';
    local *File::Spec::catfile = sub {
        $status_path_joins++;
        return $original_catfile->(@_);
    };
    ok(
        $store->_collector_sync_files_unchanged( \@stable_roots, \@jobs ),
        'metadata validation rebuilds a status-path cache without a signature'
    );
}
is( $status_path_joins, 12,
    'a cache without a signature is replaced with one path per inventory entry' );

$status_path_joins = 0;
{
    local $store->{_indicator_status_paths_cache} = {
        cache_signature => 'stale-signature',
        paths_by_name   => {},
    };
    no warnings 'redefine';
    local *File::Spec::catfile = sub {
        $status_path_joins++;
        return $original_catfile->(@_);
    };
    ok(
        $store->_collector_sync_files_unchanged( \@stable_roots, \@jobs ),
        'metadata validation rebuilds a status-path cache with a stale signature'
    );
}
is( $status_path_joins, 12,
    'a stale cache signature is replaced with one path per inventory entry' );

my $malformed_path_name = $jobs[0]{indicator}{name};
my $malformed_paths_inventory = Developer::Dashboard::JSON::json_encode(
    { roots => \@stable_roots, inventory => $cached_inventory_signature } );
{
    local $store->{_indicator_status_paths_cache} = {
        cache_signature => $malformed_paths_inventory,
        paths_by_name   => { $malformed_path_name => 'not-an-array' },
    };
    ok(
        !$store->_collector_sync_files_unchanged( \@stable_roots, \@jobs ),
        'metadata validation rejects a cached status path that is not an array'
    );
}

ok( !$store->_collector_sync_files_unchanged( undef, \@jobs ),
    'metadata-only validation rejects roots that are not an array' );
ok( !$store->_collector_sync_files_unchanged( \@stable_roots, undef ),
    'metadata-only validation rejects jobs that are not an array' );
{
    local $store->{_indicator_sync_directory_inventory_signature} = undef;
    ok( !$store->_collector_sync_files_unchanged( \@stable_roots, \@jobs ),
        'metadata-only validation falls back when no previous inventory signature exists' );
}

my $guard_root = File::Spec->catdir( $ENV{HOME}, 'p48-guard-root' );
my $guard_name = 'p48-guard-record';
my $guard_dir = File::Spec->catdir( $guard_root, $guard_name );
make_path($guard_dir);
my $guard_file = File::Spec->catfile( $guard_dir, 'status.json' );
open my $guard_fh, '>:raw', $guard_file or die "Unable to create '$guard_file': $!\n";
print {$guard_fh} Developer::Dashboard::JSON::json_encode( { name => $guard_name } );
close $guard_fh or die "Unable to close '$guard_file': $!\n";
my $guard_signature = $store->_indicator_file_signature($guard_file);
isnt( $guard_signature, 'missing', 'coverage fixture contains a real status file' );
my $guard_inventory_signature = Developer::Dashboard::JSON::json_encode(
    [ [ $guard_root, [$guard_name] ] ]
);
my $guard_job = { name => $guard_name, indicator => { name => $guard_name } };
{
    local $store->{_indicator_sync_directory_inventory_signature} = $guard_inventory_signature;
    local $store->{_indicator_sync_directory_inventory_current} = $guard_inventory_signature;
    local $store->{_indicator_file_bytes_cache} = {
        $guard_file => { signature => $guard_signature },
    };
    ok( $store->_collector_sync_files_unchanged( [$guard_root], [$guard_job] ),
        'metadata-only validation accepts a present, unchanged active status file' );
    ok( $store->_collector_sync_files_unchanged( [$guard_root], ['malformed-job'] ),
        'metadata-only validation skips malformed collector job entries' );
    ok( $store->_collector_sync_files_unchanged( [$guard_root], [ { name => $guard_name } ] ),
        'metadata-only validation skips jobs without indicator configuration' );
    ok(
        $store->_collector_sync_files_unchanged(
            [$guard_root],
            [ { name => $guard_name, indicator => { name => '' } } ],
        ),
        'metadata-only validation falls back to the collector name for a blank indicator name'
    );
    ok(
        $store->_collector_sync_files_unchanged(
            [$guard_root],
            [ { name => $guard_name, indicator => {}, disable => 1 } ],
        ),
        'metadata-only validation skips disabled collector jobs'
    );
    ok(
        $store->_collector_sync_files_unchanged(
            [$guard_root],
            [ { name => undef, indicator => {} }, { name => '', indicator => {} } ],
        ),
        'metadata-only validation skips jobs with undefined or empty names'
    );
}

my $missing_guard_root = File::Spec->catdir( $ENV{HOME}, 'p48-guard-missing' );
my $missing_guard_dir = File::Spec->catdir( $missing_guard_root, $guard_name );
make_path($missing_guard_dir);
my $missing_guard_file = File::Spec->catfile( $missing_guard_dir, 'status.json' );
my $missing_guard_inventory = Developer::Dashboard::JSON::json_encode(
    [ [ $missing_guard_root, [$guard_name] ] ]
);
{
    local $store->{_indicator_sync_directory_inventory_signature} = $missing_guard_inventory;
    local $store->{_indicator_sync_directory_inventory_current} = $missing_guard_inventory;
    local $store->{_indicator_file_bytes_cache} = {
        $missing_guard_file => { signature => 'missing' },
    };
    ok(
        !$store->_collector_sync_files_unchanged( [$missing_guard_root], [$guard_job] ),
        'metadata-only validation reconciles when an active status file is missing'
    );
    local $store->{_indicator_file_bytes_cache} = {};
    ok(
        !$store->_collector_sync_files_unchanged( [$missing_guard_root], [$guard_job] ),
        'metadata-only validation reconciles when an inventory status path is not cached'
    );
}

{
    local $store->{_indicator_sync_directory_inventory_signature} = 'stale-inventory';
    local $store->{_indicator_file_bytes_cache} = {};
    ok( !$store->_collector_sync_files_unchanged( [$guard_root], [] ),
        'metadata-only validation reconciles a changed directory inventory' );
}
{
    local $store->{_indicator_sync_directory_inventory_signature} = $guard_inventory_signature;
    local $store->{_indicator_file_bytes_cache} = [];
    ok( !$store->_collector_sync_files_unchanged( [$guard_root], [] ),
        'metadata-only validation rejects a malformed persistent byte cache' );
}
{
    local $store->{_indicator_sync_directory_inventory_signature} = $guard_inventory_signature;
    local $store->{_indicator_file_bytes_cache} = { malformed => {} };
    ok( !$store->_collector_sync_files_unchanged( [$guard_root], [] ),
        'metadata-only validation rejects a cache entry without a signature' );
}
{
    local $store->{_indicator_sync_directory_inventory_signature} = $guard_inventory_signature;
    local $store->{_indicator_file_bytes_cache} = { malformed => 'not-a-hash' };
    ok( !$store->_collector_sync_files_unchanged( [$guard_root], [] ),
        'metadata-only validation rejects a cache entry with a malformed type' );
}
{
    delete $store->{_indicator_sync_file_changed};
    local $store->{_indicator_sync_directory_inventory_signature} = $guard_inventory_signature;
    local $store->{_indicator_file_bytes_cache} = {
        $guard_file => { signature => 'stale-signature' },
    };
    ok( !$store->_collector_sync_files_unchanged( [$guard_root], [] ),
        'metadata-only validation detects a changed signature without a sync marker' );
    ok( !exists $store->{_indicator_sync_file_changed},
        'a direct freshness check does not add an absent sync-change marker' );
}
{
    local $store->{_indicator_sync_directory_inventory_signature} = $guard_inventory_signature;
    local $store->{_indicator_file_bytes_cache} = {
        $guard_file => { signature => 'stale-signature' },
    };
    local $store->{_indicator_sync_file_changed} = 0;
    ok( !$store->_collector_sync_files_unchanged( [$guard_root], [] ),
        'metadata-only validation marks a changed signature during collector sync' );
    is( $store->{_indicator_sync_file_changed}, 1,
        'changed-signature marker is set for the reconciliation path' );
}

my $nonexistent_guard_root = File::Spec->catdir( $ENV{HOME}, 'p48-guard-not-a-directory' );
{
    local $store->{_indicator_sync_directory_inventory_signature} = $guard_inventory_signature;
    local $store->{_indicator_file_bytes_cache} = {
        $guard_file => { signature => $guard_signature },
    };
    ok( !-d $nonexistent_guard_root, 'missing-root fixture is absent before validation' );
    ok(
        $store->_collector_sync_files_unchanged( [$guard_root, $nonexistent_guard_root], [] ),
        'metadata-only validation skips a missing root while preserving another root inventory'
    );
}
my $failed_open_root = File::Spec->catdir( $ENV{HOME}, 'p48-guard-open-failure' );
make_path($failed_open_root);
{
    local $store->{_indicator_sync_directory_inventory_signature} = '[]';
    local $store->{_indicator_file_bytes_cache} = {};
    local $P48_SYNC_FAIL_OPENDIR = $failed_open_root;
    ok( !$store->_collector_sync_files_unchanged( [$failed_open_root], [] ),
        'metadata-only validation reconciles when opening a root fails' );
}
{
    local $store->{_indicator_sync_directory_inventory_signature} = '[]';
    local $store->{_indicator_file_bytes_cache} = {};
    local $P48_SYNC_FAIL_READDIR = $guard_root;
    ok( !$store->_collector_sync_files_unchanged( [$guard_root], [] ),
        'metadata-only validation reconciles after a directory-read error' );
}
{
    local $store->{_indicator_sync_directory_inventory_signature} = '[]';
    local $store->{_indicator_file_bytes_cache} = {};
    local $P48_SYNC_FAIL_CLOSEDIR = $guard_root;
    my $closedir_error = eval {
        $store->_collector_sync_files_unchanged( [$guard_root], [] );
        '';
    } // $@;
    like( $closedir_error, qr/Unable to close indicator directory/,
        'metadata-only validation exposes directory-close errors' );
}
{
    local $store->{_indicator_sync_directory_inventory_signature} = '[]';
    local $store->{_indicator_file_bytes_cache} = {};
    local $P48_SYNC_FAIL_READDIR = $guard_root;
    local $P48_SYNC_FAIL_CLOSEDIR = $guard_root;
    my $read_cleanup_error = eval {
        $store->_collector_sync_files_unchanged( [$guard_root], [] );
        '';
    } // $@;
    like( $read_cleanup_error, qr/Unable to close indicator directory/,
        'metadata-only validation reports a close failure while cleaning up a read error' );
}

delete $store->{_indicator_sync_directory_inventory_signature};
my $missing_inventory_signature_plans = 0;
{
    no warnings 'redefine';
    local *Developer::Dashboard::IndicatorStore::_collector_sync_plan = sub {
        $missing_inventory_signature_plans++;
        return $original_sync_plan->(@_);
    };
    $store->sync_collectors( \@jobs, return_indicators => 1 );
}
is( $missing_inventory_signature_plans, 12,
    'a missing directory-inventory signature forces normal reconciliation' );

my $changed = $store->get_indicator('p48-sync-1');
$store->set_indicator( 'p48-sync-1', %{$changed}, status => 'error' );
my $after_change = $store->sync_collectors( \@jobs, return_indicators => 1 );
my ($changed_indicator) = grep { $_->{name} eq 'p48-sync-1' } @{ $after_change->{indicators} };
is( $changed_indicator->{status}, 'error',
    'a later sync observes changed disk state instead of a previous request cache' );

my $external_item = $store->get_indicator('p48-sync-3');
$external_item->{status} = 'external-process-update';
my $external_file = File::Spec->catfile( $paths->indicator_dir('p48-sync-3'), 'status.json' );
my $external_pending = $store->_pending_indicator_file($external_file);
$paths->atomic_write_secure(
    $external_pending,
    $external_file,
    Developer::Dashboard::JSON::json_encode($external_item),
);
my $after_external_write = $store->sync_collectors( \@jobs, return_indicators => 1 );
my ($externally_updated) = grep { $_->{name} eq 'p48-sync-3' } @{ $after_external_write->{indicators} };
is( $externally_updated->{status}, 'external-process-update',
    'an atomic external status-file replacement invalidates the fast path' );

my @remaining_jobs = @jobs[ 0 .. 10 ];
my $after_retire = $store->sync_collectors( \@remaining_jobs, return_indicators => 1 );
my $retired_still_listed = scalar grep { $_->{name} eq 'p48-sync-12' } @{ $after_retire->{indicators} };
ok( !$retired_still_listed,
    'retiring a collector invalidates the request-local file cache before listing' );
ok( !defined $store->get_indicator('p48-sync-12'),
    'retired collector indicator is absent from subsequent disk lookups' );

my $caller_copy = $store->get_indicator('p48-sync-1');
$caller_copy->{status} = 'caller-only-mutation';
is( $store->get_indicator('p48-sync-1')->{status}, 'error',
    'mutating a public get_indicator result does not alter persisted state' );

$store->delete_indicator('p48-sync-2');
my $after_external_delete = $store->sync_collectors( \@jobs, return_indicators => 1 );
my ($restored) = grep { $_->{name} eq 'p48-sync-2' } @{ $after_external_delete->{indicators} };
is( $restored->{name}, 'p48-sync-2',
    'deleting an active collector indicator invalidates the fast path and restores it' );

my @changed_jobs = map { { %$_, indicator => { %{ $_->{indicator} } } } } @jobs;
$changed_jobs[0]{indicator}{icon} = 'changed-config-icon';
my $after_config_change = $store->sync_collectors( \@changed_jobs, return_indicators => 1 );
my ($reconfigured) = grep { $_->{name} eq 'p48-sync-1' } @{ $after_config_change->{indicators} };
is( $reconfigured->{icon}, 'changed-config-icon',
    'collector configuration changes invalidate the cached synchronization plan' );

my $active_dir = $paths->indicator_dir('p48-sync-4');
my $active_file = File::Spec->catfile( $active_dir, 'status.json' );
$store->sync_collectors( \@jobs, return_indicators => 1 );
unlink $active_file or die "Unable to remove active status file '$active_file': $!\n";
my $missing_active_plans = 0;
{
    no warnings 'redefine';
    local *Developer::Dashboard::IndicatorStore::_collector_sync_plan = sub {
        $missing_active_plans++;
        return $original_sync_plan->(@_);
    };
    my $missing_active = $store->sync_collectors( \@jobs, return_indicators => 1 );
    my ($reseeded) = grep { $_->{name} eq 'p48-sync-4' } @{ $missing_active->{indicators} };
    is( $reseeded->{name}, 'p48-sync-4',
        'a missing active status file falls back to reconciliation even when its directory remains' );
}
is( $missing_active_plans, 12,
    'a missing active file prevents the stable-inventory shortcut from skipping plans' );

my @inventory_change_jobs = ( @jobs, 'malformed-job', { name => '', indicator => {} },
    { name => undef, indicator => {} },
    { name => 'disabled-job', indicator => {}, disable => 1 },
    { name => 'alternate-name', indicator => { name => 'p48-alt-name' } },
    { name => 'empty-name-fallback', indicator => { name => '' } } );
my $inventory_change = $store->sync_collectors( \@inventory_change_jobs, return_indicators => 1 );
ok( grep( { $_->{name} eq 'p48-alt-name' } @{ $inventory_change->{indicators} } ),
    'sync validates job shapes and supports an indicator name distinct from its collector name' );
ok( grep( { $_->{name} eq 'empty-name-fallback' } @{ $inventory_change->{indicators} } ),
    'an empty configured indicator name falls back to the collector name' );
my ($indicator_root) = $paths->indicators_roots;
my $extra_dir = File::Spec->catdir( $indicator_root, 'p48-unmanaged-extra' );
mkdir $extra_dir or die "Unable to add inventory-only directory '$extra_dir': $!\n";
my $plans = 0;
my $original_sync_plan_for_inventory = \&Developer::Dashboard::IndicatorStore::_collector_sync_plan;
{
    no warnings 'redefine';
    local *Developer::Dashboard::IndicatorStore::_collector_sync_plan = sub {
        $plans++;
        return $original_sync_plan_for_inventory->(@_);
    };
    $store->sync_collectors( \@inventory_change_jobs, return_indicators => 1 );
}
is( $plans, 14,
    'a changed indicator directory inventory triggers normal collector reconciliation' );
rmdir $extra_dir or die "Unable to remove inventory-only directory '$extra_dir': $!\n";

my $settled_inventory = $store->sync_collectors( \@inventory_change_jobs, return_indicators => 1 );
ok( $settled_inventory->{indicators}, 'the inventory-only test mutation is reconciled before cache-guard probing' );
my @missing_cached_jobs = ( @jobs, { name => 'p48-cached-missing', indicator => { icon => 'x' } } );
my @cached_roots = $paths->indicators_roots;
$store->{_collector_sync_config_signature}
  = Developer::Dashboard::JSON::json_encode( { jobs => \@missing_cached_jobs, roots => \@cached_roots } );
my $missing_cached_plan_calls = 0;
{
    no warnings 'redefine';
    local *Developer::Dashboard::IndicatorStore::_collector_sync_plan = sub {
        $missing_cached_plan_calls++;
        return $original_sync_plan->(@_);
    };
    my $healed = $store->sync_collectors( \@missing_cached_jobs, return_indicators => 1 );
    ok( grep( { $_->{name} eq 'p48-cached-missing' } @{ $healed->{indicators} } ),
        'the stable-plan guard restores an unexpectedly absent active indicator' );
}
is( $missing_cached_plan_calls, 13,
    'an active indicator missing from an otherwise stable inventory takes the reconciliation path' );

my $raw_file = File::Spec->catfile( $paths->indicator_dir('p48-sync-5'), 'status.json' );
my $signature_call = 0;
my $cached_item = { name => 'p48-sync-5', status => 'cached-stale', managed_by_collector => 1 };
{
    no warnings 'redefine';
    local *Developer::Dashboard::IndicatorStore::_indicator_file_signature = sub {
        my ( $self, $path ) = @_;
        return ++$signature_call == 1 ? 'before-read' : 'after-read';
    };
    local *Developer::Dashboard::IndicatorStore::_read_indicator_file_bytes_uncached = sub {
        return Developer::Dashboard::JSON::json_encode(
            { name => 'p48-sync-5', status => 'fresh-during-read', managed_by_collector => 1 }
        );
    };
    local $store->{_indicator_sync_persistent_read} = 1;
    local $store->{_indicator_sync_read_cache} = {};
    local $store->{_indicator_sync_file_changed} = 0;
    local $store->{_indicator_file_bytes_cache} = {
        $raw_file => { signature => 'old-signature', raw => Developer::Dashboard::JSON::json_encode($cached_item) },
    };
    my $fresh = $store->_read_indicator_file($raw_file);
    is( $fresh->{status}, 'fresh-during-read',
        'a file replaced during the read returns the newly read bytes' );
    ok( !exists $store->{_indicator_file_bytes_cache}{$raw_file},
        'a racing file replacement is not retained in the raw-byte cache' );
}

{
    no warnings 'redefine';
    local *Time::HiRes::stat = sub {
        $! = EACCES;
        return;
    };
    my $err = eval { $store->_indicator_file_signature($raw_file); 1 } ? '' : $@;
    like( $err, qr/Unable to inspect indicator file/, 'unexpected stat failures are reported, not treated as missing' );
}

my $not_dir = File::Spec->catfile( $ENV{HOME}, 'p48-not-directory' );
open my $not_dir_fh, '>', $not_dir or die "Unable to create not-directory probe '$not_dir': $!\n";
close $not_dir_fh or die "Unable to close not-directory probe '$not_dir': $!\n";
is( $store->_indicator_file_signature( File::Spec->catfile( $not_dir, 'status.json' ) ), 'missing',
    'a path beneath a non-directory component is treated as missing' );

{
    no warnings 'redefine';
    local *Developer::Dashboard::IndicatorStore::_close_indicator_read_handle = sub {
        my ( $self, $fh ) = @_;
        CORE::close($fh);
        return;
    };
    my $err = eval { $store->_read_indicator_file_bytes_uncached($raw_file); 1 } ? '' : $@;
    like( $err, qr/Unable to close/, 'status-file close errors are surfaced' );
}
unlink $not_dir or die "Unable to remove not-directory probe '$not_dir': $!\n";

{
    local $store->{_indicator_sync_persistent_read} = 1;
    local $store->{_indicator_sync_read_cache} = {};
    local $store->{_indicator_file_bytes_cache} = {};
    my $fresh = $store->_read_indicator_file($raw_file);
    ok( ref($fresh) eq 'HASH', 'persistent byte reads also work without a sync-change marker' );
    ok( !exists $store->{_indicator_sync_file_changed},
        'standalone persistent reads do not invent a sync-change marker' );
}

my $empty_name_dir = File::Spec->catdir( $indicator_root, 'p48-empty-name' );
make_path($empty_name_dir);
my $empty_name_file = File::Spec->catfile( $empty_name_dir, 'status.json' );
open my $empty_name_fh, '>:raw', $empty_name_file
  or die "Unable to create empty-name status file '$empty_name_file': $!\n";
print {$empty_name_fh} Developer::Dashboard::JSON::json_encode( { name => '', status => 'ok' } );
close $empty_name_fh or die "Unable to close empty-name status file '$empty_name_file': $!\n";
my $after_empty_name_seed = $store->sync_collectors( \@inventory_change_jobs, return_indicators => 1 );
ok( $after_empty_name_seed->{indicators}, 'an empty-name record reconciles into the stable inventory' );
my $stable_empty_name = $store->sync_collectors( \@inventory_change_jobs, return_indicators => 1 );
ok( $stable_empty_name->{indicators},
    'the stable fast path accepts valid inventories containing an empty stored name' );
my @empty_record_inventory = $store->list_indicators;
ok( grep( { defined $_->{name} && $_->{name} eq '' } @empty_record_inventory ),
    'indicator inventory retains records whose stored name is empty' );

done_testing;

__END__

=pod

=head1 NAME

667-problem48-collector-sync-roots.t - verify request-local indicator-root reuse

=head1 PURPOSE

Verifies that collector synchronization resolves the ordered indicator roots
once for a stable synchronization operation, while retaining the current
indicator inventory and observing changed state on the next operation. It also
verifies that unchanged root and directory-inventory signatures reuse generated
status-file path strings, while stale or malformed path caches are rebuilt and
file metadata is checked before the stable fast path is accepted.

=head1 WHY IT EXISTS

The Problem 48 NYTProf profile showed repeated root discovery inside each
collector's existing/local indicator lookup. This test prevents the sync path
from rediscovering the same runtime roots for every collector and guards the
freshness boundary between separate sync operations. A follow-up profile found
repeated path construction during freshness validation; the path map is safe to
reuse only while ordered roots and directory inventory are identical, and each
cached file signature must still match disk.

=head1 WHEN TO USE

Run this test after changing C<IndicatorStore::sync_collectors>, its collector
comparison helpers, or the runtime-layer lookup used for indicator roots.

=head1 HOW TO USE

  prove -lv t/667-problem48-collector-sync-roots.t

=head1 WHAT USES IT

The repository test suite runs this contract test. Production dashboard
requests use the same synchronization path when their configuration declares
collector-backed indicators.

=head1 EXAMPLES

  d2 docker compose -p dd-problem48-tests -f /tmp/problem48-networkless.yml run --rm --no-deps dev prove -lv t/667-problem48-collector-sync-roots.t

=cut
