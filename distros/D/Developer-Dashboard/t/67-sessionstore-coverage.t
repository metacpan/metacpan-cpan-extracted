#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

# DD-600: the CORE::GLOBAL::rename override must be installed before
# Developer::Dashboard::SessionStore is compiled so the module's own rename
# call in create() resolves through this intercept - matching DD-599's
# established pattern in t/82-auth-coverage.t / t/54-hunt-collector.t.
# Unlike DD-599's username-keyed final path, create()'s final path is keyed
# by a random session_id only known AFTER create() returns, so this records
# every observed rename's target and the SOURCE file's permission mode at
# that exact moment (rather than pre-filtering by a known target); the test
# correlates the last recorded rename against create()'s returned session_id
# afterward.
our $DD600_OBSERVED_RENAME_TO;
our $DD600_OBSERVED_RENAME_MODE;

BEGIN {
    *CORE::GLOBAL::rename = sub {
        my ( $from, $to ) = @_;
        $DD600_OBSERVED_RENAME_TO   = $to;
        $DD600_OBSERVED_RENAME_MODE = ( stat($from) )[2] & 07777;
        return CORE::rename( $from, $to );
    };
}

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::JSON qw(json_encode);

# Hermetic, isolated runtime rooted in a throwaway HOME. The session store
# resolves its state root from the deepest .developer-dashboard layer above the
# current working directory, so the test must chdir into the temp home before
# constructing anything.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $store = Developer::Dashboard::SessionStore->new( paths => $paths );

# --- constructor and create argument guards -----------------------------
{
    my $err = eval { Developer::Dashboard::SessionStore->new(); 1 } ? '' : $@;
    like( $err, qr/Missing path registry/, 'new dies when no path registry is supplied' );

    my $create_err = eval { $store->create(); 1 } ? '' : $@;
    like( $create_err, qr/Missing username/, 'create dies when no username is supplied' );
}

# --- get/delete empty-and-undefined session id guards -------------------
{
    is( scalar $store->get(undef), undef, 'get returns undef for an undefined session id' );
    is( scalar $store->get(''),    undef, 'get returns undef for an empty session id' );
    is( scalar $store->delete(undef), undef, 'delete short-circuits and returns nothing for an undefined session id' );
    is( scalar $store->delete(''),    undef, 'delete short-circuits and returns nothing for an empty session id' );
}

# --- from_cookie skips segments with undefined and empty keys -----------
{
    # ";x=y" yields a leading empty segment that splits into an undefined key,
    # and "=y" yields a segment whose key is defined but empty. Both must be
    # skipped without leaking a dashboard_session pair.
    is( scalar $store->from_cookie(';x=y'), undef, 'from_cookie skips a cookie segment whose key is undefined' );
    is( scalar $store->from_cookie('=y'),   undef, 'from_cookie skips a cookie segment whose key is the empty string' );
}

# --- private timestamp helpers: falsy ttl and malformed/undef input -----
{
    like(
        Developer::Dashboard::SessionStore::_iso8601_after(0),
        qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/,
        '_iso8601_after treats a falsy ttl as a zero-second offset from now',
    );
    is(
        Developer::Dashboard::SessionStore::_iso8601_to_epoch( undef, on_error => 'zero' ),
        0,
        '_iso8601_to_epoch returns 0 for an undefined timestamp',
    );
    is(
        Developer::Dashboard::SessionStore::_iso8601_to_epoch( 'not-a-timestamp', on_error => 'zero' ),
        0,
        '_iso8601_to_epoch returns 0 for a timestamp that does not match the ISO-8601 shape',
    );
}

# Helper: write a raw session record into the write-target session root so
# get()/from_cookie() can resolve it by id.
my $root = $paths->sessions_root;
my $write_session = sub {
    my ( $id, $record ) = @_;
    my $file = File::Spec->catfile( $root, "$id.json" );
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode($record);
    close $fh;
    return $file;
};

