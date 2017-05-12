#!/usr/bin/perl

use Test::More 'no_plan';
use Test::TempDir;

use ok 'KiokuDB';
use ok 'KiokuDB::Backend::Files';

use KiokuDB::Test;

foreach my $fmt ( qw(storable json), eval { require YAML::XS; 'yaml' } ) {
    run_all_fixtures( KiokuDB->connect("files:dir=" . tempdir, serializer => $fmt, global_lock => 1 ) );
}

run_all_fixtures( KiokuDB->connect("files:dir=" . tempdir, trie => 1, global_lock => 1 ) );
