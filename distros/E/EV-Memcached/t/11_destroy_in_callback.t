use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# DESTRUCTION contract: dropping the LAST reference from inside a
# command callback while another command is still pending must fire the
# pending callback once with (undef, "disconnected") — even though
# DESTROY is deferred (callback_depth > 0). Pre-fix the deferred branch
# dropped the queues silently and the callback never fired.

my $srv = FakeMemcached->new(script => sub {
    my ($listen) = @_;
    my $c = FakeMemcached->accept($listen);
    # Answer only the FIRST request; leave the second pending forever.
    my $r = $c->read_request or exit 0;
    $c->respond(op => $r->[0], opaque => $r->[1]);
    sleep 3;
});

my @events;
my $mc = EV::Memcached->new(
    path     => $srv->path,
    on_error => sub { push @events, "on_error($_[0])" },
);
$mc->noop(sub { push @events, 'cbA fired'; undef $mc; });   # last ref dropped here
$mc->noop(sub { push @events, 'cbB: ' . (defined $_[1] ? $_[1] : 'ok') });

my $t = EV::timer 1.5, 0, sub { EV::break };
EV::run;

is_deeply(\@events, ['cbA fired', 'cbB: disconnected'],
    'pending callback fired once with "disconnected" from deferred DESTROY')
    or diag "events: @events";
ok(!defined $mc, 'object is gone');

$srv->finish;
done_testing;
