#!/usr/bin/env perl
# Verify the VALIDATE_KEY_SIZE / VALIDATE_VALUE_SIZE boundaries (1 MiB) —
# exactly at the limit must succeed at the API surface (etcd may still reject
# its own MaxRequestBytes); just over the limit must croak client-side.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;

# Minimal local Test::Fatal::exception so we don't need an extra TEST_REQUIRES.
sub exception (&) {
    my ($code) = @_;
    local $@;
    eval { $code->(); 1 } and return undef;
    return "$@";
}

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

my $available = 0;
eval {
    my $c = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], timeout => 2);
    $c->status(sub { $available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};
plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $available;

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);
my $MAX = 1024 * 1024;  # ETCD_MAX_KEY_SIZE / ETCD_MAX_VALUE_SIZE

# Just-over key: client-side croak before any RPC
my $oversize_key   = "k" . ("x" x $MAX);  # MAX + 1
my $oversize_value = "v" . ("x" x $MAX);
my $undersize_key  = "/limits-$$/" . ("x" x 64);

like(
    exception { $client->put($oversize_key, "v", sub { }) },
    qr/key too large/,
    'put: oversize key croaks client-side',
);
like(
    exception { $client->put($undersize_key, $oversize_value, sub { }) },
    qr/value too large/,
    'put: oversize value croaks client-side',
);
like(
    exception { $client->get($oversize_key, sub { }) },
    qr/key too large/,
    'get: oversize key croaks client-side',
);
like(
    exception { $client->delete($oversize_key, sub { }) },
    qr/key too large/,
    'delete: oversize key croaks client-side',
);

# Watch and txn paths use the same validation
like(
    exception { $client->watch($oversize_key, sub { }) },
    qr/key too large/,
    'watch: oversize key croaks client-side',
);
like(
    exception {
        $client->txn(
            compare => [{ key => $oversize_key, target => 'value', value => 'x' }],
            success => [],
            failure => [],
            callback => sub { },
        );
    },
    qr/key too large/,
    'txn: oversize compare key croaks client-side',
);
like(
    exception {
        $client->txn(
            compare => [],
            success => [{ request_put => { key => $undersize_key, value => $oversize_value } }],
            failure => [],
            callback => sub { },
        );
    },
    qr/value too large/,
    'txn: oversize put value croaks client-side',
);

# A value just under the limit must succeed end-to-end
my $under = "v" x ($MAX - 1);
my $put_ok;
$client->put("/limits-$$/under", $under, sub { $put_ok = !$_[1]; EV::break });
my $tu = EV::timer(5, 0, sub { EV::break });
EV::run;
ok($put_ok, 'put with value just under MAX succeeds');

$client->delete("/limits-$$/", { prefix => 1 }, sub { EV::break });
my $td = EV::timer(2, 0, sub { EV::break });
EV::run;

done_testing();
