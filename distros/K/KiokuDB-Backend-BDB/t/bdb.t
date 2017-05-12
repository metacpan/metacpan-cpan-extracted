#!/usr/bin/perl

use Test::More 'no_plan';
use Test::TempDir;

use ok 'KiokuDB';
use ok 'KiokuDB::Backend::BDB';

use KiokuDB::Test;

for $fmt ( qw(storable json), eval { require YAML::XS; "yaml" } ) {
    run_all_fixtures(
        KiokuDB->connect("bdb:dir=" . temp_root, serializer => $fmt, create => 1),
    );
}
