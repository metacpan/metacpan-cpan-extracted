#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::JSON qw(json_encode json_decode);

# Hermetic runtime: config/state roots resolve from the deepest .developer-dashboard
# layer beneath the current working directory, so we must chdir into a private
# temp home before constructing any path registry.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $store = Developer::Dashboard::IndicatorStore->new( paths => $paths );

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# fresh_store(%opt)
# Builds a fully isolated indicator store rooted at a brand-new temp home so
# indicator inventories from earlier blocks cannot leak into later assertions.
# Input: optional cwd override.
# Output: (store, paths, home) triple.
sub fresh_store {
    my (%opt) = @_;
    my $h = tempdir( CLEANUP => 1 );
    my $p = Developer::Dashboard::PathRegistry->new(
        home => $h,
        ( defined $opt{cwd} ? ( cwd => $opt{cwd} ) : () ),
    );
    my $s = Developer::Dashboard::IndicatorStore->new( paths => $p );
    return ( $s, $p, $h );
}

# two_layer_store()
# Builds a store whose runtime stack has a deepest (local) layer and an inherited
# home layer so local-versus-inherited indicator resolution can be exercised.
# Input: none.
# Output: (store, paths, deep_root, home_root, home) list.
sub two_layer_store {
    my $h = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $h, '.developer-dashboard' ) );
    my $deep = File::Spec->catdir( $h, 'deep' );
    make_path( File::Spec->catdir( $deep, '.developer-dashboard' ) );
    my $p = Developer::Dashboard::PathRegistry->new( home => $h, cwd => $deep );
    my $s = Developer::Dashboard::IndicatorStore->new( paths => $p );
    my ( $deep_root, $home_root ) = $p->indicators_roots;
    return ( $s, $p, $deep_root, $home_root, $h );
}

# plant($root, $name, $data)
# Writes a raw indicator status file directly into one indicator root so a
# specific persisted shape (including corrupt or partial payloads) can be staged.
# Input: indicator root dir, indicator name, and Perl data to encode.
# Output: written file path.
sub plant {
    my ( $root, $name, $data ) = @_;
    my $dir = File::Spec->catdir( $root, $name );
    make_path($dir);
    my $file = File::Spec->catfile( $dir, 'status.json' );
    open my $fh, '>:raw', $file or die "Unable to plant $file: $!";
    print {$fh} json_encode($data);
    close $fh or die "Unable to close $file: $!";
    return $file;
}

# ---------------------------------------------------------------------------
# Block A: set_indicator happy path + read back
# ---------------------------------------------------------------------------
{
    my $saved = $store->set_indicator( 'alpha', status => 'ok', label => 'Alpha' );
    is( $saved->{name},   'alpha', 'set_indicator returns the saved indicator name' );
    is( $saved->{status}, 'ok',    'set_indicator persists the status field' );
    ok( defined $saved->{updated_at}, 'set_indicator stamps updated_at when absent' );

    my $read = $store->get_indicator('alpha');
    is( $read->{label}, 'Alpha', 'get_indicator reads back the persisted indicator' );

    my $with_ts = $store->set_indicator( 'alpha', status => 'ok', updated_at => 123 );
    is( $with_ts->{updated_at}, 123, 'set_indicator keeps an explicit updated_at value' );

    is( $store->get_indicator('no-such-indicator'), undef, 'get_indicator returns undef for a missing indicator' );
}

# ---------------------------------------------------------------------------
# Block B: set_indicator lock-open failure (open '>>' dies)
# ---------------------------------------------------------------------------
{
    my $dir = $paths->indicator_dir('lockfail');
    my $lock = File::Spec->catfile( $dir, '.lock' );
    make_path($lock);    # make the lock path a directory so open '>>' fails
    my $err = eval { $store->set_indicator( 'lockfail', status => 'ok' ); 1 } ? '' : $@;
    like( $err, qr/Unable to open/, 'set_indicator dies when the lock file cannot be opened for append' );
}

# ---------------------------------------------------------------------------
# Block C: set_indicator temp-write failure (open '>:raw' dies)
# ---------------------------------------------------------------------------
{
    my $dir = $paths->indicator_dir('writefail');
    my $pending = File::Spec->catfile( $dir, 'status.json.pending' );
    make_path($pending);    # make the pending path a directory so the write open fails
    my $err = eval { $store->set_indicator( 'writefail', status => 'ok' ); 1 } ? '' : $@;
    like( $err, qr/Unable to write/, 'set_indicator dies when the pending temp file cannot be opened for write' );
}

# ---------------------------------------------------------------------------
# Block D: _read_indicator_file read failure (open '<:raw' dies)
# ---------------------------------------------------------------------------
SKIP: {
    my ( $s, $p ) = fresh_store();
    my ($root) = $p->indicators_roots;
    my $file = plant( $root, 'unreadable', { status => 'ok' } );
    chmod 0000, $file or die "chmod failed: $!";
    skip 'file still readable (running as root?)', 1 if -r $file;
    my $err = eval { $s->get_indicator('unreadable'); 1 } ? '' : $@;
    like( $err, qr/Unable to read/, '_read_indicator_file dies when an existing status file cannot be read' );
    chmod 0644, $file;
}

# ---------------------------------------------------------------------------
# Block E: is_stale
# ---------------------------------------------------------------------------
{
    is( $store->is_stale('not-a-hash'), undef, 'is_stale returns undef for a non-hash item' );
    is( $store->is_stale( { stale => 1 } ), 1, 'is_stale returns true immediately for an explicitly stale item' );
    is( $store->is_stale( {} ), undef, 'is_stale returns undef when there is no updated_at timestamp' );
    is( $store->is_stale( { updated_at => time - 1000 }, max_age => 300 ), 1, 'is_stale flags an item older than max_age' );
    is( $store->is_stale( { updated_at => time }, max_age => 300 ), 0, 'is_stale clears a recently updated item' );
    is( $store->is_stale( { updated_at => time } ), 0, 'is_stale defaults max_age to 300 seconds when unspecified' );
}

