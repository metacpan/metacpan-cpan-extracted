#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese timethese);

use Horus qw(:all);

print "=== Horus UUID Benchmark ===\n\n";

print "--- Single UUID generation (per second) ---\n";
cmpthese(-3, {
    'v4_str'       => sub { uuid_v4() },
    'v4_hex'       => sub { uuid_v4(UUID_FMT_HEX) },
    'v4_binary'    => sub { uuid_v4(UUID_FMT_BINARY) },
    'v4_base64'    => sub { uuid_v4(UUID_FMT_BASE64) },
    'v4_crockford' => sub { uuid_v4(UUID_FMT_CROCKFORD) },
    'v1'           => sub { uuid_v1() },
    'v7'           => sub { uuid_v7() },
});

print "\n--- Batch v4 generation (1000 UUIDs per call) ---\n";
cmpthese(-3, {
    'bulk_1000'   => sub { uuid_v4_bulk(1000) },
    'loop_1000'   => sub { uuid_v4() for 1..1000 },
});

print "\n--- Namespace UUIDs ---\n";
my $ns = UUID_NS_DNS();
cmpthese(-3, {
    'v3_md5'  => sub { uuid_v3($ns, 'example.com') },
    'v5_sha1' => sub { uuid_v5($ns, 'example.com') },
});

print "\n--- Parse + Validate ---\n";
my $sample = uuid_v4();
cmpthese(-3, {
    'validate' => sub { uuid_validate($sample) },
    'parse'    => sub { uuid_parse($sample) },
    'convert'  => sub { uuid_convert($sample, UUID_FMT_BASE64) },
});

# Comparison with Data::UUID if available
eval {
    require Data::UUID;
    my $ug = Data::UUID->new;
    print "\n--- vs Data::UUID ---\n";
    cmpthese(-3, {
        'Horus::uuid_v4'        => sub { uuid_v4() },
        'Data::UUID::create_str' => sub { $ug->create_str() },
    });
};

# Comparison with UUID::Tiny if available
eval {
    require UUID::Tiny;
    UUID::Tiny->import(':std');
    print "\n--- vs UUID::Tiny ---\n";
    cmpthese(-3, {
        'Horus::uuid_v4'  => sub { uuid_v4() },
        'UUID::Tiny::v4'  => sub { UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_V4()) },
    });
};