# --- from_cookie: DD-764 - a missing/empty/zero expiry fails CLOSED, the
#     same way a malformed one already does, rather than being treated as
#     "never expires". _iso8601_to_epoch returns 0 for all three shapes, so
#     dropping the truthiness guard on $session->{expires_at} is what makes
#     absence compare as long-expired instead of short-circuiting past the
#     comparison entirely. ---------------------------------------------
for my $case ( [ 'cover-empty-expiry', '' ], [ 'cover-zero-expiry', '0' ] ) {
    my ( $id, $expires_at ) = @$case;
    $write_session->(
        $id,
        {
            session_id  => $id,
            username    => "$id-user",
            role        => 'helper',
            remote_addr => '10.0.0.1',
            expires_at  => $expires_at,
        }
    );
    my $session = $store->from_cookie("dashboard_session=$id");
    is( $session, undef, "from_cookie rejects a session whose expires_at is '$expires_at' as expired, not eternal" );
}

# --- from_cookie: a request remote_addr with no stored remote_addr key
#     leaves the binding check inert ------------------------------------
{
    $write_session->(
        'cover-no-remote',
        {
            session_id => 'cover-no-remote',
            username   => 'no-remote-user',
            role       => 'helper',
            expires_at => '2999-01-01T00:00:00Z',
        }
    );
    my $session = $store->from_cookie( 'dashboard_session=cover-no-remote', remote_addr => '1.2.3.4' );
    is( ref $session, 'HASH', 'from_cookie returns a session that stores no remote_addr even when a request address is supplied' );
    is( $session->{username}, 'no-remote-user', 'from_cookie loads the crafted no-remote-addr session record' );
}

# --- from_cookie: a stored remote_addr with NO request remote_addr supplied
#     at all also leaves the binding check inert - this is the "defined
#     $args{remote_addr}" side of the guard, distinct from the stored-side
#     case immediately above. DD-764's own fix uncovered this arm: before,
#     a session with no expires_at was falsy at the truthiness guard and
#     fell through to this line; now it is deleted and returned early, so
#     the only path that used to reach here with no expires_at is gone.
#     Reach the same arm directly instead. ---------------------------
{
    $write_session->(
        'cover-no-request-addr',
        {
            session_id  => 'cover-no-request-addr',
            username    => 'no-request-addr-user',
            role        => 'helper',
            remote_addr => '10.0.0.1',
            expires_at  => '2999-01-01T00:00:00Z',
        }
    );
    my $session = $store->from_cookie('dashboard_session=cover-no-request-addr');
    is( ref $session, 'HASH', 'from_cookie skips remote-address binding when the caller supplies no remote_addr at all' );
    is( $session->{username}, 'no-request-addr-user', 'from_cookie loads the crafted no-request-addr session record' );
}

# --- from_cookie: a stored empty remote_addr disables address binding ---
{
    $write_session->(
        'cover-blank-remote',
        {
            session_id  => 'cover-blank-remote',
            username    => 'blank-remote-user',
            role        => 'helper',
            remote_addr => '',
            expires_at  => '2999-01-01T00:00:00Z',
        }
    );
    my $session = $store->from_cookie( 'dashboard_session=cover-blank-remote', remote_addr => '1.2.3.4' );
    is( ref $session, 'HASH', 'from_cookie skips remote-address binding when the stored remote_addr is the empty string' );
    is( $session->{username}, 'blank-remote-user', 'from_cookie loads the crafted blank-remote-addr session record' );
}

# --- get: a present but unreadable session file makes the open die ------
{
    my $record = $store->create( username => 'openfail-user', remote_addr => '127.0.0.1' );
    my $file   = File::Spec->catfile( $root, "$record->{session_id}.json" );
    ok( -f $file, 'created session file exists before the read-failure probe' );
  SKIP: {
        chmod 0000, $file or skip 'chmod not honored on this filesystem', 1;
        if ( open my $probe, '<', $file ) {
            close $probe or die "Unable to close probe on $file: $!";
            skip 'this process can read a mode-0000 session file, so the open failure cannot occur', 1;
        }

        my $err = eval { $store->get( $record->{session_id} ); 1 } ? '' : $@;
        like( $err, qr/Unable to read/, 'get dies when a present session file cannot be opened for reading' );
    }

    chmod 0600, $file or die "Unable to restore mode on $file: $!";
}