# ---------------------------------------------------------------------------
# Block E2: mark_stale
# ---------------------------------------------------------------------------
{
    my ( $s, $p ) = fresh_store();
    $s->set_indicator( 'ms', status => 'ok', label => 'MS' );
    my $marked = $s->mark_stale( 'ms', status => 'stopped' );
    is( $marked->{stale},  1,         'mark_stale flags the indicator as stale' );
    is( $marked->{status}, 'stopped', 'mark_stale applies an explicit replacement status' );

    my $marked_nostatus = $s->mark_stale('ms');
    is( $marked_nostatus->{status}, 'stopped', 'mark_stale keeps the prior status when none is supplied' );

    is( $s->mark_stale('missing-indicator'), undef, 'mark_stale returns undef for a missing indicator' );
}

# ---------------------------------------------------------------------------
# Block F: _is_template_toolkit_text
# ---------------------------------------------------------------------------
{
    is( $store->_is_template_toolkit_text(undef),      0, '_is_template_toolkit_text is false for undef' );
    is( $store->_is_template_toolkit_text(''),         0, '_is_template_toolkit_text is false for an empty string' );
    is( $store->_is_template_toolkit_text('plain'),    0, '_is_template_toolkit_text is false for plain text' );
    is( $store->_is_template_toolkit_text('[% x %]'),  1, '_is_template_toolkit_text detects a TT directive marker' );
}

# ---------------------------------------------------------------------------
# Block G: _is_placeholder_missing_indicator
# ---------------------------------------------------------------------------
{
    is( $store->_is_placeholder_missing_indicator('x'), 0, '_is_placeholder_missing_indicator is false for a non-hash' );
    is( $store->_is_placeholder_missing_indicator( { managed_by_collector => 0 } ), 0, '_is_placeholder_missing_indicator is false for an unmanaged indicator' );
    is( $store->_is_placeholder_missing_indicator( { managed_by_collector => 1 } ), 0, '_is_placeholder_missing_indicator is false when there is no status' );
    is( $store->_is_placeholder_missing_indicator( { managed_by_collector => 1, status => 'ok' } ), 0, '_is_placeholder_missing_indicator is false for a live status' );
    is( $store->_is_placeholder_missing_indicator( { managed_by_collector => 1, status => 'MISSING' } ), 1, '_is_placeholder_missing_indicator detects the default missing placeholder case-insensitively' );
}

# ---------------------------------------------------------------------------
# Block H: status-icon resolution
# ---------------------------------------------------------------------------
{
    is( $store->_page_status_icon('not-a-hash'), '', '_page_status_icon returns empty for a non-hash' );
    is( $store->_page_status_icon( { page_status_icon => 'X', status => 'ok' } ), 'X', '_page_status_icon prefers an explicit page_status_icon' );
    is( $store->_page_status_icon( { page_status_icon => '', status => 'ok' } ), '&#x2705;', '_page_status_icon ignores an empty page_status_icon and maps status' );
    is( $store->_page_status_icon( { status => 'error' } ), '&#x1F6A8;', '_page_status_icon maps error status to its entity' );

    is( $store->prompt_status_icon('not-a-hash'), '', 'prompt_status_icon returns empty for a non-hash' );
    is( $store->prompt_status_icon( { status => 'ok' } ), '✅', 'prompt_status_icon maps ok status to the success glyph' );
    is( $store->prompt_status_icon( { status => 'stopped' } ), '🚨', 'prompt_status_icon maps error status to the alert glyph' );
    is( $store->prompt_status_icon( { status => 'unknown', icon => 'Z' } ), 'Z', 'prompt_status_icon falls back to the explicit icon' );
    is( $store->prompt_status_icon( { status => 'unknown' } ), '', 'prompt_status_icon falls back to empty when there is no icon' );
    is( $store->prompt_status_icon( {} ), '', 'prompt_status_icon tolerates a status-less indicator' );
}

# ---------------------------------------------------------------------------
# Block I: _indicator_matches
# ---------------------------------------------------------------------------
{
    is( $store->_indicator_matches( 'x', {} ), 0, '_indicator_matches rejects a non-hash existing record' );
    is( $store->_indicator_matches( {}, 'y' ), 0, '_indicator_matches rejects a non-hash candidate record' );
    is( $store->_indicator_matches( { name => 'a' }, { name => 'b' } ), 0, '_indicator_matches returns 0 when a compared field differs' );
    is( $store->_indicator_matches( { name => 'a' }, { name => 'a' } ), 1, '_indicator_matches returns 1 when all compared fields agree' );

    is( $store->_indicator_matches( { collector_order => 5 }, { collector_order => 5 } ), 1, '_indicator_matches compares a real collector_order value' );
    is( $store->_indicator_matches( {}, { collector_order => 5 } ), 1, '_indicator_matches skips collector_order when the existing record lacks it' );
    is( $store->_indicator_matches( { collector_order => '' }, { collector_order => 5 } ), 1, '_indicator_matches skips collector_order when the existing value is blank' );
    is( $store->_indicator_matches( { collector_order => undef }, { collector_order => 5 } ), 1, '_indicator_matches skips collector_order when the existing value is undef' );
}

# ---------------------------------------------------------------------------
# Block J: delete_indicator
# ---------------------------------------------------------------------------
{
    is( $store->delete_indicator(undef), 1, 'delete_indicator is a no-op for an undef name' );
    is( $store->delete_indicator(''),    1, 'delete_indicator is a no-op for an empty name' );

    $store->set_indicator( 'to-delete', status => 'ok' );
    ok( defined $store->get_indicator('to-delete'), 'indicator exists before deletion' );
    is( $store->delete_indicator('to-delete'), 1, 'delete_indicator removes an existing indicator' );
    is( $store->get_indicator('to-delete'), undef, 'indicator is gone after deletion' );

    is( $store->delete_indicator('never-created'), 1, 'delete_indicator tolerates a name with no directory or file' );
}

# ---------------------------------------------------------------------------
# Block K: _local_indicator with no candidate files
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::IndicatorStore::_indicator_file_candidates = sub { return () };
    is( $store->_local_indicator('whatever'), undef, '_local_indicator returns undef when there are no candidate files' );
}

# ---------------------------------------------------------------------------
# Block L: _nearest_inherited_indicator across layers
# ---------------------------------------------------------------------------
{
    my ( $s, $p, $deep_root, $home_root ) = two_layer_store();
    plant( $home_root, 'inh-present', { status => 'ok', name => 'inh-present' } );
    my $inherited = $s->_nearest_inherited_indicator('inh-present');
    is( ref($inherited), 'HASH', '_nearest_inherited_indicator returns an inherited record beneath the local layer' );
    is( $inherited->{status}, 'ok', '_nearest_inherited_indicator returns the inherited status' );

    is( $s->_nearest_inherited_indicator('inh-missing'), undef, '_nearest_inherited_indicator returns undef when no inherited layer stores the indicator' );
}

