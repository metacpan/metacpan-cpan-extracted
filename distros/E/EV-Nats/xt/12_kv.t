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
my $bucket = "evnats_kv_$$";
my $kv     = EV::Nats::KV->new(js => $js, bucket => $bucket);

js_or_skip($nats, sub { my ($d) = @_; $kv->create_bucket({}, sub { $d->($_[1]) }) });

plan tests => 8;
pass 'create_bucket';

# put / get
my ($put_seq, $got, $missing, $keys);
$kv->put('alpha', 'value-a', sub {
    $put_seq = $_[0];
    $kv->put('beta', 'value-b', sub {
        $kv->get('alpha', sub {
            $got = $_[0];
            $kv->get('nonexistent', sub {
                $missing = $_[0];
                $kv->keys(sub {
                    $keys = $_[0];
                    EV::break;
                });
            });
        });
    });
});
EV::timer(8, 0, sub { EV::break });
EV::run;

ok defined $put_seq && $put_seq > 0, 'put returns a sequence';
is $got, 'value-a', 'get round-trip value';
is $missing, undef, 'get on missing key is undef (not an error)';
ok ref($keys) eq 'ARRAY' && (grep { $_ eq 'alpha' } @$keys), 'keys lists alpha';

# create: succeeds for a new key, fails for an existing one
my ($create_seq, $create_err, $conflict_seq, $conflict_err);
$kv->create('fresh', 'first-value', sub {
    ($create_seq, $create_err) = @_;
    $kv->create('fresh', 'second-value', sub {
        ($conflict_seq, $conflict_err) = @_;
        EV::break;
    });
});
EV::timer(5, 0, sub { EV::break });
EV::run;

ok defined($create_seq) && $create_seq > 0,
    'create on a fresh key returns a sequence' or diag "err: $create_err";
ok !defined($conflict_seq) && defined($conflict_err),
    'create on an existing key returns an error';
like $conflict_err, qr/wrong last sequence|already exists|Last Sequence/i,
    'conflict error mentions a sequence violation' or diag "err: $conflict_err";

$kv->delete_bucket(sub { EV::break });
EV::timer(3, 0, sub { EV::break });
EV::run;
$nats->disconnect;
