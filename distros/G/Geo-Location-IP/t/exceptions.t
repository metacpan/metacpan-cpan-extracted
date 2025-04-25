#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use File::Spec::Functions qw(catfile);
use Geo::Location::IP::Database::Reader;

my $file = catfile(qw(t data Test-City.mmdb));

my $reader = new_ok 'Geo::Location::IP::Database::Reader' => [file => $file];

eval { $reader->asn(ip => '176.9.54.163') };
like $@,
    qr{^The [^-]+->asn\(\) method cannot be called with a [^ ]+ database},
    'wrong database type throws exception';

eval { $reader->city(ip => undef) };
like $@, qr{^Required param \(ip\) was missing},
    'undefined IP address throws exception';

eval { $reader->city(ip => '-1') };
like $@, qr{^The IP address you provided [^ ]+ is not a valid},
    'invalid IP address throws exception';

eval { $reader->city(ip => 'me') };
like $@, qr{^me is not a valid IP}, '"me" throws exception';

eval { $reader->city(ip => '10.0.0.0') };
like $@, qr{^The IP address you provided [^ ]+ is not a public IP address},
    '10.0.0.0 throws exception';

for my $i (16 .. 31) {
    my $ip = "172.$i.0.0";
    eval { $reader->city(ip => $ip) };
    like $@,
        qr{^The IP address you provided [^ ]+ is not a public IP address},
        "$ip throws exception";
}

eval { $reader->city(ip => '192.168.0.0') };
like $@, qr{^The IP address you provided [^ ]+ is not a public IP address},
    '192.168.0.0 throws exception';

eval { $reader->city(ip => 'fd9e:21a7:a92c:2323::1') };
like $@, qr{^The IP address you provided [^ ]+ is not a public IP address},
    'private IPv6 address throws exception';

for my $ip (qw(1.10.0.1 12.172.31.12 123.192.168.123 1fc::1 12fd::1)) {
    eval { $reader->city(ip => $ip) };
    my $e = $@;
    like $e, qr{^No record found for IP address},
        'unknown address throws exception';
    is $e->ip_address, $ip, qq{IP address is "$ip"};
}

ok defined $reader->city(ip => '176.9.54.163'), 'known address succeeds';

done_testing;