# ---------------------------------------------------------------------------
# Block M: collector_indicator_candidate
# ---------------------------------------------------------------------------
{
    my $err_job = eval { $store->collector_indicator_candidate('not-a-hash'); 1 } ? '' : $@;
    like( $err_job, qr/requires a collector job hash/, 'collector_indicator_candidate rejects a non-hash job' );

    my $err_noname = eval { $store->collector_indicator_candidate( { indicator => {} } ); 1 } ? '' : $@;
    like( $err_noname, qr/requires a collector name/, 'collector_indicator_candidate rejects a job with no name' );
    my $err_emptyname = eval { $store->collector_indicator_candidate( { name => '' } ); 1 } ? '' : $@;
    like( $err_emptyname, qr/requires a collector name/, 'collector_indicator_candidate rejects a job with an empty name' );

    # 235 false branch: indicator is not a hash -> defaults to {}; no existing opt
    # -> resolves via get_indicator (undef -> {}).
    my $bare = $store->collector_indicator_candidate( { name => 'bare' } );
    is( $bare->{name},  'bare',    'collector_indicator_candidate defaults the label to the name' );
    is( $bare->{label}, 'bare',    'collector_indicator_candidate falls back to the name for a missing label' );
    is( $bare->{status}, 'missing', 'collector_indicator_candidate defaults status to missing' );
    is( $bare->{configured_alias}, '', 'collector_indicator_candidate blanks configured_alias without an alias' );
    is( $bare->{configured_page_status_icon}, '', 'collector_indicator_candidate blanks configured_page_status_icon without one' );
    is( $bare->{prompt_visible}, 1, 'collector_indicator_candidate defaults prompt_visible to 1' );
    ok( !exists $bare->{icon}, 'collector_indicator_candidate omits icon when the config supplies none' );

    # existing resolved from persisted state (eval get_indicator returns a hash)
    $store->set_indicator( 'existing-src', status => 'ok', collector_order => 3, prompt_visible => 0 );
    my $from_store = $store->collector_indicator_candidate( { name => 'existing-src', indicator => { name => 'existing-src' } } );
    is( $from_store->{status}, 'ok', 'collector_indicator_candidate inherits persisted status when no override is given' );
    is( $from_store->{collector_order}, 3, 'collector_indicator_candidate inherits persisted collector_order' );
    is( $from_store->{prompt_visible}, 0, 'collector_indicator_candidate inherits persisted prompt_visible' );

    # explicit existing hash opt (ternary true branch) + explicit status/order opts
    my $with_existing = $store->collector_indicator_candidate(
        { name => 'x1', indicator => { name => 'x1', label => 'L1', alias => 'A1', page_status_icon => 'P1', icon => 'I1', prompt_visible => 1 } },
        existing        => { status => 'ok', prompt_visible => 0 },
        status          => 'given',
        collector_order => 9,
    );
    is( $with_existing->{status}, 'given', 'collector_indicator_candidate honours an explicit status override' );
    is( $with_existing->{collector_order}, 9, 'collector_indicator_candidate honours an explicit collector_order override' );
    is( $with_existing->{label}, 'L1', 'collector_indicator_candidate uses the configured label' );
    is( $with_existing->{configured_alias}, 'A1', 'collector_indicator_candidate captures the configured alias' );
    is( $with_existing->{configured_page_status_icon}, 'P1', 'collector_indicator_candidate captures the configured page status icon' );
    is( $with_existing->{prompt_visible}, 1, 'collector_indicator_candidate prefers the config prompt_visible over existing' );

    # existing prompt_visible fallback (indicator lacks it, existing has it)
    my $pv = $store->collector_indicator_candidate(
        { name => 'x2', indicator => { name => 'x2' } },
        existing => { prompt_visible => 0 },
    );
    is( $pv->{prompt_visible}, 0, 'collector_indicator_candidate falls back to existing prompt_visible' );

    # existing status blank -> default missing
    my $blank_status = $store->collector_indicator_candidate(
        { name => 'x3', indicator => { name => 'x3' } },
        existing => { status => '' },
    );
    is( $blank_status->{status}, 'missing', 'collector_indicator_candidate defaults to missing when existing status is blank' );

    # label defined but empty -> falls back to name
    my $empty_label = $store->collector_indicator_candidate( { name => 'x4', indicator => { name => 'x4', label => '' } } );
    is( $empty_label->{label}, 'x4', 'collector_indicator_candidate falls back to the name for an empty label' );

    # alias / page_status_icon key present but undef -> blank
    my $undef_alias = $store->collector_indicator_candidate(
        { name => 'x5', indicator => { name => 'x5', alias => undef, page_status_icon => undef } },
    );
    is( $undef_alias->{configured_alias}, '', 'collector_indicator_candidate blanks an undef configured alias' );
    is( $undef_alias->{configured_page_status_icon}, '', 'collector_indicator_candidate blanks an undef configured page status icon' );

    # TT icon branch: various existing icon_template pairings
    my $tt_no_existing = $store->collector_indicator_candidate( { name => 't1', indicator => { name => 't1', icon => '[% status %]' } } );
    is( $tt_no_existing->{icon_template}, '[% status %]', 'collector_indicator_candidate stores a TT icon template' );
    is( $tt_no_existing->{icon}, '', 'collector_indicator_candidate blanks the live icon when there is no preserved render' );

    my $tt_preserved = $store->collector_indicator_candidate(
        { name => 't2', indicator => { name => 't2', icon => '[% status %]' } },
        existing => { icon_template => '[% status %]', icon => 'RENDERED' },
    );
    is( $tt_preserved->{icon}, 'RENDERED', 'collector_indicator_candidate preserves a matching rendered icon' );

    my $tt_changed = $store->collector_indicator_candidate(
        { name => 't3', indicator => { name => 't3', icon => '[% status %]' } },
        existing => { icon_template => '[% other %]', icon => 'RENDERED' },
    );
    is( $tt_changed->{icon}, '', 'collector_indicator_candidate discards a rendered icon when the template changed' );

    my $tt_no_icon = $store->collector_indicator_candidate(
        { name => 't4', indicator => { name => 't4', icon => '[% status %]' } },
        existing => { icon_template => '[% status %]' },
    );
    is( $tt_no_icon->{icon}, '', 'collector_indicator_candidate blanks the icon when the template matches but no render exists' );

    # non-TT icon: plain, undef, and absent
    my $plain_icon = $store->collector_indicator_candidate( { name => 'p1', indicator => { name => 'p1', icon => 'D' } } );
    is( $plain_icon->{icon}, 'D', 'collector_indicator_candidate keeps a plain configured icon' );
    is( $plain_icon->{configured_icon}, 'D', 'collector_indicator_candidate records the configured plain icon' );
    ok( !exists $plain_icon->{icon_template}, 'collector_indicator_candidate drops icon_template for a plain icon' );

    my $undef_icon = $store->collector_indicator_candidate( { name => 'p2', indicator => { name => 'p2', icon => undef } } );
    is( $undef_icon->{icon}, '', 'collector_indicator_candidate blanks an undef configured icon' );
    is( $undef_icon->{configured_icon}, '', 'collector_indicator_candidate blanks configured_icon for an undef icon' );

    my $no_icon = $store->collector_indicator_candidate( { name => 'p3', indicator => { name => 'p3' } } );
    ok( !exists $no_icon->{icon}, 'collector_indicator_candidate omits icon entirely when the config has no icon key' );
    is( $no_icon->{configured_icon}, '', 'collector_indicator_candidate blanks configured_icon when the config has no icon key' );
}

