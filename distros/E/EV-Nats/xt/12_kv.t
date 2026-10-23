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

plan tests => 18;
my $guard;  # kept: an unkept EV::timer never fires
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
$guard = EV::timer(8, 0, sub { EV::break });
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
$guard = EV::timer(5, 0, sub { EV::break });
EV::run;

ok defined($create_seq) && $create_seq > 0,
    'create on a fresh key returns a sequence' or diag "err: $create_err";
ok !defined($conflict_seq) && defined($conflict_err),
    'create on an existing key returns an error';
like $conflict_err, qr/wrong last sequence|already exists|Last Sequence/i,
    'conflict error mentions a sequence violation' or diag "err: $conflict_err";

# update: compare-and-swap on the revision
my ($upd_seq, $upd_err, $stale_seq, $stale_err, $miss_seq, $miss_err);
$kv->put('cas', 'v1', sub {
    my ($rev) = @_;
    $kv->update('cas', 'v2', $rev, sub {
        ($upd_seq, $upd_err) = @_;
        $kv->update('cas', 'v3', $rev, sub {
            ($stale_seq, $stale_err) = @_;
            $kv->update('never-there', 'v', 5, sub {
                ($miss_seq, $miss_err) = @_;
                EV::break;
            });
        });
    });
});
$guard = EV::timer(5, 0, sub { EV::break });
EV::run;

ok defined($upd_seq) && $upd_seq > 0,
    'update on the current revision returns a sequence' or diag "err: $upd_err";
ok !defined($stale_seq) && ($stale_err // '') =~ /wrong last sequence/i,
    'update on a stale revision fails' or diag "err: $stale_err";
ok !defined($miss_seq) && ($miss_err // '') =~ /wrong last sequence/i,
    'update on a missing key fails' or diag "err: $miss_err";
eval { $kv->update('cas', 'v', 0, sub {}) };
like $@, qr/invalid KV revision/, 'update with rev 0 croaks up front';

# delete/purge interplay with get and keys
my ($del_ok, $got_del, $keys_del, $got_purged);
$kv->put('gone', 'v', sub {
    $kv->delete('gone', sub {
        ($del_ok) = @_;
        $kv->get('gone', sub {
            ($got_del) = @_;
            $kv->keys(sub {
                $keys_del = $_[0];
                $kv->purge('gone', sub {
                    $kv->get('gone', sub {
                        ($got_purged) = @_;
                        EV::break;
                    });
                });
            });
        });
    });
});
$guard = EV::timer(5, 0, sub { EV::break });
EV::run;

ok $del_ok, 'delete reports ok';
is $got_del, undef, 'get after delete is undef';
ok(ref($keys_del) eq 'ARRAY' && (grep { $_ eq 'gone' } @$keys_del),
    'keys still lists the tombstoned key');
is $got_purged, undef, 'get after purge is undef';

subtest 'deleted and purged keys can be recreated atomically' => sub {
    for my $op (qw(delete purge)) {
        my $key = "reuse_$op";
        my @results;
        $kv->create($key, 'original', sub {
            $kv->$op($key, sub {
                for my $writer (1..2) {
                    $kv->create($key, "writer$writer", sub {
                        push @results, [@_, "writer$writer"];
                        EV::break if @results == 2;
                    });
                }
            });
        });
        $guard = EV::timer(5, 0, sub { EV::break });
        EV::run;
        is scalar @results, 2, "$op: both creators completed";
        my @winners = grep { defined $_->[0] && !defined $_->[1] } @results;
        is scalar @winners, 1, "$op: exactly one creator acquired the deleted key";
        my @losers = grep { !defined $_->[0] && defined $_->[1] } @results;
        is scalar @losers, 1, "$op: competing creator reported a conflict";
        my $value;
        $kv->get($key, sub { $value = $_[0]; EV::break });
        $guard = EV::timer(3, 0, sub { EV::break });
        EV::run;
        is $value, @winners ? $winners[0][2] : 'missing winner',
            "$op: winner's value stored";
    }
};

my $st;
$kv->status(sub { $st = $_[0]; EV::break });
$guard = EV::timer(3, 0, sub { EV::break });
EV::run;
ok $st && $st->{bucket} eq $bucket && $st->{values} > 0 && $st->{history} == 1,
    'status shape sane';

$kv->delete_bucket(sub { EV::break });
$guard = EV::timer(3, 0, sub { EV::break });
EV::run;
$nats->disconnect;
