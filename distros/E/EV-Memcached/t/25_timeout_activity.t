use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# Sending more commands must not postpone detection of an unresponsive peer.
{
    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        1 while $c->read_request;
    });
    my (@errors, $fired);
    my ($traffic, $observation);
    EV::now_update;
    my $mc = EV::Memcached->new(path => $srv->path, command_timeout => 100,
        on_error => sub { push @errors, $_[0]; EV::break });
    $mc->on_connect(sub {
        $mc->noop(sub { $fired = $_[1] });
        $traffic = EV::timer 0.02, 0.02, sub { $mc->noop if $mc->is_connected };
        $observation = EV::timer 0.6, 0, sub { EV::break };
    });
    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run;
    undef $traffic;
    undef $observation;
    $mc->on_connect(undef);
    is_deeply(\@errors, ['command timeout'], 'continuous sends do not reset response timeout');
    is($fired, 'disconnected', 'stalled command is cancelled');
    $mc->disconnect;
    $srv->finish;
}

# Shortening an armed waiting timeout takes effect for existing commands.
{
    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        1 while $c->read_request;
    });
    my $error;
    my $mc = EV::Memcached->new(path => $srv->path, max_pending => 1,
        waiting_timeout => 2000, on_error => sub {});
    $mc->on_connect(sub {
        $mc->noop;
        $mc->noop(sub { $error = $_[1]; EV::break });
        $mc->waiting_timeout(100);
    });
    my $t = EV::timer 0.6, 0, sub { EV::break };
    EV::run;
    is($error, 'waiting timeout', 'updated waiting timeout expires existing work');
    $mc->disconnect;
    $srv->finish;
}

# Waiting deadlines continue during the reconnect delay after a peer closes.
{
    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        $c->read_request;
    });
    my $error;
    my $mc = EV::Memcached->new(path => $srv->path, max_pending => 1,
        waiting_timeout => 100, reconnect => 1, reconnect_delay => 2000,
        resume_waiting_on_reconnect => 1, on_error => sub {});
    $mc->noop;
    $mc->noop(sub { $error = $_[1]; EV::break });
    my $t = EV::timer 0.6, 0, sub { EV::break };
    EV::run;
    is($error, 'waiting timeout', 'replayed work expires while reconnect is pending');
    $mc->disconnect;
    $srv->finish;
}

# A timeout callback may change the deadline for the remaining queue.
for my $timeout (0, 1000) {
    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        1 while $c->read_request;
    });
    my @fired;
    my $mc = EV::Memcached->new(path => $srv->path, max_pending => 1,
        waiting_timeout => 50, on_error => sub {});
    $mc->on_connect(sub {
        $mc->noop;
        $mc->noop(sub { push @fired, $_[1]; $mc->waiting_timeout($timeout) });
        $mc->noop(sub { push @fired, $_[1] });
    });
    my $t = EV::timer 0.2, 0, sub { EV::break };
    EV::run;
    is_deeply(\@fired, ['waiting timeout'], "callback updates waiting timeout to $timeout");
    is($mc->waiting_count, 1, 'remaining command keeps its updated deadline');
    $mc->disconnect;
    $srv->finish;
}

done_testing;
