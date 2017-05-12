#!/usr/bin/perl

use strict;
use warnings;

use lib qw(t);
use Test::More;
use Test::Deep;
use File::Basename;

use MigraineTester;

my $migraine_tester = MigraineTester->new(__FILE__, plan => 14);

my $migrator = $migraine_tester->migrator;

$migrator->migrate(version => 3);
cmp_deeply([ $migrator->applied_migrations ],
           [1,2,3],
           "Migrating to version 3, the applied migrations should be correct");
cmp_deeply([ $migrator->applied_migration_ranges ],
           ["1-3"],
           "Simple range test should work");

$migrator->apply_migration(5);
cmp_deeply([ $migrator->applied_migrations ],
           [1,2,3,5],
           "After applying migration 5, the list should not contain 4");
cmp_deeply([ $migrator->applied_migration_ranges ],
           ["1-3", "5"],
           "Simple range test with a 'hole' should work");

$migrator->apply_migration(6);
cmp_deeply([ $migrator->applied_migrations ],
           [1,2,3,5,6],
           "After applying migration 6, the list should not contain 4");
cmp_deeply([ $migrator->applied_migration_ranges ],
           ["1-3", "5-6"],
           "Simple range test with a 'hole' ending in range should work");

$migrator->migrate(version => 3);
cmp_deeply([ $migrator->applied_migrations ],
           [1,2,3,5,6],
           "Migrating up to version 3 shouldn't add migrations or die");
cmp_deeply([ $migrator->applied_migration_ranges ],
           ["1-3", "5-6"],
           "The ranges should stay the same if there aren't changes");

$migrator->apply_migration(4);
cmp_deeply([ $migrator->applied_migrations ],
           [1,2,3,4,5,6],
           "After applying migration 4, the list should contain 1-6");
cmp_deeply([ $migrator->applied_migration_ranges ],
           ["1-6"],
           "Simple range test after fixing the 'hole' should work");

$migrator->apply_migration(8);
cmp_deeply([ $migrator->applied_migrations ],
           [1,2,3,4,5,6,8],
           "After applying migration 8, there should be another range");
cmp_deeply([ $migrator->applied_migration_ranges ],
           ["1-6", "8"],
           "After applying an extra migration, there should be a second range");

$migrator->migrate(version => 7);
cmp_deeply([ $migrator->applied_migrations ],
           [1,2,3,4,5,6,7,8],
           "Migrating up to version 7 should plug the hole");
cmp_deeply([ $migrator->applied_migration_ranges ],
           ["1-8"],
           "The range should be complete after plugging the hole");
