use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 12;
use EV;
use TestServer;
use EV::YACurl ':constants';

TestServer::watchdog(120);

my $server = TestServer->new(sub { (200, [], 'x' x 16) });
my $base = $server->base_url;

is(EV::YACurl->default_priority, 0, 'default priority starts at 0');

{
    my $client = EV::YACurl->new({});
    is($client->priority, 0, 'client inherits the default');
    is($client->priority(1), 0, 'setter returns the previous value');
    is($client->priority, 1, 'setter took effect');
    is($client->priority(EV::MAXPRI + 10), 1, 'out of range setter still returns previous');
    is($client->priority, EV::MAXPRI, 'high value clamped to MAXPRI');
    $client->priority(EV::MINPRI - 10);
    is($client->priority, EV::MINPRI, 'low value clamped to MINPRI');
}

{
    is(EV::YACurl->default_priority(-1), 0, 'default_priority returns the previous value');
    is(EV::YACurl->new({})->priority, -1, 'new client picks up the changed default');
    EV::YACurl->default_priority(0);
    is(EV::YACurl->new({})->priority, 0, 'and the change is undone');
}

# A high priority client must run before a priority 0 watcher that is ready in
# the same loop iteration, and a low priority one after. Only a sample where
# both really did land in one iteration proves anything, so keep sampling.
sub sample_order {
    my ($priority) = @_;
    my @order;

    pipe(my $read, my $write) or die "pipe: $!";
    my $plain = EV::io_ns(fileno($read), EV::READ,
                          sub { push @order, ['plain', EV::iteration]; $_[0]->stop });
    $plain->priority(0);
    $plain->start;

    my $client = EV::YACurl->new({});
    $client->priority($priority);
    my ($done, $sent) = (0, 0);

    $client->request(sub { push @order, ['curl', EV::iteration]; $done = 1 }, {
        CURLOPT_URL => "$base/",
        CURLOPT_WRITEFUNCTION => sub { },
        CURLOPT_VERBOSE => 1,
        CURLOPT_DEBUGFUNCTION => sub { $sent = 1 if $_[0] == CURLINFO_HEADER_OUT },
    });

    # Stop driving the loop as soon as the request is on the wire, so the reply
    # and our own byte are both sitting unread when one iteration picks them up.
    my $deadline = EV::time() + 5;
    EV::run(EV::RUN_NOWAIT) until $sent || $done || EV::time() > $deadline;
    return undef if $done;

    select undef, undef, undef, 0.3;
    syswrite $write, '!';

    # RUN_ONCE blocks until something happens, so give it something.
    my $give_up = EV::timer($deadline - EV::time(), 0, sub { });
    EV::run(EV::RUN_ONCE);
    EV::run(EV::RUN_ONCE) until $done || EV::time() > $deadline;
    $give_up->stop;
    EV::run(EV::RUN_NOWAIT) for 1 .. 2;

    # Priority only orders watchers that are pending together, so a sample
    # where they landed in different iterations proves nothing either way.
    return undef unless @order == 2 && $order[0][1] == $order[1][1];
    return join ',', map { $_->[0] } @order;
}

sub order_for {
    my ($priority) = @_;
    for (1 .. 10) {
        my $order = sample_order($priority);
        return $order if defined $order;
    }
    return undef;
}

for my $case ([EV::MAXPRI, 'curl,plain', 'before'], [EV::MINPRI, 'plain,curl', 'after']) {
    my ($priority, $expected, $when) = @$case;
    my $order = order_for($priority);

    SKIP: {
        skip "could not get both watchers pending in one iteration", 1
            unless defined $order;
        is($order, $expected, "priority $priority client runs $when a priority 0 watcher");
    }
}
