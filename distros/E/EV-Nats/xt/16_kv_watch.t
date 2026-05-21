use strict;
use warnings;
use Test::More;
use lib 'xt/lib';
use EVNatsHelpers qw(nats_or_skip js_or_skip);
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::KV;

my ($host, $port) = nats_or_skip();
my $nats   = EV::Nats->new(host => $host, port => $port);
my $js     = EV::Nats::JetStream->new(nats => $nats, timeout => 2000);
my $bucket = "evnats_kvw_$$";
my $kv     = EV::Nats::KV->new(js => $js, bucket => $bucket);

js_or_skip($nats, sub { my ($d) = @_; $kv->create_bucket({}, sub { $d->($_[1]) }) });

plan tests => 4;
pass 'create_bucket';

my @events;
$kv->watch('>', sub {
    my ($key, $value, $op) = @_;
    push @events, [$key, $value, $op];
});

# Flush the SUB to the server before publishing so the watcher is
# definitely subscribed when the puts hit the stream.
$nats->flush(sub {
    $kv->put('alpha', 'one', sub {
        $kv->put('alpha', 'two', sub {
            $kv->delete('alpha', sub {
                $kv->purge('alpha', sub {
                    # Watcher delivery is async; small grace before exit.
                    my $t; $t = EV::timer(0.5, 0, sub { undef $t; EV::break });
                });
            });
        });
    });
});

my $guard = EV::timer(15, 0, sub { fail 'timeout'; EV::break });
EV::run;

# Expect at least: PUT one, PUT two, DEL, PURGE — all on key 'alpha'.
my @ops = map { $_->[2] } @events;
ok scalar(@events) >= 4, "watcher saw >= 4 events (got " . scalar(@events) . ")";
ok((grep { $_ eq 'PUT' } @ops) >= 2, 'watcher saw PUT events');
ok((grep { $_ eq 'DEL' || $_ eq 'PURGE' } @ops), 'watcher saw a DEL or PURGE')
    or diag "ops: @ops";

$kv->delete_bucket(sub { EV::break });
EV::timer(3, 0, sub { EV::break });
EV::run;
$nats->disconnect;
