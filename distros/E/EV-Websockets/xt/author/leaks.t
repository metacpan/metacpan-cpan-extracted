use strict;
use warnings;
use Test::More;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

# Author test: Perl-level SV leak detection across create/destroy cycles, to
# catch refcount regressions in the XS glue. C-level (lws/malloc) leaks are
# covered separately by running the suite under valgrind/ASan. Run `prove -lb xt/`.
# Import at compile time (so no_leaks_ok's prototype is in scope), skipping
# cleanly if the module is absent.
BEGIN {
    unless (eval { require Test::LeakTrace; Test::LeakTrace->VERSION(0.14); 1 }) {
        plan skip_all => "Test::LeakTrace 0.14 required for leak tests";
    }
    Test::LeakTrace->import;
}

use EV;
use EV::Websockets;

# Warm up: create the default loop and one context/connection first so EV's and
# lws's one-time/persistent allocations are not counted as leaks below.
{
    my $ctx = EV::Websockets::Context->new;
    $ctx->listen(port => 0, on_message => sub { });
    eval { $ctx->connect(url => "ws://127.0.0.1:1", on_error => sub { }) };
}

no_leaks_ok {
    for (1 .. 25) {
        my $ctx  = EV::Websockets::Context->new;
        my $port = $ctx->listen(port => 0, on_message => sub { }, on_connect => sub { });
    }
} "context + listener create/destroy does not leak SVs";

no_leaks_ok {
    my $ctx = EV::Websockets::Context->new;
    for (1 .. 25) {
        my $conn = eval {
            $ctx->connect(
                url        => "ws://127.0.0.1:1",
                on_connect => sub { },
                on_message => sub { },
                on_error   => sub { },
                headers    => { 'X-Test' => 'v' },
            );
        };
    }
} "connect attempts (with callbacks/headers) do not leak SVs";

done_testing;
