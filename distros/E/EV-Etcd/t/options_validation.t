#!/usr/bin/env perl
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use Test::More;
use lib 'blib/lib', 'blib/arch';

# Unknown option keys croak at the call; every documented key stays accepted

BEGIN {
    eval { require EV };
    if ($@) {
        plan skip_all => 'EV module not available';
        exit;
    }
}

plan tests => 64;

use_ok('EV::Etcd');

# Nothing listens there: the accepted calls (delete, compact, member_add)
# must not reach a real etcd
my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:1'],
);

ok($client, 'client created');

my $cb = sub { };

eval { $client->get('/k', { bogus => 1 }, $cb); };
like($@, qr/Unknown option 'bogus'/, 'get rejects unknown option');

eval { $client->put('/k', 'v', { bogus => 1 }, $cb); };
like($@, qr/Unknown option 'bogus'/, 'put rejects unknown option');

eval { $client->delete('/k', { bogus => 1 }, $cb); };
like($@, qr/Unknown option 'bogus'/, 'delete rejects unknown option');

eval { $client->watch('/k', { bogus => 1 }, $cb); };
like($@, qr/Unknown option 'bogus'/, 'watch rejects unknown option');

eval { $client->lease_time_to_live(12345, { bogus => 1 }, $cb); };
like($@, qr/Unknown option 'bogus'/, 'lease_time_to_live rejects unknown option');

eval { $client->compact(1, { bogus => 1 }, $cb); };
like($@, qr/Unknown option 'bogus'/, 'compact rejects unknown option');

eval { $client->lease_keepalive(12345, { bogus => 1 }, $cb); };
like($@, qr/Unknown option 'bogus'/, 'lease_keepalive rejects unknown option');

eval { $client->election_observe('el', { bogus => 1 }, $cb); };
like($@, qr/Unknown option 'bogus'/, 'election_observe rejects unknown option');

eval { $client->member_list({ bogus => 1 }, $cb); };
like($@, qr/Unknown option 'bogus'/, 'member_list rejects unknown option');

eval { $client->member_add(['http://127.0.0.1:2380'], { bogus => 1 }, $cb); };
like($@, qr/Unknown option 'bogus'/, 'member_add rejects unknown option');

eval { $client->alarm('GET', { bogus => 1 }, $cb); };
like($@, qr/Unknown option 'bogus'/, 'alarm rejects unknown option');

eval {
    $client->get('/k', {
        range_end => '/z', prefix => 0, limit => 10, revision => 0,
        keys_only => 0, count_only => 0, serializable => 0,
        sort_order => 'descend', sort_target => 'value',
        min_mod_revision => 0, max_mod_revision => 0,
        min_create_revision => 0, max_create_revision => 0,
    }, $cb);
};
ok(!$@, 'get accepts all documented options') or diag($@);

eval { $client->put('/k', 'v', { lease => 0, prev_kv => 0, ignore_value => 0, ignore_lease => 0 }, $cb); };
ok(!$@, 'put accepts all documented options') or diag($@);

eval { $client->delete('/k', { range_end => '/z', prefix => 0, prev_kv => 0 }, $cb); };
ok(!$@, 'delete accepts all documented options') or diag($@);

eval {
    $client->watch('/k', {
        auto_reconnect => 0, range_end => '/z', prefix => 0,
        start_revision => 0, progress_notify => 0, prev_kv => 0, watch_id => 0,
    }, $cb);
};
ok(!$@, 'watch accepts all documented options') or diag($@);

eval { $client->lease_time_to_live(12345, { keys => 1 }, $cb); };
ok(!$@, 'lease_time_to_live accepts all documented options') or diag($@);

eval { $client->compact(1, { physical => 1 }, $cb); };
ok(!$@, 'compact accepts all documented options') or diag($@);

eval { $client->lease_keepalive(12345, { auto_reconnect => 0 }, $cb); };
ok(!$@, 'lease_keepalive accepts all documented options') or diag($@);

