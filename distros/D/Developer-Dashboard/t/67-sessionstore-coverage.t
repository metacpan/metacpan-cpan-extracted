#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

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
        Developer::Dashboard::SessionStore::_iso8601_to_epoch(undef),
        0,
        '_iso8601_to_epoch returns 0 for an undefined timestamp',
    );
    is(
        Developer::Dashboard::SessionStore::_iso8601_to_epoch('not-a-timestamp'),
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

# --- from_cookie: empty expiry short-circuits the expiry check, and no
#     request remote_addr short-circuits the binding check ---------------
{
    $write_session->(
        'cover-empty-expiry',
        {
            session_id  => 'cover-empty-expiry',
            username    => 'empty-expiry-user',
            role        => 'helper',
            remote_addr => '10.0.0.1',
            expires_at  => '',
        }
    );
    my $session = $store->from_cookie('dashboard_session=cover-empty-expiry');
    is( ref $session, 'HASH', 'from_cookie returns a session whose empty expiry skips the expiry comparison' );
    is( $session->{username}, 'empty-expiry-user', 'from_cookie loads the crafted empty-expiry session record' );
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
    chmod 0000, $file or die "Unable to chmod $file: $!";
    my $err = eval { $store->get( $record->{session_id} ); 1 } ? '' : $@;
    like( $err, qr/Unable to read/, 'get dies when a present session file cannot be opened for reading' );
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
    chmod 0000, $file or die "Unable to chmod $file: $!";

    no warnings qw(redefine once);
    local *Developer::Dashboard::PathRegistry::sessions_root = sub { return $dir };
    is( $store->sweep_expired, 0, 'sweep_expired skips a session file it cannot open for reading' );
    chmod 0600, $file or die "Unable to restore mode on $file: $!";
}

# --- sweep_expired: a record with an empty expiry is left untouched -----
{
    my $dir = File::Spec->catdir( $home, 'sweep-empty-expiry' );
    make_path($dir);
    my $file = File::Spec->catfile( $dir, 'blank.json' );
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} json_encode( { session_id => 'blank', expires_at => '' } );
    close $fh;

    no warnings qw(redefine once);
    local *Developer::Dashboard::PathRegistry::sessions_root = sub { return $dir };
    is( $store->sweep_expired, 0, 'sweep_expired leaves a record whose expiry is the empty string untouched' );
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
    chmod 0500, $dir  or die "Unable to chmod $dir: $!";

    my $removed;
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::PathRegistry::sessions_root = sub { return $dir };
        $removed = $store->sweep_expired;
    }
    is( $removed, 0, 'sweep_expired reports zero removals when an expired file cannot be unlinked' );
    chmod 0700, $dir or die "Unable to restore mode on $dir: $!";
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
