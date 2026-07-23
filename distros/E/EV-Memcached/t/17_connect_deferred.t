use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# on_connect is always delivered from the event loop, never synchronously
# from new()/connect()/connect_unix() — so a handler installed right
# after the constructor still fires (pre-fix, an immediately-completing
# unix connect fired on_connect inside new(), before any handler could
# be installed).

my $srv = FakeMemcached->new(script => sub {
    my ($listen) = @_;
    my $c = FakeMemcached->accept($listen);
    my $r = $c->read_request or exit 0;
    $c->respond(op => $r->[0], opaque => $r->[1]);
    sleep 2;
});

my @events;
my $fired_in_new = 0;
my $mc = EV::Memcached->new(
    path       => $srv->path,
    on_error   => sub { push @events, "on_error($_[0])" },
    on_connect => sub { $fired_in_new = 1 },
);
ok(!$fired_in_new, 'constructor on_connect did not fire inside new()');

# Handler installed AFTER new() — must still fire.
$mc->on_connect(sub { push @events, 'on_connect' });

# Issued between new() and connect completion: queues and still works.
$mc->noop(sub { push @events, defined $_[1] ? "noop err=$_[1]" : 'noop' });

my $t = EV::timer 1.5, 0, sub { EV::break };
EV::run;

is_deeply(\@events, ['on_connect', 'noop'],
    'on_connect fires from the event loop; queued command works')
    or diag "events: @events";

# Same for connect_unix() called explicitly.
my $srv2 = FakeMemcached->new(script => sub {
    my ($listen) = @_;
    my $c = FakeMemcached->accept($listen);
    sleep 2;
});
my @events2;
my $mc2 = EV::Memcached->new(on_error => sub { push @events2, "on_error($_[0])" });
$mc2->connect_unix($srv2->path);
$mc2->on_connect(sub { push @events2, 'on_connect'; EV::break });
my $t2 = EV::timer 1.5, 0, sub { EV::break };
EV::run;
is_deeply(\@events2, ['on_connect'],
    'on_connect installed after connect_unix() still fires')
    or diag "events2: @events2";

$srv->finish;
$srv2->finish;
done_testing;