eval { $client->election_observe('el', { auto_reconnect => 0 }, $cb); };
ok(!$@, 'election_observe accepts all documented options') or diag($@);

eval { $client->member_list({ linearizable => 1 }, $cb); };
ok(!$@, 'member_list accepts all documented options') or diag($@);

eval { $client->member_add(['http://127.0.0.1:2380'], { is_learner => 1 }, $cb); };
ok(!$@, 'member_add accepts all documented options') or diag($@);

eval { $client->alarm('GET', { alarm => 'NOSPACE', member_id => 0 }, $cb); };
ok(!$@, 'alarm accepts all documented options') or diag($@);

eval { $client->txn(compare => [], sucess => [], $cb); };
like($@, qr/Unknown option 'sucess'/, 'txn rejects unknown named argument');

my @txn_warns;
{
    local $SIG{__WARN__} = sub { push @txn_warns, @_ };
    eval { $client->txn([], [], []); };
    like($@, qr/expected.*positional.*pairs|pairs.*positional/, 'txn 3-array croaks clearly');
}
ok(!@txn_warns, 'txn 3-array does not warn') or diag(@txn_warns);

eval { $client->txn([], [], [], []); };
like($@, qr/callback must be a code reference/, 'txn 4-arg near-miss keeps callback diagnostic');

eval { $client->txn(compare => [], success => [], failure => [], callback => $cb); };
ok(!$@, 'txn named form with callback key does not croak') or diag($@);

eval { $client->txn(compare => [], success => [], failure => [], $cb); };
ok(!$@, 'txn named form with trailing callback does not croak') or diag($@);

eval { $client->txn([], [], [], $cb); };
ok(!$@, 'txn positional form does not croak') or diag($@);

sub croaks {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    like($ok ? 'no croak' : $@, $re, $name);
}

# Arguments of the wrong type croak instead of silently falling back
croaks(sub { EV::Etcd->new(endpoints => '10.0.0.1:2379') },
    qr/endpoints must be an array reference/, 'string endpoints croaks');
croaks(sub { EV::Etcd->new(endpoints => [undef]) },
    qr/endpoints element 0 is undefined/, 'undef endpoint croaks');
croaks(sub { EV::Etcd->new(endpoints => []) },
    qr/endpoints is empty/, 'empty endpoints croaks');
croaks(sub { EV::Etcd->new(endpoints => ['http://']) },
    qr/endpoints element 0 is empty/, 'empty endpoint croaks');
croaks(sub { EV::Etcd->new(endpoints => ["127.0.0.1:1\0x"]) },
    qr/endpoint contains a NUL byte/, 'endpoint with a NUL croaks');
croaks(sub { EV::Etcd->new(on_health_change => 'not code') },
    qr/on_health_change must be a code reference/, 'non-code on_health_change croaks');
croaks(sub { EV::Etcd->new(endpoints => ['127.0.0.1:1'], auth_token => "token\n") },
    qr/auth_token must be printable ASCII/, 'auth_token with a newline croaks');
croaks(sub { $client->put('/k', 'v', 12345, $cb) },
    qr/options must be a hash reference/, 'positional lease for put croaks');
croaks(sub { $client->get('/k', [prefix => 1], $cb) },
    qr/options must be a hash reference/, 'array options croak');
ok(eval { $client->get('/k', undef, $cb); 1 }, 'undef options are accepted') or diag($@);

my %iter_opts = (prefix => 1, keys_only => 1);
my $iterations = 0;
while (my ($k) = each %iter_opts) {
    last if ++$iterations > 5;
    $client->get('/k', \%iter_opts, $cb);
}
is($iterations, 2, "validating options keeps the caller's each() iterator");

croaks(sub { $client->user_delete("root\0x", $cb) },
    qr/name contains a NUL byte/, 'name with a NUL croaks');