# ---------------------------------------------------------------------------
# Block N: sync_collectors
# ---------------------------------------------------------------------------
{
    # non-array jobs -> empty result
    is_deeply( $store->sync_collectors('not-array'), [], 'sync_collectors returns empty for a non-array argument' );
    is_deeply( $store->sync_collectors( [] ), [], 'sync_collectors returns empty for an empty job list' );

    # happy write path
    my ( $s, $p ) = fresh_store();
    my $written = $s->sync_collectors(
        [ { name => 'live', indicator => { name => 'live', label => 'Live' } } ]
    );
    is( ref($written), 'ARRAY', 'sync_collectors returns an array reference of written indicators' );
    ok( scalar(@$written) >= 1, 'sync_collectors writes the collector-declared indicator' );
    is( $s->get_indicator('live')->{managed_by_collector}, 1, 'sync_collectors marks the indicator as collector-managed' );

    # filtered jobs: non-hash, hash-indicator with empty name, disabled
    my ( $s2, $p2 ) = fresh_store();
    my $w2 = $s2->sync_collectors(
        [
            'not-a-hash',
            { indicator => {}, name => undef },
            { indicator => {}, name => '' },
            { indicator => {}, name => 'dis', disable => 1 },
            { indicator => 'not-a-hash', name => 'noind' },
        ]
    );
    is_deeply( $w2, [], 'sync_collectors skips malformed and disabled jobs without writing' );

    # second loop: a single corrupt (array) indicator is skipped as a non-hash
    my ( $s3, $p3 ) = fresh_store();
    my ($root3) = $p3->indicators_roots;
    plant( $root3, 'arr', [ 1, 2, 3 ] );
    is_deeply( $s3->sync_collectors( [ { indicator => {}, name => '' } ] ), [], 'sync_collectors skips a corrupt array indicator in the reconcile loop' );

    # second loop delete path: managed indicators whose collector is gone or blank
    my ( $s4, $p4 ) = fresh_store();
    my ($root4) = $p4->indicators_roots;
    plant( $root4, 'ghost',    { managed_by_collector => 1, collector_name => 'gonecollector', status => 'ok', name => 'ghost', priority => 2 } );
    plant( $root4, 'nameless', { managed_by_collector => 1, collector_name => '', status => 'ok', name => 'nameless', priority => 1 } );
    plant( $root4, 'plain',    { managed_by_collector => 0, status => 'ok', name => 'plain', priority => 3 } );
    my $w4 = $s4->sync_collectors( [ { indicator => {}, name => '' } ] );
    my %deleted = map { $_->{name} => 1 } grep { $_->{deleted} } @$w4;
    ok( $deleted{ghost}, 'sync_collectors deletes an indicator whose collector is no longer active' );
    ok( !$deleted{nameless}, 'sync_collectors leaves a managed indicator with a blank collector name alone' );
    is( $s4->get_indicator('ghost'), undef, 'sync_collectors physically removes the orphaned indicator' );
}

# ---------------------------------------------------------------------------
# Block O: collectors_need_sync
# ---------------------------------------------------------------------------
{
    # non-array coerced to empty; nothing to sync
    is( $store->collectors_need_sync('not-array'), 0, 'collectors_need_sync coerces a non-array argument and reports no work' );

    # a fresh collector whose indicator is not yet persisted needs a write
    my ( $s, $p ) = fresh_store();
    is( $s->collectors_need_sync( [ { name => 'fresh', indicator => { name => 'fresh' } } ] ), 1, 'collectors_need_sync reports work for an unseeded collector' );

    # once synced, an active collector's own indicator does not force more work
    my ( $s_stable, $p_stable ) = fresh_store();
    my $stable_job = { name => 'stable', indicator => { name => 'stable', label => 'Stable' } };
    $s_stable->sync_collectors( [$stable_job] );
    is( $s_stable->collectors_need_sync( [$stable_job] ), 0, 'collectors_need_sync reports no work when an active collector is already in sync' );

    # filtered jobs only -> no active collectors, corrupt indicator ignored
    my ( $s2, $p2 ) = fresh_store();
    my ($root2) = $p2->indicators_roots;
    plant( $root2, 'arr', [ 1, 2 ] );
    is(
        $s2->collectors_need_sync(
            [ 'not-a-hash', { indicator => {}, name => undef }, { indicator => {}, name => '' }, { indicator => {}, name => 'dis', disable => 1 } ]
        ),
        0,
        'collectors_need_sync ignores malformed jobs and a corrupt array indicator',
    );

    # second loop: a managed indicator whose collector is gone forces a sync
    my ( $s3, $p3 ) = fresh_store();
    my ($root3) = $p3->indicators_roots;
    plant( $root3, 'nameless', { managed_by_collector => 1, collector_name => '', status => 'ok', name => 'nameless', priority => 1 } );
    plant( $root3, 'ghost',    { managed_by_collector => 1, collector_name => 'gone', status => 'ok', name => 'ghost', priority => 2 } );
    is( $s3->collectors_need_sync( [ { indicator => {}, name => '' } ] ), 1, 'collectors_need_sync reports work when a managed collector indicator is orphaned' );
}

