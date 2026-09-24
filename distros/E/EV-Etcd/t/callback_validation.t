#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';

# A non-coderef callback croaks at the call, not later from the event loop

BEGIN {
    eval { require EV };
    if ($@) {
        plan skip_all => 'EV module not available';
        exit;
    }
}

plan tests => 12;

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

done_testing();
