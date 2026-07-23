use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# The loop option must hold a real EV::Loop object; the pointer lives in
# the IV slot of the blessed referent (EV's T_LOOP convention).

# Invalid loop values croak.
for my $bad ([], "x", {}) {
    my $mc = eval { EV::Memcached->new(loop => $bad) };
    like($@, qr/^loop must be an EV::Loop object/,
        "loop => " . (ref $bad || "'$bad'") . " croaks");
    is($mc, undef, 'no object returned');
}

# A valid explicit loop is accepted and usable (pre-fix: SIGSEGV from a
# NULL loop pointer as soon as watchers were started).
{
    # Closed port: connect failure is delivered on the explicitly-passed
    # loop without crashing.
    my $closed = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 1)
        or die "cannot reserve a port: $!";
    my $port = $closed->sockport;
    close $closed;

    my $err;
    my $mc = EV::Memcached->new(
        loop     => EV::default_loop,
        host     => '127.0.0.1',
        port     => $port,
        on_error => sub { $err = $_[0]; EV::break },
    );
    ok($mc, 'new(loop => EV::default_loop, ...) does not crash');

    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;
    like($err, qr/connect failed/, 'connect error delivered via default loop');
}

# The held reference keeps a non-default loop alive for the object's life.
{
    my $mc = EV::Memcached->new(loop => EV::Loop->new, on_error => sub {});
    ok($mc, 'new(loop => EV::Loop->new) accepted');
}

# Stronger: start watchers on the custom loop, then destroy the object.
# Without the loop_sv hold the EV::Loop is freed while rio/wio are armed
# on it and DESTROY's ev_io_stop touches freed memory. NOTE: plain
# no-crash assertion here — the real check is running this file under
# valgrind (without the hold it reports invalid reads; often survives
# normally, so no fail-pre proof is offered).
{
    my $srv = FakeMemcached->new(script => sub {
        my ($listen) = @_;
        my $c = FakeMemcached->accept($listen);
        sleep 2;
    });
    my $mc = EV::Memcached->new(
        loop     => EV::Loop->new,
        path     => $srv->path,
        on_error => sub {},
    );
    undef $mc;   # connect armed watchers on the custom loop; DESTROY stops them
    ok(1, 'custom loop with armed watchers survives DESTROY (see comment)');
    $srv->finish;
}

done_testing;