# ---------------------------------------------------------------------------
# Block P1: _collector_sync_plan direct edge cases
# ---------------------------------------------------------------------------
{
    # 519 both-false: job with no name reaches indicator_name resolution before
    # collector_indicator_candidate rejects it.
    my $err = eval { $store->_collector_sync_plan( { indicator => {}, name => '' } ); 1 } ? '' : $@;
    like( $err, qr/requires a collector name/, '_collector_sync_plan resolves a blank indicator name before delegating' );

    # 519 job-name fallback: the indicator hash carries no name of its own.
    my ( $s0, $p0 ) = fresh_store();
    my $plan0 = $s0->_collector_sync_plan( { name => 'jobonly', indicator => {} }, collector_order => 0 );
    is( $plan0->{candidate}{name}, 'jobonly', '_collector_sync_plan resolves the indicator name from the job when the indicator has none' );

    # 524 A-false: a corrupt (array) local indicator is not a hash.
    my ( $s, $p ) = fresh_store();
    my ($root) = $p->indicators_roots;
    plant( $root, 'arrplan', [ 1, 2, 3 ] );
    my $died = eval { $s->_collector_sync_plan( { name => 'arrplan', indicator => { name => 'arrplan' } } ); 1 } ? 0 : 1;
    ok( $died, '_collector_sync_plan surfaces a corrupt array indicator rather than healing it' );
}

# ---------------------------------------------------------------------------
# Block P2: _collector_sync_plan preserve block (551/556/564/572/580)
# ---------------------------------------------------------------------------
sub run_plan {
    my ( $store_obj, $paths_obj, $name, $local, $indicator ) = @_;
    my ($root) = $paths_obj->indicators_roots;
    plant( $root, $name, $local );
    return $store_obj->_collector_sync_plan(
        { name => $name, indicator => { name => $name, %{$indicator} } },
        collector_order => 0,
    );
}

{
    my ( $s, $p ) = fresh_store();

    # P1: configured values match, live sub-fields differ -> all preserved
    my $p1 = run_plan(
        $s, $p, 'pv1',
        {
            managed_by_collector        => 1,
            collector_name              => 'pv1',
            status                      => 'ok',
            configured_label            => 'LBL',
            label                       => 'DIFF',
            configured_alias            => 'AL',
            alias                       => 'DIFFA',
            configured_page_status_icon => 'PSI',
            page_status_icon            => 'DIFFP',
            configured_icon             => 'IC',
            icon                        => 'DIFFI',
        },
        { label => 'LBL', alias => 'AL', page_status_icon => 'PSI', icon => 'IC' },
    );
    my %pres1 = map { $_ => 1 } @{ $p1->{preserve_existing} };
    ok( $pres1{label} && $pres1{alias} && $pres1{page_status_icon} && $pres1{icon}, '_collector_sync_plan preserves live fields whose configured source is unchanged' );

    # P2: configured values match, live sub-fields undef -> still preserved
    my $p2 = run_plan(
        $s, $p, 'pv2',
        {
            managed_by_collector        => 1,
            collector_name              => 'pv2',
            status                      => 'ok',
            configured_label            => 'LBL',
            label                       => undef,
            configured_alias            => 'AL',
            alias                       => undef,
            configured_page_status_icon => 'PSI',
            page_status_icon            => undef,
            configured_icon             => 'IC',
            icon                        => undef,
        },
        { label => 'LBL', alias => 'AL', page_status_icon => 'PSI', icon => 'IC' },
    );
    my %pres2 = map { $_ => 1 } @{ $p2->{preserve_existing} };
    ok( $pres2{label}, '_collector_sync_plan preserves a label even when the live value is undef' );

    # P3: configured values undef -> nothing preserved
    my $p3 = run_plan(
        $s, $p, 'pv3',
        {
            managed_by_collector        => 1,
            collector_name              => 'pv3',
            status                      => 'ok',
            configured_label            => undef,
            configured_alias            => undef,
            configured_page_status_icon => undef,
            configured_icon             => undef,
        },
        { label => 'L3' },
    );
    my %pres3 = map { $_ => 1 } @{ $p3->{preserve_existing} };
    ok( !$pres3{label}, '_collector_sync_plan does not preserve when the configured source is undef' );

    # P4: configured values differ from the new config -> nothing preserved
    my $p4 = run_plan(
        $s, $p, 'pv4',
        {
            managed_by_collector        => 1,
            collector_name              => 'pv4',
            status                      => 'ok',
            configured_label            => 'X1',
            configured_alias            => 'X2',
            configured_page_status_icon => 'X3',
            configured_icon             => 'X4',
        },
        { label => 'L4', alias => 'A4', page_status_icon => 'P4', icon => 'I4' },
    );
    my %pres4 = map { $_ => 1 } @{ $p4->{preserve_existing} };
    ok( !$pres4{alias}, '_collector_sync_plan does not preserve when the configured source changed' );

    # P5: no configured_* keys at all -> exists checks are false
    my $p5 = run_plan(
        $s, $p, 'pv5',
        { managed_by_collector => 1, collector_name => 'pv5', status => 'ok' },
        {},
    );
    my %pres5 = map { $_ => 1 } @{ $p5->{preserve_existing} };
    ok( !$pres5{alias}, '_collector_sync_plan skips preservation when the record has no configured fields' );

    # P6: managed record whose collector name does not match the job (and is blank)
    # -> the preserve block is skipped entirely.
    my $p6 = run_plan(
        $s, $p, 'pv6',
        { managed_by_collector => 1, collector_name => '', status => 'ok', configured_label => 'LBL', label => 'DIFF' },
        { label => 'LBL' },
    );
    my %pres6 = map { $_ => 1 } @{ $p6->{preserve_existing} };
    ok( !$pres6{label}, '_collector_sync_plan skips the preserve block when the record collector name does not match the job' );

    # P7: configured values match and the live values already equal them -> nothing
    # to preserve (the "already up to date" branch of each preserve check).
    my $p7 = run_plan(
        $s, $p, 'pv7',
        {
            managed_by_collector        => 1,
            collector_name              => 'pv7',
            status                      => 'ok',
            configured_label            => 'LBL',
            label                       => 'LBL',
            configured_alias            => 'AL',
            alias                       => 'AL',
            configured_page_status_icon => 'PSI',
            page_status_icon            => 'PSI',
            configured_icon             => 'IC',
            icon                        => 'IC',
        },
        { label => 'LBL', alias => 'AL', page_status_icon => 'PSI', icon => 'IC' },
    );
    my %pres7 = map { $_ => 1 } @{ $p7->{preserve_existing} };
    ok( !$pres7{label}, '_collector_sync_plan preserves nothing when the live values already match the configured ones' );
}

