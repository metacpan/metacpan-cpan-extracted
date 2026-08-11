#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Socket qw(AF_INET6);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Auth;
use Developer::Dashboard::JSON qw(json_encode);

# Hermetic runtime rooted in a throwaway HOME. The auth config layer resolves
# from the deepest .developer-dashboard directory found walking up from the cwd,
# so we must chdir into the temp home before building the registries.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $auth  = Developer::Dashboard::Auth->new( paths => $paths, files => $files );

isa_ok( $auth, 'Developer::Dashboard::Auth', 'constructed auth manager' );

# new() rejects missing registries -- exercises the die side of both ||-guards.
{
    my $no_paths = eval { Developer::Dashboard::Auth->new(); 1 } ? '' : $@;
    like( $no_paths, qr/Missing path registry/, 'new dies without a path registry' );
    my $no_files = eval { Developer::Dashboard::Auth->new( paths => $paths ); 1 } ? '' : $@;
    like( $no_files, qr/Missing file registry/, 'new dies without a file registry' );
}

# add_user success plus every guarded rejection path.
{
    my $record = $auth->add_user( username => 'alice', password => 'password123' );
    is( $record->{username}, 'alice', 'add_user stores the requested username' );
    is( $record->{iterations}, 210_000, 'add_user records the default PBKDF2 work factor' );

    my $no_username = eval { $auth->add_user( password => 'password123' ); 1 } ? '' : $@;
    like( $no_username, qr/Missing username/, 'add_user dies without a username' );

    my $no_password = eval { $auth->add_user( username => 'bob' ); 1 } ? '' : $@;
    like( $no_password, qr/Missing password/, 'add_user dies without a password' );

    my $bad_username = eval { $auth->add_user( username => 'bad name!', password => 'password123' ); 1 } ? '' : $@;
    like( $bad_username, qr/unsupported characters/, 'add_user rejects unsupported username characters' );

    my $short_password = eval { $auth->add_user( username => 'carol', password => 'short' ); 1 } ? '' : $@;
    like( $short_password, qr/at least 8 characters/, 'add_user rejects passwords shorter than eight characters' );

    # Force the write-failure die: make the target record path an existing
    # directory so the ">:raw" open cannot succeed.
    my $victim_file = $auth->_user_file('victim');
    mkdir $victim_file or die "Unable to stage directory $victim_file: $!";
    my $write_fail = eval { $auth->add_user( username => 'victim', password => 'password123' ); 1 } ? '' : $@;
    like( $write_fail, qr/Unable to write/, 'add_user dies when the record file cannot be opened for writing' );
}

# verify_user guards, the PBKDF2 verification path, and a record that omits the
# iteration count (so the default work factor fills in).
{
    ok( !defined $auth->verify_user(), 'verify_user returns undef without a username' );
    ok( !defined $auth->verify_user( username => 'alice' ), 'verify_user returns undef without a password' );
    ok( $auth->verify_user( username => 'alice', password => 'password123' ), 'verify_user accepts a valid PBKDF2 login' );
    ok( !defined $auth->verify_user( username => 'alice', password => 'wrongpass1' ), 'verify_user rejects a wrong password' );

    my $salt = 'coverage-salt';
    my $hash = Developer::Dashboard::Auth::_pbkdf2_hmac_sha256_hex( 'password123', $salt, 210_000 );
    my $file = $auth->_user_file('noiter');
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} json_encode(
        {
            username        => 'noiter',
            role            => 'helper',
            salt            => $salt,
            password_scheme => 'pbkdf2-hmac-sha256',
            password_hash   => $hash,
        }
    );
    close $fh;
    ok(
        $auth->verify_user( username => 'noiter', password => 'password123' ),
        'verify_user falls back to the default work factor when a record omits its iteration count',
    );
}

# get_user must surface an open failure on a record that exists but is
# unreadable (running as a non-root owner, mode 0000 denies our own read).
{
    my $locked = $auth->_user_file('locked');
    open my $fh, '>', $locked or die "Unable to write $locked: $!";
    print {$fh} json_encode( { username => 'locked' } );
    close $fh;
    chmod 0000, $locked;
    my $read_fail = eval { $auth->get_user('locked'); 1 } ? '' : $@;
    like( $read_fail, qr/Unable to read/, 'get_user dies when an existing record cannot be opened for reading' );
    chmod 0600, $locked;
}

