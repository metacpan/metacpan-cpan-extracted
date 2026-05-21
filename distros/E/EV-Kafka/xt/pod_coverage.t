use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING' unless $ENV{RELEASE_TESTING};

eval { require Test::Pod::Coverage; Test::Pod::Coverage->import; 1 }
    or plan skip_all => 'Test::Pod::Coverage required';

# Methods documented elsewhere or intentionally undocumented (internal helpers,
# private XS thunks).
my $trustme = [
    qr/^_/,                # private helpers
    qr/^DESTROY$/,
    qr/^new$/,             # documented under EV::Kafka not EV::Kafka::Client
    qr/^connected$/,       # XS accessor, listed as one-liner
    qr/^state$/,
    qr/^pending$/,
    qr/^client_id$/,
    qr/^tls$/,
    qr/^sasl$/,
    qr/^auto_reconnect$/,
];

pod_coverage_ok('EV::Kafka',
    { also_private => $trustme, trustme => $trustme });
done_testing;