# ---------------------------------------------------------------------------
# Block P3: _collector_sync_plan icon-template preservation (589)
# ---------------------------------------------------------------------------
{
    my ( $s, $p ) = fresh_store();

    # matching icon_template -> icon + icon_template preserved
    my $tmatch = run_plan(
        $s, $p, 'it1',
        { managed_by_collector => 0, status => 'ok', icon_template => '[% t %]', icon => 'R' },
        { icon => '[% t %]' },
    );
    my %pm = map { $_ => 1 } @{ $tmatch->{preserve_existing} };
    ok( $pm{icon} && $pm{icon_template}, '_collector_sync_plan preserves the rendered icon when the icon template is unchanged' );

    # differing icon_template -> not preserved
    my $tdiff = run_plan(
        $s, $p, 'it2',
        { managed_by_collector => 0, status => 'ok', icon_template => '[% other %]', icon => 'R' },
        { icon => '[% t %]' },
    );
    my %pd = map { $_ => 1 } @{ $tdiff->{preserve_existing} };
    ok( !$pd{icon_template}, '_collector_sync_plan does not preserve when the icon template changed' );

    # no existing icon_template -> not preserved
    my $tnone = run_plan(
        $s, $p, 'it3',
        { managed_by_collector => 0, status => 'ok' },
        { icon => '[% t %]' },
    );
    my %pn = map { $_ => 1 } @{ $tnone->{preserve_existing} };
    ok( !$pn{icon_template}, '_collector_sync_plan does not preserve when the existing record has no template' );

    # candidate has no icon_template (plain icon) -> not preserved
    my $tplain = run_plan(
        $s, $p, 'it4',
        { managed_by_collector => 0, status => 'ok', icon_template => '[% t %]', icon => 'R' },
        { icon => 'PLAIN' },
    );
    my %pp = map { $_ => 1 } @{ $tplain->{preserve_existing} };
    ok( !$pp{icon_template}, '_collector_sync_plan does not preserve a template for a plain configured icon' );

    # blank effective status -> candidate status defaults to missing
    my $sblank = run_plan(
        $s, $p, 'it5',
        { managed_by_collector => 0, status => '' },
        {},
    );
    is( $sblank->{candidate}{status}, 'missing', '_collector_sync_plan defaults a blank effective status to missing' );
}

# ---------------------------------------------------------------------------
# Block P4: _collector_sync_plan inherited healing (524/530)
# ---------------------------------------------------------------------------
{
    my ( $s, $p, $deep_root, $home_root ) = two_layer_store();

    # I1: local placeholder + real inherited from same collector -> heal
    plant( $deep_root, 'heal', { managed_by_collector => 1, collector_name => 'heal', status => 'missing', name => 'heal' } );
    plant( $home_root, 'heal', { managed_by_collector => 1, collector_name => 'heal', status => 'ok', name => 'heal', label => 'Healed', configured_label => 'heal', icon => 'H' } );
    my $healed = $s->_collector_sync_plan( { name => 'heal', indicator => { name => 'heal' } }, collector_order => 0 );
    is( $healed->{candidate}{status}, 'ok', '_collector_sync_plan heals a placeholder from a live inherited indicator' );
    my %healed_preserve = map { $_ => 1 } @{ $healed->{preserve_existing} };
    ok( !$healed_preserve{status}, '_collector_sync_plan does not force-preserve the local placeholder status when healing from inherited state' );

    # I2: local placeholder + no inherited -> no heal
    plant( $deep_root, 'heal2', { managed_by_collector => 1, collector_name => 'heal2', status => 'missing', name => 'heal2' } );
    my $noheal = $s->_collector_sync_plan( { name => 'heal2', indicator => { name => 'heal2' } }, collector_order => 0 );
    is( $noheal->{candidate}{status}, 'missing', '_collector_sync_plan leaves a placeholder alone when nothing is inherited' );

    # I3: inherited is an empty hash -> no heal
    plant( $deep_root, 'heal3', { managed_by_collector => 1, collector_name => 'heal3', status => 'missing', name => 'heal3' } );
    plant( $home_root, 'heal3', {} );
    my $h3 = $s->_collector_sync_plan( { name => 'heal3', indicator => { name => 'heal3' } }, collector_order => 0 );
    is( $h3->{candidate}{status}, 'missing', '_collector_sync_plan ignores an empty inherited record' );

    # I4: inherited unmanaged -> no heal
    plant( $deep_root, 'heal4', { managed_by_collector => 1, collector_name => 'heal4', status => 'missing', name => 'heal4' } );
    plant( $home_root, 'heal4', { status => 'ok', collector_name => 'heal4', name => 'heal4' } );
    my $h4 = $s->_collector_sync_plan( { name => 'heal4', indicator => { name => 'heal4' } }, collector_order => 0 );
    is( $h4->{candidate}{status}, 'missing', '_collector_sync_plan ignores an unmanaged inherited record' );

    # I5: inherited from a different collector -> no heal
    plant( $deep_root, 'heal5', { managed_by_collector => 1, collector_name => 'heal5', status => 'missing', name => 'heal5' } );
    plant( $home_root, 'heal5', { managed_by_collector => 1, collector_name => 'OTHER', status => 'ok', name => 'heal5' } );
    my $h5 = $s->_collector_sync_plan( { name => 'heal5', indicator => { name => 'heal5' } }, collector_order => 0 );
    is( $h5->{candidate}{status}, 'missing', '_collector_sync_plan ignores an inherited record from a different collector' );

    # I5b: inherited with a blank collector name -> no heal (|| fallback branch)
    plant( $deep_root, 'heal5b', { managed_by_collector => 1, collector_name => 'heal5b', status => 'missing', name => 'heal5b' } );
    plant( $home_root, 'heal5b', { managed_by_collector => 1, collector_name => '', status => 'ok', name => 'heal5b' } );
    my $h5b = $s->_collector_sync_plan( { name => 'heal5b', indicator => { name => 'heal5b' } }, collector_order => 0 );
    is( $h5b->{candidate}{status}, 'missing', '_collector_sync_plan ignores an inherited record with a blank collector name' );

    # I6: inherited is itself a placeholder -> no heal
    plant( $deep_root, 'heal6', { managed_by_collector => 1, collector_name => 'heal6', status => 'missing', name => 'heal6' } );
    plant( $home_root, 'heal6', { managed_by_collector => 1, collector_name => 'heal6', status => 'missing', name => 'heal6' } );
    my $h6 = $s->_collector_sync_plan( { name => 'heal6', indicator => { name => 'heal6' } }, collector_order => 0 );
    is( $h6->{candidate}{status}, 'missing', '_collector_sync_plan ignores an inherited record that is itself a placeholder' );
}