# list_users: skip non-json directory entries and drop entries whose record
# cannot be loaded (the staged "victim.json" is a directory, not a file).
{
    my $stray = File::Spec->catfile( $paths->users_root, 'notes.txt' );
    open my $fh, '>', $stray or die "Unable to write $stray: $!";
    print {$fh} "not a user record\n";
    close $fh;

    my @users = $auth->list_users;
    is_deeply(
        [ map { $_->{username} } @users ],
        [ 'alice', 'locked', 'noiter' ],
        'list_users returns only loadable json records, sorted by username',
    );
    is( $auth->helper_users_enabled, 1, 'helper_users_enabled reports configured helper logins' );
}

# trust_tier and its host/IP canonicalisation helpers.
{
    is( $auth->trust_tier( remote_addr => '127.0.0.1', host => '127.0.0.1' ), 'admin', 'loopback client with loopback host is admin' );
    is( $auth->trust_tier( remote_addr => '127.0.0.1' ), 'admin', 'loopback client with an undefined host is admin' );
    is( $auth->trust_tier( remote_addr => '127.0.0.1', host => '' ), 'admin', 'loopback client with a blank host is admin' );
    is( $auth->trust_tier( remote_addr => '127.0.0.1', host => '127.0.0.1', ssl_proxied => 1 ), 'helper', 'ssl-proxied requests never get the loopback-admin shortcut' );

    is( $auth->trust_tier( host => '127.0.0.1' ), 'helper', 'a missing remote address canonicalises to blank and stays helper' );
    is( $auth->trust_tier( remote_addr => '', host => '127.0.0.1' ), 'helper', 'a blank remote address stays helper' );
    is( $auth->trust_tier( remote_addr => 'zz:zz', host => '127.0.0.1' ), 'helper', 'an unparseable colon address is lowercased but not loopback' );
    is( $auth->trust_tier( remote_addr => '::1', host => '::1' ), 'admin', 'canonical IPv6 loopback is admin' );
}

# _ip_is_loopback across undef, blank, IPv4 loopback, and the two spelled-out
# IPv6 loopback literals.
{
    is( $auth->_ip_is_loopback(undef), 0, '_ip_is_loopback rejects undef' );
    is( $auth->_ip_is_loopback(''), 0, '_ip_is_loopback rejects the empty string' );
    is( $auth->_ip_is_loopback('127.0.0.1'), 1, '_ip_is_loopback accepts 127.0.0.1' );
    is( $auth->_ip_is_loopback('127.255.255.255'), 1, '_ip_is_loopback accepts the whole 127.0.0.0/8 range' );
    is( $auth->_ip_is_loopback('126.0.0.1'), 0, '_ip_is_loopback rejects a non-127 IPv4 address' );
    is( $auth->_ip_is_loopback('::1'), 1, '_ip_is_loopback accepts compressed IPv6 loopback' );
    is( $auth->_ip_is_loopback('0:0:0:0:0:0:0:1'), 1, '_ip_is_loopback accepts spelled-out IPv6 loopback' );
    is( $auth->_ip_is_loopback('8.8.8.8'), 0, '_ip_is_loopback rejects a public address' );
}

# _secure_compare defined/undef combinations.
{
    is( Developer::Dashboard::Auth::_secure_compare( undef, 'abc' ), 0, '_secure_compare rejects an undef left operand' );
    is( Developer::Dashboard::Auth::_secure_compare( 'abc', undef ), 0, '_secure_compare rejects an undef right operand' );
    is( Developer::Dashboard::Auth::_secure_compare( 'abc', 'abc' ), 1, '_secure_compare accepts identical strings' );
    is( Developer::Dashboard::Auth::_secure_compare( 'abc', 'abd' ), 0, '_secure_compare rejects differing equal-length strings' );
}