# --- create: an unwritable session file makes the open die --------------
{
    no warnings qw(redefine once);
    local *Developer::Dashboard::PathRegistry::sessions_root = sub {
        return File::Spec->catdir( $home, 'no-such-sessions-root' );
    };
    my $err = eval { $store->create( username => 'writefail-user' ); 1 } ? '' : $@;
    like( $err, qr/Unable to write/, 'create dies when the session file cannot be written' );
}

# --- create: the session record's PREDICTABLE final path must never become
# visible with loose permissions - a bare stat() after create() returns can't
# prove this (a later chmod always leaves the final state correct even with
# the bug), so this intercepts the rename that makes the file visible under
# its final name and checks the SOURCE file's permissions at that exact
# moment: by the time anything could observe the file at its predictable
# path, it must already be secured. ------------------------------------
{
    my $old_umask = umask(0);
    local $DD600_OBSERVED_RENAME_TO;
    local $DD600_OBSERVED_RENAME_MODE;
    my $record = $store->create( username => 'rename-observed-user', remote_addr => '127.0.0.1' );
    umask($old_umask);
    my $expected_file = $store->_session_file( $record->{session_id} );
    is( $DD600_OBSERVED_RENAME_TO, $expected_file,
        'DD-600: create renamed a source file into the predictable final session path (rename observed)' );
    is( sprintf( '%04o', $DD600_OBSERVED_RENAME_MODE // -1 ), '0600',
        'DD-600: the source file was already 0600 BEFORE the rename that made it visible at its final, predictable path - even under umask(0)' );
    $store->delete( $record->{session_id} );    # avoid polluting later state
}

# --- create: force the earlier open-stage die. _pending_session_file is
# pinned to a fixed path (rather than relying on the real pid/time-based
# name, which cannot be pre-staged reliably) so a directory can occupy it -
# matching Collector.pm::_pending_path's own override technique in
# t/89-collector-coverage.t and DD-599's t/82-auth-coverage.t. -----------
{
    my $target       = $store->_session_file('open-blocked-session');
    my $pending_path = "$target.blocked-open.pending";
    mkdir $pending_path or die "Unable to create $pending_path: $!";
    no warnings 'redefine';
    local *Developer::Dashboard::SessionStore::_pending_session_file = sub { return $pending_path };
    use warnings 'redefine';
    my $open_fail = eval { $store->create( username => 'open-blocked-user' ); 1 } ? '' : $@;
    like( $open_fail, qr/Unable to write \Q$pending_path\E/, 'create dies when the pending file cannot be opened' );
    rmdir $pending_path or die "Unable to remove $pending_path: $!";
}

SKIP: {
    skip 'requires a writable /dev/full to force a write failure', 1
      if !-e '/dev/full' || !-w '/dev/full';

    my $target       = $store->_session_file('write-blocked-session');
    my $pending_path = "$target.forced-full.pending";
    no warnings 'redefine';
    local *Developer::Dashboard::SessionStore::_pending_session_file = sub { return $pending_path };
    use warnings 'redefine';

    skip "unable to symlink /dev/full: $!", 1
      if !symlink( '/dev/full', $pending_path );

    # DD-600: /dev/full always fails a write with ENOSPC. The session record
    # is far smaller than Perl's IO buffer, so print() itself returns true
    # (buffered, not yet flushed to the device) and the error only surfaces
    # at close() - exercising the close-stage die branch, distinct from the
    # open-stage die covered above.
    my @warnings;
    my $write_fail;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $write_fail = eval { $store->create( username => 'write-blocked-user' ); 1 } ? '' : $@;
    }
    like( $write_fail, qr/Unable to close \Q$pending_path\E/, 'create dies when the pending write cannot be flushed to the device at close' );
    unlink $pending_path;
}

# --- create: force the rename-stage die by making the final session path
# an existing directory. _session_file is pinned to a fixed path (the real
# path is keyed by a random session_id only known after create() returns,
# so it cannot be pre-staged) - the pending temp write still succeeds, since
# only the FINAL path is a directory. --------------------------------------
{
    my $victim_file = File::Spec->catfile( $store->{paths}->sessions_root, 'rename-blocked-session.json' );
    mkdir $victim_file or die "Unable to stage directory $victim_file: $!";
    no warnings 'redefine';
    local *Developer::Dashboard::SessionStore::_session_file = sub { return $victim_file };
    use warnings 'redefine';
    my $rename_fail = eval { $store->create( username => 'rename-blocked-user' ); 1 } ? '' : $@;
    like( $rename_fail, qr/Unable to rename/, 'create dies when the record cannot be installed at its final path' );
}

