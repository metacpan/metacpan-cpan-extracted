#!/usr/bin/env perl
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use Test::More;
use lib 'blib/lib', 'blib/arch';

# Invalid arguments croak at the call, not later from the event loop

BEGIN {
    eval { require EV };
    if ($@) {
        plan skip_all => 'EV module not available';
        exit;
    }
}

plan tests => 27;

use_ok('EV::Etcd');

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

ok($client, 'client created');

eval { $client->get('/test/key', 'not_a_callback'); };
like($@, qr/callback must be a code reference/, 'get rejects non-coderef callback');

eval { $client->put('/test/key', 'value', 'not_a_callback'); };
like($@, qr/callback must be a code reference/, 'put rejects non-coderef callback');

eval { $client->delete('/test/key', 'not_a_callback'); };
like($@, qr/callback must be a code reference/, 'delete rejects non-coderef callback');

eval { $client->watch('/test/key', 'not_a_callback'); };
like($@, qr/callback must be a code reference/, 'watch rejects non-coderef callback');

eval { $client->lease_grant(60, 'not_a_callback'); };
like($@, qr/callback must be a code reference/, 'lease_grant rejects non-coderef callback');

eval { $client->lease_revoke(12345, 'not_a_callback'); };
like($@, qr/callback must be a code reference/, 'lease_revoke rejects non-coderef callback');

eval { $client->lease_time_to_live(12345, 'not_a_callback'); };
like($@, qr/callback must be a code reference/, 'lease_time_to_live rejects non-coderef callback');

eval { $client->lease_leases('not_a_callback'); };
like($@, qr/callback must be a code reference/, 'lease_leases rejects non-coderef callback');

eval { $client->compact(1, 'not_a_callback'); };
like($@, qr/callback must be a code reference/, 'compact rejects non-coderef callback');

eval { $client->status('not_a_callback'); };
like($@, qr/callback must be a code reference/, 'status rejects non-coderef callback');

eval { $client->role_grant_permission('r', 'BOGUS', '/k', undef, sub {}); };
like($@, qr/Invalid permission type/, 'role_grant_permission rejects invalid perm_type');

eval { $client->alarm('GET', { alarm => 'BOGUS' }, sub {}); };
like($@, qr/Invalid alarm type/, 'alarm rejects invalid alarm type');

eval { $client->txn([{ key => '/k', value => 'v', result => 'BOGUS' }], [], [], sub {}); };
like($@, qr/invalid compare result/, 'txn rejects invalid compare result');

eval { $client->txn([{ key => '/k', value => 'v', target => 'BOGUS' }], [], [], sub {}); };
like($@, qr/invalid compare target/, 'txn rejects invalid compare target');

eval { $client->txn([{ key => '/k', value => 'v', target => 5 }], [], [], sub {}); };
like($@, qr/invalid compare target/, 'txn rejects numeric target');

eval { $client->txn([{ key => '/k', value => 'v', target => [] }], [], [], sub {}); };
like($@, qr/invalid compare target/, 'txn rejects ref target');

eval { $client->txn([{ key => '/k', value => 'v', result => 5 }], [], [], sub {}); };
like($@, qr/invalid compare result/, 'txn rejects numeric result');

eval { $client->txn([{ key => '/k', value => 'v', target => undef, result => undef }], [], [], sub {}); };
ok(!$@, 'txn undef target/result behave as absent') or diag($@);

eval { EV::Etcd->new(endpoints => ['127.0.0.1:2379'], bogus_opt => 1); };
like($@, qr/Unknown option/, 'new rejects unknown option');

eval { $client->get('/k', { sort_order => 'sideways' }, sub {}); };
like($@, qr/Invalid sort_order/, 'get rejects invalid sort_order');

eval { $client->get('/k', { sort_target => 'BOGUS' }, sub {}); };
like($@, qr/Invalid sort_target/, 'get rejects invalid sort_target');

eval { $client->txn([{ key => '/k', value => 'v', result => '=', target => 'value' }], [], [], sub {}); };
ok(!$@, 'valid txn compare does not croak') or diag($@);

eval { $client->get('/k', { sort_order => 'descend', sort_target => 'value' }, sub {}); };
ok(!$@, 'valid sort opts do not croak') or diag($@);

my (@undef_warns, $undef_client);
{
    local $SIG{__WARN__} = sub { push @undef_warns, @_ };
    $undef_client = EV::Etcd->new(timeout => undef, max_retries => undef);
}
ok($undef_client, 'client created with undef numerics');
ok(!@undef_warns, 'undef numerics do not warn') or diag(@undef_warns);

done_testing();