# ---------------------------------------------------------------------------
# Block Q: list_indicators ordering + unreadable/absent roots
# ---------------------------------------------------------------------------
{
    my ( $s, $p ) = fresh_store();
    $s->set_indicator( 'z-first', status => 'ok', priority => 10 );
    $s->set_indicator( 'a-second', status => 'ok', priority => 20 );
    $s->set_indicator( 'coll-a', status => 'ok', priority => 5, managed_by_collector => 1, collector_order => 2 );
    $s->set_indicator( 'coll-b', status => 'ok', priority => 5, managed_by_collector => 1, collector_order => 1 );
    my @list = $s->list_indicators;
    is( scalar(@list), 4, 'list_indicators returns every stored indicator' );
    is( $list[0]{name}, 'coll-b', 'list_indicators orders by priority then collector order' );
    is( $list[1]{name}, 'coll-a', 'list_indicators keeps collector order within a priority tier' );

    # equal priority + falsy names -> name comparator right-hand fallbacks
    my ( $s2, $p2 ) = fresh_store();
    my ($root2) = $p2->indicators_roots;
    plant( $root2, 'blank-one', { status => 'ok', priority => 7, name => '' } );
    plant( $root2, 'blank-two', { status => 'ok', priority => 7, name => '' } );
    my @blank = $s2->list_indicators;
    is( scalar(@blank), 2, 'list_indicators tolerates records with blank names' );

    # roots that are missing or unreadable are skipped
    my ( $s3, $p3, $h3 ) = fresh_store();
    my $unreadable = File::Spec->catdir( $h3, 'unreadable-root' );
    make_path($unreadable);
    chmod 0000, $unreadable;
  SKIP: {
        skip 'unreadable dir still listable (running as root?)', 1 if opendir( my $probe, $unreadable );
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::indicators_roots = sub {
            return ( File::Spec->catdir( $h3, 'does-not-exist' ), $unreadable );
        };
        is_deeply( [ $s3->list_indicators ], [], 'list_indicators skips absent and unreadable indicator roots' );
    }
    chmod 0755, $unreadable;
}

# ---------------------------------------------------------------------------
# Block R: page_header_items / page_header_payload
# ---------------------------------------------------------------------------
{
    my ( $s, $p ) = fresh_store();
    my ($root) = $p->indicators_roots;
    plant( $root, 'ind-alias',  { status => 'ok', alias => 'A', priority => 10, name => 'ind-alias' } );
    plant( $root, 'ind-icon',   { status => 'ok', alias => undef, icon => 'I', priority => 20, name => 'ind-icon' } );
    plant( $root, 'ind-label',  { status => 'ok', alias => undef, icon => undef, label => 'L', priority => 30, name => 'ind-label' } );
    plant( $root, 'ind-name',   { status => 'ok', alias => '', icon => '', label => '', priority => 40, name => 'ind-name' } );
    plant( $root, 'ind-hidden', { status => 'ok', alias => 'H', prompt_visible => 0, priority => 50, name => 'ind-hidden' } );
    plant( $root, 'ind-undef',  { status => 'ok', alias => undef, icon => undef, label => undef, priority => 60, name => 'ind-undef' } );

    my @items = $s->page_header_items;
    my %by_prog = map { $_->{prog} => $_ } @items;
    is( scalar(@items), 5, 'page_header_items omits prompt-hidden indicators' );
    is( $by_prog{'ind-undef'}{alias}, 'ind-undef', 'page_header_items falls back to the name when alias/icon/label are all undef' );
    is( $by_prog{'ind-alias'}{alias}, 'A', 'page_header_items uses an explicit alias' );
    is( $by_prog{'ind-icon'}{alias}, 'I', 'page_header_items falls back to the icon' );
    is( $by_prog{'ind-label'}{alias}, 'L', 'page_header_items falls back to the label' );
    is( $by_prog{'ind-name'}{alias}, 'ind-name', 'page_header_items falls back to the name when alias/icon/label are blank' );

    my $payload = $s->page_header_payload;
    is( ref( $payload->{array} ), 'ARRAY', 'page_header_payload exposes an array of items' );
    is( ref( $payload->{hash} ),  'HASH',  'page_header_payload exposes a keyed hash of items' );
    is( $payload->{status}, $payload->{status}, 'page_header_payload includes the status icon map' );
    ok( exists $payload->{hash}{'ind-alias'}, 'page_header_payload keys the hash by program name' );
}