# --- sweep_expired: an unopenable sessions root makes opendir die -------
{
    no warnings qw(redefine once);
    local *Developer::Dashboard::PathRegistry::sessions_root = sub {
        return File::Spec->catdir( $home, 'missing-sweep-root' );
    };
    my $err = eval { $store->sweep_expired; 1 } ? '' : $@;
    like( $err, qr/Unable to read sessions root/, 'sweep_expired dies when the sessions root cannot be opened' );
}

# --- sweep_expired: a session file it cannot open is skipped ------------
{
    my $dir = File::Spec->catdir( $home, 'sweep-unreadable-file' );
    make_path($dir);
    my $file = File::Spec->catfile( $dir, 'unreadable.json' );
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode( { session_id => 'unreadable', expires_at => '2000-01-01T00:00:00Z' } );
    close $fh;
  SKIP: {
        chmod 0000, $file or skip 'chmod not honored on this filesystem', 1;
        if ( open my $probe, '<', $file ) {
            close $probe or die "Unable to close probe on $file: $!";
            skip 'this process can read a mode-0000 session file, so the skip-on-read-failure path cannot occur', 1;
        }

        no warnings qw(redefine once);
        local *Developer::Dashboard::PathRegistry::sessions_root = sub { return $dir };
        is( $store->sweep_expired, 0, 'sweep_expired skips a session file it cannot open for reading' );
    }

    chmod 0600, $file or die "Unable to restore mode on $file: $!";
}

# --- sweep_expired: DD-764 - a record with a missing, empty, or "0" expiry
#     is COLLECTED, not left untouched. An absent expiry used to be treated
#     as "never expires" and skipped by the same guard that (correctly)
#     still protects a record whose expiry is a genuinely future timestamp
#     below, which sweep_expired must still leave alone. -----------------
for my $case ( [ 'blank', '' ], [ 'zero', '0' ], [ 'missing', undef ] ) {
    my ( $name, $expires_at ) = @$case;
    my $dir = File::Spec->catdir( $home, "sweep-$name-expiry" );
    make_path($dir);
    my $file = File::Spec->catfile( $dir, "$name.json" );
    my %record = ( session_id => $name );
    $record{expires_at} = $expires_at if defined $expires_at;
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode( \%record );
    close $fh;

    no warnings qw(redefine once);
    local *Developer::Dashboard::PathRegistry::sessions_root = sub { return $dir };
    is( $store->sweep_expired, 1, "sweep_expired collects a record whose expiry is " . ( defined $expires_at ? "'$expires_at'" : 'absent' ) );
    ok( !-e $file, "and the file is actually removed ($name)" );
}

# --- sweep_expired: a record with a genuinely future expiry is still left
#     untouched - the regression guard for the fix above. ----------------
{
    my $dir = File::Spec->catdir( $home, 'sweep-future-expiry' );
    make_path($dir);
    my $file = File::Spec->catfile( $dir, 'future.json' );
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode( { session_id => 'future', expires_at => '2999-01-01T00:00:00Z' } );
    close $fh;

    no warnings qw(redefine once);
    local *Developer::Dashboard::PathRegistry::sessions_root = sub { return $dir };
    is( $store->sweep_expired, 0, 'sweep_expired leaves a record with a genuinely future expiry untouched' );
    ok( -f $file, 'and the file is still there' );
}

# --- sweep_expired: dry_run counts an expired file without unlinking it -
# (DD-613, for Housekeeper's preview mode)
{
    my $dir = File::Spec->catdir( $home, 'sweep-dry-run' );
    make_path($dir);
    my $file = File::Spec->catfile( $dir, 'expired.json' );
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode( { session_id => 'expired', expires_at => '2000-01-01T00:00:00Z' } );
    close $fh;

    no warnings qw(redefine once);
    local *Developer::Dashboard::PathRegistry::sessions_root = sub { return $dir };
    is( $store->sweep_expired( dry_run => 1 ), 1, 'sweep_expired counts an expired file as removed under dry_run' );
    ok( -f $file, 'sweep_expired leaves the expired file on disk under dry_run' );
    is( $store->sweep_expired, 1, 'a real (non-dry-run) sweep_expired against the same fixture actually removes it' );
    ok( !-f $file, 'the real sweep_expired call removed the file this time' );
}

