use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/DBIx/Class/KiokuDB.pm',
    'lib/DBIx/Class/KiokuDB/EntryProxy.pm',
    'lib/DBIx/Class/Schema/KiokuDB.pm',
    'lib/KiokuDB/Backend/DBI.pm',
    'lib/KiokuDB/Backend/DBI/Schema.pm',
    'lib/KiokuDB/TypeMap/Entry/DBIC/ResultSet.pm',
    'lib/KiokuDB/TypeMap/Entry/DBIC/ResultSource.pm',
    'lib/KiokuDB/TypeMap/Entry/DBIC/Row.pm',
    'lib/KiokuDB/TypeMap/Entry/DBIC/Schema.pm'
);

notabs_ok($_) foreach @files;
done_testing;
