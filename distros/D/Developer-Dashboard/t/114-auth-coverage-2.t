#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Socket ();

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Auth;

# Hermetic runtime rooted in a throwaway HOME. The auth layer resolves its
# config/state roots from the deepest .developer-dashboard directory found while
# walking up from the cwd, so the test must chdir into the temp home before any
# registry is constructed.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $auth  = Developer::Dashboard::Auth->new( paths => $paths, files => $files );

isa_ok( $auth, 'Developer::Dashboard::Auth', 'constructed an auth manager in the throwaway runtime' );

# ---------------------------------------------------------------------------
# Well-known local-machine host aliases beyond bare 'localhost'.
#
# The DNS-rebinding hardening trusts only a tiny explicit alias list without
# resolution. Every entry on that list must actually be honoured, otherwise a
# perfectly local browser hitting http://localhost.localdomain:7890/ or the
# IPv6 alias names would silently be demoted to helper tier and prompted for a
# login it does not have.
# ---------------------------------------------------------------------------
for my $alias (qw(localhost localhost.localdomain localhost6 localhost6.localdomain6)) {
    is(
        $auth->trust_tier( remote_addr => '127.0.0.1', host => $alias ),
        'admin',
        "local alias host '$alias' over a loopback connection is admin",
    );
    is(
        $auth->trust_tier( remote_addr => '127.0.0.1', host => "$alias:7890" ),
        'admin',
        "local alias host '$alias' with a port is admin",
    );
    is(
        $auth->trust_tier( remote_addr => '10.11.12.13', host => $alias ),
        'helper',
        "local alias host '$alias' claimed by a remote client is never admin",
    );
}

# Near-miss alias names must NOT be trusted: the list is exact-match only, so a
# suffixed or prefixed lookalike stays helper tier.
for my $lookalike (qw(localhost.localdomain.evil.example notlocalhost6 localhost7 localhost6.localdomain)) {
    is(
        $auth->trust_tier( remote_addr => '127.0.0.1', host => $lookalike ),
        'helper',
        "lookalike host '$lookalike' is not treated as a local alias",
    );
}

# The alias checks are also exercised directly so the loopback-admin predicate
# is pinned independently of trust_tier's ssl_proxied short-circuit.
is(
    $auth->_request_is_loopback_admin( remote_addr => '::1', host => 'localhost.localdomain' ),
    1,
    '_request_is_loopback_admin accepts localhost.localdomain over IPv6 loopback',
);
is(
    $auth->_request_is_loopback_admin( remote_addr => '::1', host => 'localhost6' ),
    1,
    '_request_is_loopback_admin accepts the localhost6 alias',
);
is(
    $auth->_request_is_loopback_admin( remote_addr => '::1', host => 'localhost6.localdomain6' ),
    1,
    '_request_is_loopback_admin accepts the localhost6.localdomain6 alias',
);

# ---------------------------------------------------------------------------
# Resolution failure paths.
#
# _resolve_host_ips must swallow a getaddrinfo error and report no addresses,
# and _host_resolves_only_to_loopback must then answer "not loopback-safe"
# instead of vacuously returning true for an empty address list -- an empty
# result set must never read as "all resolved addresses are loopback".
# The resolver is stubbed so the test never depends on real DNS.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::Auth::getaddrinfo = sub {
        return ('Name or service not known');
    };

    is_deeply(
        [ $auth->_resolve_host_ips('nx.invalid') ],
        [],
        '_resolve_host_ips returns no addresses when the resolver reports an error',
    );
    is(
        $auth->_host_resolves_only_to_loopback('nx.invalid'),
        0,
        'a host whose resolution fails is not loopback-safe',
    );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::Auth::getaddrinfo = sub {
        return ('');
    };

    is_deeply(
        [ $auth->_resolve_host_ips('empty.invalid') ],
        [],
        '_resolve_host_ips returns no addresses when the resolver succeeds with no results',
    );
    is(
        $auth->_host_resolves_only_to_loopback('empty.invalid'),
        0,
        'an empty resolved address set is not loopback-safe',
    );
}

# The positive counterpart of the same guard: a non-empty, all-loopback address
# set must still be reported as loopback-safe, so the "no addresses" rejection
# above cannot be satisfied by rejecting everything.
{
    no warnings 'redefine';
    my $v4 = Socket::pack_sockaddr_in( 0, Socket::inet_aton('127.0.0.1') );
    local *Developer::Dashboard::Auth::getaddrinfo = sub {
        return ( '', { family => Socket::AF_INET(), addr => $v4 } );
    };

    is(
        $auth->_host_resolves_only_to_loopback('loop.invalid'),
        1,
        'a host resolving to a single loopback address is loopback-safe',
    );
}

done_testing;

__END__

=pod

=head1 NAME

t/114-auth-coverage-2.t - branch and condition coverage for the auth trust-alias and resolver-failure paths

=head1 PURPOSE

This test pins the parts of the auth trust model that the rest of the suite
leaves unexercised: the well-known local-machine host aliases
C<localhost.localdomain>, C<localhost6>, and C<localhost6.localdomain6>, and the
two "no addresses resolved" outcomes of hostname resolution. It asserts that
each alias earns admin tier over a loopback connection, that lookalike names do
not, and that a failed or empty resolution is reported as not loopback-safe.

=head1 WHY IT EXISTS

It exists because the DNS-rebinding hardening reduced admin trust to an exact
alias whitelist, and an untested entry on that whitelist is indistinguishable
from a missing one: a regression would quietly demote a genuinely local browser
to helper tier and demand a login. The resolver-failure side matters for the
opposite reason -- if an empty address list were ever read as "every resolved
address is loopback", a name that does not resolve at all would be treated as
loopback-safe. Both directions are security-relevant, so both get an executable
contract, and covering them takes the module's branch and condition coverage to
100 percent.

=head1 WHEN TO USE

Use this test when changing the trusted local-alias host list, the
loopback-admin predicate, or the hostname-resolution helpers in the auth module.
Run it first when tightening or relaxing which host headers may be treated as
local admin traffic.

=head1 HOW TO USE

Run it on its own with C<prove -lv t/114-auth-coverage-2.t>, or as part of the
full suite with C<prove -lr t>. It needs no network, no server, and no shared
state: it builds a throwaway HOME, chdirs into it, and stubs the resolver, so it
is safe to run in parallel with the rest of the suite.

=head1 WHAT USES IT

The repository test suite runs it, and the Devel::Cover gate relies on it for
the branch and condition arms of the auth module's alias and resolver code.
Reviewers of any change to the trust tier rules use it as the statement of the
intended behavior.

=head1 EXAMPLES

Example 1:

  prove -lv t/114-auth-coverage-2.t

Run just this file with per-assertion output while editing the trust rules.

Example 2:

  prove -lv t/57-hunt-auth.t t/82-auth-coverage.t t/114-auth-coverage-2.t

Run the whole auth-focused group after touching the trust tier logic.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Confirm the coverage gate still reports every metric at 100 percent.

Example 4:

  perl -Ilib t/114-auth-coverage-2.t

Execute the file directly, without the harness, to see raw TAP output.

=cut