# --- sweep_expired: an expired file that cannot be unlinked is not counted
{
    my $dir = File::Spec->catdir( $home, 'sweep-readonly-dir' );
    make_path($dir);
    my $file = File::Spec->catfile( $dir, 'expired.json' );
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode( { session_id => 'expired', expires_at => '2000-01-01T00:00:00Z' } );
    close $fh;
    chmod 0600, $file or die "Unable to chmod $file: $!";
  SKIP: {
        chmod 0500, $dir or skip 'chmod not honored on this filesystem', 1;

        # An unlink needs write on the DIRECTORY, so probe by trying to create
        # a file in it - -w is mode-bit arithmetic and lies for uid 0.
        my $wprobe = File::Spec->catfile( $dir, '.unlink-probe' );
        my $pfh;
        my $can_write = open( $pfh, '>', $wprobe ) ? do { close $pfh; unlink $wprobe; 1 } : 0;

        my $removed;
        if ( !$can_write ) {
            no warnings qw(redefine once);
            local *Developer::Dashboard::PathRegistry::sessions_root = sub { return $dir };
            $removed = $store->sweep_expired;
        }
        chmod 0700, $dir or die "Unable to restore mode on $dir: $!";

        skip 'this process can write into a mode-0500 directory, so the unlink failure cannot occur', 1
          if $can_write;
        is( $removed, 0, 'sweep_expired reports zero removals when an expired file cannot be unlinked' );
    }
}

# DD-850: same shape as DD-848 in Zipper.pm - every other test in this file
# overrides _pending_session_file; this one calls the real implementation,
# which none of them exercise.
{
    my @paths = map { $store->_pending_session_file('/tmp/dd850-session-target') } 1 .. 50;
    my %seen;
    my @dupes = grep { $seen{$_}++ } @paths;
    is( scalar(@dupes), 0,
        'DD-850: 50 real, rapid-fire calls to _pending_session_file for the same destination never repeat a staging path' );
}

done_testing;

__END__

=head1 NAME

t/67-sessionstore-coverage.t - branch and condition coverage closure for the file-backed session store

=head1 PURPOSE

This test drives the defensive and short-circuit paths of the helper-session
store that the higher-level login, logout, and request-auth flows do not reach
on their own. It exercises the constructor and create argument guards, the
empty/undefined session-id guards in get and delete, the cookie-parsing skip for
empty and undefined cookie keys, the expiry and remote-address short-circuits in
from_cookie, the private timestamp helpers with falsy and malformed input, and
the read, write, opendir, and unlink failure arms of get, create, and
sweep_expired.

=head1 WHY IT EXISTS

The session store carries security-relevant guards (path-safe ids, expiry
enforcement, remote-address binding) and filesystem error handling that a normal
happy-path login never triggers, so those branches would otherwise sit uncovered
and could rot silently. This file pins each of those arms to an explicit
assertion so the branch and condition coverage of the store stays complete and a
regression in a guard or an error path fails loudly instead of slipping through.

=head1 WHEN TO USE

Use this file when changing the session store's argument validation, cookie
parsing, expiry or remote-address binding rules, the on-disk record shape, or the
sweep that reclaims expired session files.

=head1 HOW TO USE

Run C<prove -lv t/67-sessionstore-coverage.t> while iterating on the session
store, then keep it green under C<prove -lr t> and the full coverage run before
release.

=head1 WHAT USES IT

Developers during TDD, the full repository test suite, and the coverage gate all
rely on this file to keep the session store's guard and error-handling behavior
from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/67-sessionstore-coverage.t

Run the focused session-store coverage test by itself while changing the store.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/67-sessionstore-coverage.t

Exercise the same focused test while collecting coverage for the session-store
branches and conditions it targets.

Example 3:

  prove -lr t

Put any session-store change back through the entire repository suite before
calling the work finished.

=cut