croaks(sub { $client->user_add('u', "pw\0rest", $cb) },
    qr/password contains a NUL byte/, 'password with a NUL croaks');
croaks(sub { $client->member_add(["http://a\0b:2380"], $cb) },
    qr/peer URL contains a NUL byte/, 'peer URL with a NUL croaks');

croaks(sub { $client->txn([], [{ delete => { key => '/jobs/', prefix => 1 } }], [], $cb) },
    qr/Unknown option 'prefix' in \$client->txn delete/, 'unsupported txn op key croaks');
croaks(sub { $client->txn([{ key => '/k', mod => 5 }], [], [], $cb) },
    qr/Unknown option 'mod' in \$client->txn compare/, 'misspelt compare key croaks');
croaks(sub { $client->txn([], [{ get => { key => '/k' } }], [], $cb) },
    qr/Unknown option 'get' in \$client->txn operation/, 'unknown txn op croaks');
croaks(sub { $client->txn([], ['x'], [], $cb) },
    qr/success operation 0 is not a hash reference/, 'non-hash txn op croaks');
croaks(sub { $client->txn([], [], [{ put => { key => 'a' }, delete => { key => 'b' } }], $cb) },
    qr/failure operation 0 needs exactly one/, 'two ops in one txn element croak');
croaks(sub { $client->txn(compare => {}, success => [], failure => [], callback => $cb) },
    qr/compare'? must be an array reference/, 'non-array compare croaks');
croaks(sub { $client->txn([{ key => '/k', target => 'mod', version => 5 }], [], [], $cb) },
    qr/has target 'mod' but a version field/, 'compare target disagreeing with its field croaks');
croaks(sub { $client->txn([{ key => '/k', version => 1, mod_revision => 2 }], [], [], $cb) },
    qr/more than one of value, version/, 'compare with two value fields croaks');
ok(eval { $client->txn([{ key => '/k', target => 'version' }], [], [], $cb); 1 },
    'compare with a target and no field is accepted') or diag($@);
croaks(sub { $client->lock('/k', 0, $cb) },
    qr/lease_id must be a granted lease/, 'lock without a lease croaks');
croaks(sub { $client->election_campaign('/e', 0, 'v', $cb) },
    qr/lease_id must be a granted lease/, 'campaign without a lease croaks');
croaks(sub { $client->election_proclaim({ name => '/e', key => '/e/1', rev => 5 }, 'v', $cb) },
    qr/leader must be the hash election_campaign returned/, 'proclaim without the leader lease croaks');
croaks(sub { $client->election_resign({ name => '/e', key => '/e/1', lease => 7 }, $cb) },
    qr/leader must be the hash election_campaign returned/, 'resign without the leader rev croaks');
{
    require Tie::Hash;
    tie my %leader, 'Tie::StdHash';
    %leader = (name => '/e', key => '/e/1', rev => 5, lease => 7);
    ok(eval { $client->election_resign(\%leader, $cb); 1 }, 'tied leader hash is accepted') or diag($@);
}

my $handle = $client->watch('/k', $cb);
eval { die "pending error\n" };
$handle->cancel(sub {});
is($@, "pending error\n", "cancel keeps the caller's \$@");
my @returned = $handle->cancel(sub {});
is(scalar @returned, 0, 'cancel of a cancelled handle returns nothing');

my $blessed_cb = bless sub { }, 'My::Callback';
ok(eval { $client->txn([], [], [], $blessed_cb); 1 }, 'txn takes a blessed callback') or diag($@);
ok(eval { $client->txn(compare => bless([], 'My::List'), success => [], callback => $blessed_cb); 1 },
    'txn takes blessed arrays and a blessed callback by name') or diag($@);

{
    package My::Etcd;
    our @ISA = ('EV::Etcd');
}
isa_ok(My::Etcd->new(endpoints => ['127.0.0.1:1']), 'My::Etcd', 'new from a subclass');

done_testing();
