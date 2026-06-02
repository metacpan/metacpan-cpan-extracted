use strict;
use warnings;
use Test::More;
use POSIX ();
use EV;
use EV::Websockets;

use if -d 'blib', lib => 'blib/lib', 'blib/arch';

EV::Websockets::_set_debug(1) if $ENV{EV_WS_DEBUG};

# Regression for the OpenSSL global-deinit crash.
#
# libwebsockets refcounts the global TLS-library init across contexts created
# with DO_SSL_GLOBAL_INIT and runs OPENSSL_cleanup() when the last such context
# is destroyed — and OpenSSL 1.1+/3.x cannot re-init after that. So destroying a
# TLS-capable context and then using TLS again (reconnect-with-fresh-context,
# worker recycling, ...) used to SIGSEGV inside OpenSSL's error path or fail to
# create the next context. The module now pins the init in a process-lifetime
# keepalive context so user contexts can be recycled freely.
#
# The crash-prone sequence is run in a forked child so that, if a regression
# (or an lws/OpenSSL combination the keepalive doesn't cover) reintroduces the
# crash, it is contained and reported rather than taking down the whole suite.

sub child_status {
    my ($code) = @_;
    my $pid = fork;
    return undef unless defined $pid;
    unless ($pid) { $code->(); POSIX::_exit(0); }
    waitpid($pid, 0);
    return $?;
}

# 1. create + destroy a context, then a fresh context performs a TLS operation
{
    my $st = child_status(sub {
        { my $c = EV::Websockets::Context->new(); }   # create + destroy
        my $ctx = EV::Websockets::Context->new();
        # Unreadable cert: exercises lws's OpenSSL error path — exactly what
        # crashed before the keepalive. Should croak cleanly, not crash.
        eval {
            $ctx->listen(
                port     => 0,
                name     => 'recycle1',
                ssl_cert => '/nonexistent/cert.pem',
                ssl_key  => '/nonexistent/key.pem',
                on_message => sub { },
            );
        };
    });
    SKIP: {
        skip "fork unavailable: $!", 1 unless defined $st;
        is($st & 127, 0, "no crash on TLS use after a context was recycled")
            or diag "child terminated by signal " . ($st & 127);
    }
}

# 2. several create/destroy cycles, then TLS use, in a child
{
    my $st = child_status(sub {
        EV::Websockets::Context->new() for 1 .. 4;    # transient, all destroyed
        my $ctx = EV::Websockets::Context->new();
        eval {
            $ctx->listen(
                port     => 0,
                name     => 'recycle2',
                ssl_cert => '/nonexistent/cert.pem',
                ssl_key  => '/nonexistent/key.pem',
                on_message => sub { },
            );
        };
    });
    SKIP: {
        skip "fork unavailable: $!", 1 unless defined $st;
        is($st & 127, 0, "no crash after multiple context recycles + TLS");
    }
}

# 3. (in-process, no crash path) a TLS-capable context is creatable after a
#    prior TLS context was destroyed. Without the keepalive, lws would have run
#    OPENSSL_cleanup() on the first context's teardown and this second
#    create would fail (cleanly) — so this both proves the fix and is safe to
#    run in-process.
{
    { EV::Websockets::Context->new(ssl_init => 1); }   # flagged, destroyed
    my $ctx = eval { EV::Websockets::Context->new(ssl_init => 1) };
    ok($ctx, "TLS-capable context creatable after destroying a prior TLS context")
        or diag "context creation failed: $@";
}

done_testing;

POSIX::_exit(Test::More->builder->is_passing ? 0 : 1);