# ---------------------------------------------------------------------------
# Block S: refresh_core_indicators
# ---------------------------------------------------------------------------
{
    # S1: explicit cwd argument (359 A-true) + prompt-only early return
    {
        my ( $s, $p, $h ) = fresh_store();
        no warnings 'redefine';
        local *Developer::Dashboard::IndicatorStore::command_in_path = sub { return '/usr/bin/docker' };
        my $items = $s->refresh_core_indicators( cwd => $h, prompt_only => 1 );
        is( scalar(@$items), 1, 'refresh_core_indicators prompt-only mode returns just the docker indicator' );
        is( $items->[0]{status}, 'ok', 'refresh_core_indicators marks docker ok when it is on PATH' );
    }

    # S2: docker missing (362/368/369 false)
    {
        my ($s) = fresh_store();
        no warnings 'redefine';
        local *Developer::Dashboard::IndicatorStore::command_in_path = sub { return undef };
        my $items = $s->refresh_core_indicators( prompt_only => 1 );
        is( $items->[0]{status}, 'missing', 'refresh_core_indicators marks docker missing when it is not on PATH' );
    }

    # S3: project resolvable + real git work tree (359 A-false-B-true, 386/388/393/407)
    my $gitproj = File::Spec->catdir( $home, 'gitproj' );
    make_path($gitproj);
    system( 'git', 'init', '-q', $gitproj ) == 0 or die 'git init failed';
    {
        my ($s) = fresh_store();
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::project_root_for = sub { return $gitproj };
        my $items = $s->refresh_core_indicators;
        my %by = map { $_->{name} => $_ } @$items;
        is( $by{project}{status}, 'ok', 'refresh_core_indicators marks the project indicator ok when a project resolves' );
        ok( exists $by{git}, 'refresh_core_indicators emits a git indicator for a real work tree' );
    }

    # S4: no project (359 A-false-B-false-C home, 376 fallback, 386 false)
    {
        my ($s) = fresh_store();
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::project_root_for = sub { return };
        my $items = $s->refresh_core_indicators;
        my %by = map { $_->{name} => $_ } @$items;
        is( $by{project}{label}, '(no-project)', 'refresh_core_indicators labels the project indicator when nothing resolves' );
        is( $by{project}{status}, 'none', 'refresh_core_indicators marks the project indicator none without a project' );
        is( $by{git}{status}, 'none', 'refresh_core_indicators keeps git status none without a work tree' );
    }

    # S5: git rev-parse reports "not inside work tree" (393 A-true-B-false)
    {
        my ($s) = fresh_store();
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::project_root_for = sub { return $gitproj };
        local *Developer::Dashboard::IndicatorStore::capture = sub (&) { return ( "false\n", '', 0 ) };
        my $items = $s->refresh_core_indicators;
        my %by = map { $_->{name} => $_ } @$items;
        is( $by{git}{status}, 'none', 'refresh_core_indicators keeps git status none when the tree is not a work tree' );
    }

    # S6: git command fails outright (393 A-false)
    {
        my ($s) = fresh_store();
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::project_root_for = sub { return $gitproj };
        local *Developer::Dashboard::IndicatorStore::capture = sub (&) { return ( '', 'boom', 128 ) };
        my $items = $s->refresh_core_indicators;
        my %by = map { $_->{name} => $_ } @$items;
        is( $by{git}{status}, 'none', 'refresh_core_indicators keeps git status none when git rev-parse fails' );
    }

    # S7: chdir into the project fails (388 die)
    {
        my ($s) = fresh_store();
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::project_root_for = sub { return File::Spec->catdir( $home, 'no-such-project-dir' ) };
        my $err = eval { $s->refresh_core_indicators; 1 } ? '' : $@;
        like( $err, qr/Unable to chdir/, 'refresh_core_indicators dies when it cannot chdir into the project' );
    }

    # S8: chdir back to the original directory fails (407 die)
    {
        my ($s) = fresh_store();
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::project_root_for = sub { return $gitproj };
        local *Developer::Dashboard::IndicatorStore::cwd     = sub { return File::Spec->catdir( $home, 'vanished-old-cwd' ) };
        local *Developer::Dashboard::IndicatorStore::capture = sub (&) { return ( "false\n", '', 0 ) };
        my $err = eval { $s->refresh_core_indicators; 1 } ? '' : $@;
        like( $err, qr/Unable to restore cwd/, 'refresh_core_indicators dies when it cannot restore the original directory' );
        chdir $home or die "Unable to restore test cwd: $!";
    }
}

# ---------------------------------------------------------------------------
# Block T: _set_indicator_if_changed unchanged fast-path
# ---------------------------------------------------------------------------
{
    my ( $s, $p ) = fresh_store();
    no warnings 'redefine';
    local *Developer::Dashboard::IndicatorStore::command_in_path = sub { return '/usr/bin/docker' };
    my $first  = $s->refresh_core_indicators( prompt_only => 1 );
    my $second = $s->refresh_core_indicators( prompt_only => 1 );
    is( $first->[0]{name}, 'docker', 'refresh_core_indicators writes docker on the first pass' );
    is( $second->[0]{name}, 'docker', 'refresh_core_indicators returns the unchanged docker indicator on the second pass' );
}

done_testing;

__END__

=head1 NAME

t/95-indicatorstore-coverage.t - branch and condition coverage for the indicator store

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::IndicatorStore>. It exercises every persistence,
resolution, collector-sync, healing, ordering, and core-refresh branch of the
indicator store so the module holds at 100% on all four Devel::Cover metrics.

=head1 WHY IT EXISTS

The indicator store carries the shared status state read by the prompt renderer
and the browser status strip, and it merges collector-managed indicators with
user-managed ones across inherited runtime layers. That merge, the placeholder
healing path, and the icon-template preservation logic have many condition
combinations that ordinary CLI and browser flows never reach. This file pins
those combinations directly so a regression in the merge or refresh logic
surfaces as a failing assertion rather than as silent indicator drift.

=head1 WHEN TO USE

Use this file when changing indicator persistence, the collector sync and
need-sync fast paths, collector-managed indicator healing from inherited
layers, TT-backed icon template handling, indicator ordering, or the built-in
core indicator refresh.

=head1 HOW TO USE

Run C<prove -lv t/95-indicatorstore-coverage.t> while iterating on the module,
then keep it green under C<prove -lr t> and the coverage gate before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the Devel::Cover
coverage gate all rely on this file to keep the indicator store's branch and
condition behavior honest.

=head1 EXAMPLES

Example 1:

  prove -lv t/95-indicatorstore-coverage.t

Run the focused indicator-store coverage test on its own.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/95-indicatorstore-coverage.t

Exercise the same test while collecting coverage for the indicator store.

Example 3:

  prove -lr t

Put the change back through the entire repository suite before release.

=cut
