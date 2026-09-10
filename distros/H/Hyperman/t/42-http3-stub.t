#!perl
use strict;
use warnings;
use Test::More;
use Hyperman;

# The HTTP/3 build plumbing and the graceful-degradation story.
#
# What this file protects is the CPAN smoker matrix. HTTP/3 is unavailable on
# most of it: no ngtcp2, no nghttp3, or LibreSSL, which has no ngtcp2 crypto
# backend at all and is what every OpenBSD smoker has. So the stubs have to
# be right, and every other h3 test gates on Hyperman->has_http3.
#
# This runs on both kinds of build and asserts the same contract from each
# side, rather than skipping the half it happens not to be.

my $h3 = Hyperman->has_http3;
ok(defined $h3, 'has_http3 answers on every build');
is($h3, $h3 ? 1 : 0, 'has_http3 is a plain boolean');
note("has_http3 = $h3");

my $lib = Hyperman->quic_library;
note('quic_library = ' . (defined $lib ? $lib : '(undef)'));

if ($h3) {
    ok(defined $lib && length $lib, 'quic_library names the stack when built');
    like($lib, qr/ngtcp2/,  'the QUIC library is reported');
    like($lib, qr/nghttp3/, 'and the HTTP/3 library with it');
    # QUIC's handshake IS a TLS handshake, so this direction is a build
    # invariant and not a coincidence of this machine.
    ok(Hyperman->has_tls, 'an http3 build always has TLS');
} else {
    is($lib, undef, 'quic_library is undef when HTTP/3 was not built');
}

# The option is accepted by the parser on every build - a config that names
# http3 must not become a syntax error on a machine that cannot serve it -
# and refused by the validator with a reason that says what to do.
{
    # No certificate here on purpose. Naming an unreadable one would make
    # OpenSSL print a load failure to stderr before the check under test is
    # reached, and buys nothing: both builds refuse this call, they just
    # refuse it for different reasons, and those reasons are what is asserted.
    my $err = '';
    eval { Hyperman->run(app => sub { }, port => 0, http3 => 1); 1 }
        or $err = "$@";
    ok(length $err, 'http3 => 1 does not silently start a server');
    if ($h3) {
        unlike($err, qr/unknown option/,
               'the option is known to the parser');
        unlike($err, qr/was not built/,
               'and not refused as unbuilt on a build that has it');
    } else {
        like($err, qr/http3 requested but QUIC support was not built/,
             'an unbuilt server says so');
        like($err, qr/ngtcp2/,
             'and names what is missing rather than just failing');
    }
}

# QUIC has no cleartext mode, so this is refused everywhere it is understood.
SKIP: {
    skip 'HTTP/3 not built', 1 unless $h3;
    my $err = '';
    eval { Hyperman->run(app => sub { }, port => 0, http3 => 1); 1 }
        or $err = "$@";
    like($err, qr/http3 needs tls_cert and tls_key/,
         'http3 without a certificate is refused: QUIC has no cleartext mode');
}

# Per-listener too, not only top level: `listen => [{...}]` is the form a
# real deployment uses, and an option the overlay does not know croaks as
# "unknown listen option".
{
    my $err = '';
    eval {
        Hyperman->run(app => sub { }, listen => [ { port => 0, http3 => 1 } ]);
        1;
    } or $err = "$@";
    unlike($err, qr/unknown listen option/,
           'http3 is a per-listener option as well as a top-level one');
}

done_testing();
