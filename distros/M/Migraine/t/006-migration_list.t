#!/usr/bin/perl

use strict;
use warnings;

use lib qw(t);
use Test::More;
use Test::Deep;
use File::Basename;

use MigraineTester;

my $migraine_tester = MigraineTester->new(__FILE__, plan => 10);

my $migrator = $migraine_tester->migrator;

ok($migrator);
cmp_deeply([ $migrator->applied_migrations ],
           [],
           "Before creating the migraine meta data the list is empty");

$migrator->create_migraine_metadata;
cmp_deeply([ $migrator->applied_migrations ],
           [],
           "Before applying migrations the list is empty");

$migrator->apply_migration(3);
cmp_deeply([ $migrator->applied_migrations ],
           [3],
           "After applying migration 3, the list should only contain 3");

$migrator->apply_migration(2);
cmp_deeply([ $migrator->applied_migrations ],
           [2, 3],
           "After applying migration 3, the list should only contain 3");

my $reapplying_works = 0;
eval {
    $migrator->apply_migration(3);
    $reapplying_works = 1;
};
is($reapplying_works, 0, "Re-applying a migration shouldn't work");
cmp_deeply([ $migrator->applied_migrations ],
           [2, 3],
           "After applying migration 3, the list should only contain 3");

$migrator->migrate(version => 3);
cmp_deeply([ $migrator->applied_migrations ],
           [1, 2, 3],
           "After migrating to version 3, the list should also contain 1");

$migrator->apply_migration(6);
cmp_deeply([ $migrator->applied_migrations ],
           [1, 2, 3, 6],
           "After applying migration 6, the list should not contain 4 or 5");

$migrator->migrate(version => 4);
cmp_deeply([ $migrator->applied_migrations ],
           [1, 2, 3, 4, 6],
           "Migrating to version 4 should add migration 4 but not 5");
