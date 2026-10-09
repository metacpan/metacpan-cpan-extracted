use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# Quiet writes and mgets must follow older commands held by max_pending.
for my $method (qw(set flush mget mgets)) {
    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        my $quiet = 0;
        while (my $r = $c->read_request) {
            if ($r->[0] == 0x00) {
                $c->respond_hit(op => $r->[0], opaque => $r->[1],
                    value => $r->[2] . ($quiet ? ' after quiet' : ''));
            } elsif ($r->[0] == 0x11 || $r->[0] == 0x18) {
                $quiet = 1;
            } elsif ($r->[0] != 0x11 && $r->[0] != 0x18 && $r->[0] != 0x0d) {
                $c->respond(op => $r->[0], opaque => $r->[1]);
            }
        }
    });
    my (@events, @errors);
    my $mc = EV::Memcached->new(path => $srv->path, max_pending => 1,
        on_error => sub { push @errors, $_[0]; EV::break });
    $mc->on_connect(sub {
        $mc->get('first', sub { push @events, $_[0] // $_[1] });
        $mc->get('second', sub { push @events, $_[0] // $_[1] });
        if ($method eq 'set') {
            $mc->set('k', 'v');
        } elsif ($method eq 'flush') {
            $mc->flush;
        } else {
            $mc->$method(['k'], sub { push @events, $_[1] // $method });
        }
        $mc->noop(sub { push @events, $_[1] // 'fence'; EV::break });
    });
    my $t = EV::timer 2, 0, sub { fail("$method: timed out"); EV::break };
    EV::run;
    is_deeply(\@events, ['first', 'second',
        ($method =~ /^mget/ ? ($method) : ()), 'fence'],
        "$method: responses preserve issue order under backpressure");
    is_deeply(\@errors, [], "$method: no opaque mismatch");
    $mc->disconnect;
    $srv->finish;
}

# Removing the cap must release waiting work even when the peer is stalled.
{
    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        my $first = $c->read_request or exit 0;
        my $second = $c->read_request or exit 0;
        $c->respond(op => $first->[0], opaque => $first->[1]);
        $c->respond(op => $second->[0], opaque => $second->[1]);
        sleep 2;
    });
    my $done = 0;
    my $mc = EV::Memcached->new(path => $srv->path, max_pending => 1,
        on_error => sub { diag "@_"; EV::break });
    $mc->on_connect(sub {
        $mc->noop(sub { ++$done == 2 and EV::break });
        $mc->noop(sub { ++$done == 2 and EV::break });
        is($mc->waiting_count, 1, 'one command waits behind the cap');
        $mc->max_pending(0);
        is($mc->waiting_count, 0, 'max_pending(0) releases waiting work');
    });
    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;
    is($done, 2, 'both commands complete after removing the cap');
    $mc->disconnect;
    $srv->finish;
}

# An mget counts as one command against the cap, even with nothing waiting.
for my $method (qw(mget mgets)) {
    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        1 while $c->read_request;
    });
    my ($pending, $waiting);
    my $mc = EV::Memcached->new(path => $srv->path, max_pending => 1,
        on_error => sub {});
    $mc->on_connect(sub {
        $mc->get('blocker', sub {});
        $mc->$method(['a', 'b'], sub {});
        ($pending, $waiting) = ($mc->pending_count, $mc->waiting_count);
        EV::break;
    });
    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;
    is_deeply([$pending, $waiting], [1, 1], "$method: held behind the cap");
    $mc->disconnect;
    $srv->finish;
}

done_testing;
