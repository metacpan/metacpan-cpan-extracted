#!/usr/bin/perl
use Test::More;
use Test::TempDir;

use ok 'KiokuDB';
use ok 'KiokuDB::Backend::Redis';

use KiokuDB::Test;

SKIP: {
    skip 'Must set KIOKU_REDIS_URL environment variable', 1 unless defined($ENV{KIOKU_REDIS_URL});

    for $fmt ( qw(storable json), eval { require YAML::XS; "yaml" } ) {
        run_all_fixtures(
            KiokuDB->connect("Redis:server=127.0.0.1:6379", serializer => $fmt, create => 1),
        );
    }
};

done_testing;