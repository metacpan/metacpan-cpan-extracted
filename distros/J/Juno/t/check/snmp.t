#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

{
    local $@ = undef;
    eval 'use Net::SNMP';
    $@ and plan skip_all => 'Net::SNMP is required for this test';
}

{
    local $@ = undef;
    eval 'use AnyEvent::SNMP';
    $@ and plan skip_all => 'AnyEvent::SNMP is required for this test';
}

{
    local $@ = undef;
    eval 'use Juno::Check::SNMP';
    $@ and plan skip_all => 'Juno::Check::SNMP is required for this test';
}

plan tests => 7;

like(
    exception {
        Juno::Check::SNMP->new(
            community   => 'b',
            version     => 2,
            oid         => 'stuff2'
        );
    },
    qr/^\QMissing required arguments: hostname\E/,
    'Attribute hostname required',
);

like(
    exception {
        Juno::Check::SNMP->new(
            hostname => 'a',
            version  => 2,
            oid      => 'stuff2',
        );
    },
    qr/^\QMissing required arguments: community\E/,
    'Attribute community required',
);

like(
    exception {
        Juno::Check::SNMP->new(
            hostname  => 'a',
            community => 'b',
            oid       => 'stuff2',
        );
    },
    qr/^\QMissing required arguments: version\E/,
    'Attribute version required',
);

like(
    exception {
        Juno::Check::SNMP->new(
            hostname  => 'a',
            community => 'b',
            version   => 2,
        );
    },
    qr/^\QMissing required arguments: oid\E/,
    'Attribute oid required',
);

my $juno = Juno::Check::SNMP->new(
    hostname  => 'localhost',
    community => 'stuff',
    version   => 2,
    oid       => 'stuff2',
);

isa_ok( $juno, 'Juno::Check::SNMP' );
isa_ok( $juno->session, 'Net::SNMP' );
is( $juno->session->hostname, 'localhost', 'hostname passed to SNMP session' );
