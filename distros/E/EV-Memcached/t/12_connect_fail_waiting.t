use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Memcached;

# Commands queued while connecting must not hang when the connect fails
# terminally: without reconnect the callback fires as soon as the failure
# is known; with bounded reconnect it fires when reconnecting gives up.

sub closed_port {
    my $s = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 1)
        or die "cannot reserve a port: $!";
    my $port = $s->sockport;
    close $s;
    return $port;
}

# Terminal connect failure, no reconnect: cb fires DURING the loop run
# (pre-fix: only at DESTROY).
{
    my (@fired, @errors);
    my $mc = EV::Memcached->new(
        host     => '127.0.0.1',
        port     => closed_port(),
        on_error => sub { push @errors, $_[0] },
    );
    $mc->set('k', 'v', sub { push @fired, [ $_[0], $_[1] ] });

    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;

    is(scalar @fired, 1, 'set callback fired during the run (not at DESTROY)');
    ok(defined $fired[0][1], '... with a defined error')
        and diag "error: $fired[0][1]";
    ok(!defined $fired[0][0], '... and undefined result');
    like($errors[0], qr/connect failed/, 'on_error saw connect failure');
    is($mc->waiting_count, 0, 'waiting queue drained');
}

# Bounded reconnect: cb fires after the give-up error.
{
    my (@fired, @errors);
    my $mc = EV::Memcached->new(
        host                  => '127.0.0.1',
        port                  => closed_port(),
        reconnect             => 1,
        reconnect_delay       => 50,
        max_reconnect_attempts => 2,
        on_error              => sub { push @errors, $_[0] },
    );
    $mc->set('k', 'v', sub { push @fired, [ $_[0], $_[1] ] });

    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run;

    is(scalar @fired, 1, 'queued command callback fired after give-up');
    ok(defined $fired[0][1], '... with a defined error')
        and diag "error: $fired[0][1]";
    ok((grep { /max reconnect attempts reached/ } @errors),
        'saw "max reconnect attempts reached"')
        or diag "errors: @errors";
    is($mc->waiting_count, 0, 'waiting queue drained');
}

done_testing;
