use v5.20;
use Test2::V0;

use strict;
use warnings;

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use IP::Random;

my (@ips) = map { IP::Random::random_ipv4() } 0 .. 2047;

my (@octets) = map { 0 } ( 0 .. 255 );
for my $ip (@ips) {
    foreach my $oct ( split( /\./, $ip ) ) {
        $octets[$oct]++;
    }
}

subtest 'randomness', sub {
    for ( my $oct = 0; $oct < 256; $oct++ ) {
        my $min = ( ( $oct == 0 ) || ( $oct == 10 ) || ( $oct > 224 ) ) ? 2 : 4;
        ok( $octets[$oct] <= 64,   "$oct randomness 1 ($octets[$oct])" );
        ok( $octets[$oct] >= $min, "$oct randomness 2 ($octets[$oct])" );
    }

    done_testing;
};

subtest 'not invalid', sub {
    is( scalar grep( { $_ =~ m/^0\./ } @ips ),   0, 'IPs starting with 0.' );
    is( scalar grep( { $_ =~ m/^10\./ } @ips ),  0, 'IPs starting with 10.' );
    is( scalar grep( { $_ =~ m/^240\./ } @ips ), 0, 'IPs starting with 240.' );
    done_testing;
};

subtest 'only RFC1112', sub {
    (@ips) = map {
        IP::Random::random_ipv4(
            additional_types_allowed => [
                'rfc919',  'rfc1122', 'rfc1918', 'rfc2544', 'rfc3068', 'rfc3171',
                'rfc3927', 'rfc5736', 'rfc5737', 'rfc6598'
            ]
          )
    } 0 .. 2047;

    ok( scalar grep( { $_ =~ m/^0\./ } @ips ) > 0,  'IPs starting with 0.' );
    ok( scalar grep( { $_ =~ m/^10\./ } @ips ) > 0, 'IPs starting with 10.' );
    is( scalar grep( { $_ =~ m/^240\./ } @ips ), 0, 'IPs starting with 240.' );

    done_testing;
};

subtest 'RFC1112 and RFC 1122', sub {
    (@ips) = map {
        IP::Random::random_ipv4(
            additional_types_allowed => [
                'rfc919',  'rfc1918', 'rfc2544', 'rfc3068', 'rfc3171', 'rfc3927',
                'rfc5736', 'rfc5737', 'rfc6598'
            ]
          )
    } 0 .. 2047;

    is( scalar grep( { $_ =~ m/^0\./ } @ips ), 0, 'IPs starting with 0.' );
    ok( scalar grep( { $_ =~ m/^10\./ } @ips ) > 0, 'IPs starting with 10.' );
    is( scalar grep( { $_ =~ m/^240\./ } @ips ), 0, 'IPs starting with 240.' );

    done_testing;
};

subtest 'RFC1112 and RFC 1122', sub {
    (@ips) = map {
        IP::Random::random_ipv4(
            additional_types_allowed => [
                'rfc919',  'rfc1918', 'rfc2544', 'rfc3068', 'rfc3171', 'rfc3927',
                'rfc5736', 'rfc5737', 'rfc6598'
            ]
          )
    } 0 .. 2047;

    is( scalar grep( { $_ =~ m/^0\./ } @ips ), 0, 'IPs starting with 0.' );
    ok( scalar grep( { $_ =~ m/^10\./ } @ips ) > 0, 'IPs starting with 10.' );
    is( scalar grep( { $_ =~ m/^240\./ } @ips ), 0, 'IPs starting with 240.' );

    done_testing;
};

subtest 'RFC1112 and RFC 1122 via exclude', sub {
    (@ips) = map { IP::Random::random_ipv4( exclude => [ 'rfc1112', 'rfc1122', ] ) } 0 .. 2047;

    is( scalar grep( { $_ =~ m/^0\./ } @ips ), 0, 'IPs starting with 0.' );
    ok( scalar grep( { $_ =~ m/^10\./ } @ips ) > 0, 'IPs starting with 10.' );
    is( scalar grep( { $_ =~ m/^240\./ } @ips ), 0, 'IPs starting with 240.' );

    done_testing;
};

subtest 'RFC1112 and RFC 1122 via additional_exclude', sub {
    (@ips) = map {
        IP::Random::random_ipv4( exclude => [], additional_exclude => [ 'rfc1112', 'rfc1122', ] )
    } 0 .. 2047;

    is( scalar grep( { $_ =~ m/^0\./ } @ips ), 0, 'IPs starting with 0.' );
    ok( scalar grep( { $_ =~ m/^10\./ } @ips ) > 0, 'IPs starting with 10.' );
    is( scalar grep( { $_ =~ m/^240\./ } @ips ), 0, 'IPs starting with 240.' );

    done_testing;
};

done_testing;

