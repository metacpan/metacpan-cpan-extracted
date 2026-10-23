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

# Client and Conn live in EV/Kafka.pm: satisfy the require and point
# Pod::Coverage at the shared POD file.
require EV::Kafka;
$INC{'EV/Kafka/Client.pm'} = __FILE__;
$INC{'EV/Kafka/Conn.pm'}   = __FILE__;
for my $pkg (qw(EV::Kafka::Client EV::Kafka::Conn)) {
    pod_coverage_ok($pkg,
        { also_private => $trustme, trustme => $trustme,
          pod_from => 'lib/EV/Kafka.pm' });
}
done_testing;