# _host_resolves_only_to_loopback and _resolve_host_ips with a stubbed resolver
# so the address-family, dedup, and skip branches all run without real DNS.
{
    no warnings 'redefine';
    my $v4 = Socket::pack_sockaddr_in( 0, Socket::inet_aton('127.0.0.1') );
    my $v6 = Socket::pack_sockaddr_in6( 0, Socket::inet_pton( AF_INET6, '::1' ) );
    local *Developer::Dashboard::Auth::getaddrinfo = sub {
        return (
            '',
            'not-a-hash',
            { family => undef, addr => '' },
            { family => 2,     addr => $v4 },
            { family => 2,     addr => $v4 },
            { family => 10,    addr => $v6 },
            { family => 99,    addr => '' },
        );
    };

    is_deeply(
        [ $auth->_resolve_host_ips('any-host') ],
        [ '127.0.0.1', '::1' ],
        '_resolve_host_ips canonicalises IPv4/IPv6 results, skips non-hash and unknown families, and de-duplicates',
    );
    is( $auth->_host_resolves_only_to_loopback('any-host'), 1, 'a host resolving only to loopback addresses is loopback-safe' );

    is( $auth->_host_resolves_only_to_loopback(undef), 0, '_host_resolves_only_to_loopback rejects an undef host' );
    is( $auth->_host_resolves_only_to_loopback(''), 0, '_host_resolves_only_to_loopback rejects a blank host' );
    is_deeply( [ $auth->_resolve_host_ips(undef) ], [], '_resolve_host_ips returns nothing for an undef host' );
    is_deeply( [ $auth->_resolve_host_ips('') ], [], '_resolve_host_ips returns nothing for a blank host' );

    # _request_is_loopback_admin: alias filtering (undef/blank/whitespace inputs)
    # plus DNS-rebinding protection: a non-localhost hostname is not trusted
    # even when it resolves only to loopback.
    is(
        $auth->_request_is_loopback_admin(
            remote_addr          => '127.0.0.1',
            host                 => 'target-host',
            extra_loopback_hosts => [ undef, '', '   ', 'other-alias' ],
        ),
        0,
        '_request_is_loopback_admin rejects a non-localhost hostname even when it resolves only to loopback (DNS-rebinding fix)',
    );
    is(
        $auth->_request_is_loopback_admin(
            remote_addr          => '127.0.0.1',
            host                 => 'match-alias',
            extra_loopback_hosts => [ 'nomatch', 'match-alias' ],
        ),
        1,
        '_request_is_loopback_admin trusts a request whose host matches a configured loopback alias',
    );
}

# _request_is_loopback_admin blank/undef host guards and the non-loopback
# remote short-circuit, driven directly.
{
    is(
        $auth->_request_is_loopback_admin( remote_addr => '', host => undef ),
        0,
        '_request_is_loopback_admin denies a non-loopback (blank) remote address',
    );
    is(
        $auth->_request_is_loopback_admin( remote_addr => '127.0.0.1', host => undef ),
        1,
        '_request_is_loopback_admin trusts a loopback remote with an undefined host',
    );
    is(
        $auth->_request_is_loopback_admin( remote_addr => '127.0.0.1', host => '' ),
        1,
        '_request_is_loopback_admin trusts a loopback remote with a blank host',
    );
}

done_testing;

__END__

=pod

=head1 NAME

t/82-auth-coverage.t - branch and condition coverage closure for the auth manager

=head1 PURPOSE

This test drives Developer::Dashboard::Auth through the specific branch and
condition sides that ordinary CLI and web flows never reach: the constructor and
add_user validation dies, the record write- and read-failure paths, the PBKDF2
default-work-factor fallback, list_users entry filtering, host/IP
canonicalisation edge cases, the loopback-admin trust rules, and the
address-family handling inside hostname resolution. It exists to hold those
paths at full branch and condition coverage.

=head1 WHY IT EXISTS

The trust boundary in the auth manager is dense with defensive guards -- undef
and blank host/address handling, alias filtering, address-family selection, and
constant-time comparison -- that decide whether a request is treated as local
admin or a challenged helper. A statement-only test can leave the wrong side of
those guards unexercised, so a security-relevant regression could pass unseen.
This file pins each guard's untaken side with an explicit, readable assertion.

=head1 WHEN TO USE

Use this file when changing helper-user storage, password verification, the
loopback-versus-helper trust decision, host or IP canonicalisation, or hostname
resolution. Extend it first (failing) when adding a new guard so its untaken
side is covered from the start.

=head1 HOW TO USE

Run C<perl -Ilib t/82-auth-coverage.t> or C<prove -lv t/82-auth-coverage.t>
while iterating, and keep it green under C<prove -lr t> and the coverage gate
before release. It is fully hermetic: it roots HOME in a temporary directory,
chdirs into it, and stubs the resolver, so it needs no network or real users.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the Devel::Cover
branch/condition gate all rely on this file to keep the auth manager's guarded
paths honest.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/82-auth-coverage.t

Run the auth coverage closure test standalone while changing the module.

Example 2:

  prove -lv t/82-auth-coverage.t

Run it verbosely through the harness to read each guarded assertion.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the auth manager under the repository branch and condition coverage gate.

=cut
