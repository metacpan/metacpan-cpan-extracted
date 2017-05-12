#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;
use Test::Deep;
use lib qw(t);
use MigraineTester;

my $migraine_tester = MigraineTester->new(__FILE__, plan => 13);

my $migrator = $migraine_tester->migrator;

ok($migrator);
is($migrator->latest_version, 11);
is($migrator->current_version, 0);
$migrator->migrate(version => 9);
cmp_deeply([ $migrator->applied_migrations ],
           [ qw(1 2 3 4 5 6 7 8 9) ],
           "Migrations without holes should be applied without problems");

# Try to upgrade to version 11. Migration 10 doesn't exist, it shouldn't work
eval { $migrator->migrate(version => 11); };
ok($EVAL_ERROR,
   "Migrations shouldn't be applied if there are holes in between");
cmp_deeply([ $migrator->applied_migrations ],
           [ qw(1 2 3 4 5 6 7 8 9) ],
           "The applied migration list should stay the same");

# The same, without explicit version
eval { $migrator->migrate; };
ok($EVAL_ERROR,
   "Migrations shouldn't be applied if there are holes in between (2)");
cmp_deeply([ $migrator->applied_migrations ],
           [ qw(1 2 3 4 5 6 7 8 9) ],
           "The applied migration list should stay the same (2)");


# Now, try to apply 11 only (it should work)
$migrator->apply_migration(11);
cmp_deeply([ $migrator->applied_migrations ],
           [ qw(1 2 3 4 5 6 7 8 9 11) ],
           "Migrations without holes should be applied without problems");

# Try to get version 10 after applying 11
eval { $migrator->migrate(version => 11); };
ok($EVAL_ERROR,
   "Migrations shouldn't be applied if there are holes in between (3)");
cmp_deeply([ $migrator->applied_migrations ],
           [ qw(1 2 3 4 5 6 7 8 9 11) ],
           "The applied migration list should stay the same (3)");

# Try to apply version 10 explicitly
eval { $migrator->apply_migration(10); };
ok($EVAL_ERROR,
   "Non-existent migrations shouldn't be applied");
cmp_deeply([ $migrator->applied_migrations ],
           [ qw(1 2 3 4 5 6 7 8 9 11) ],
           "The applied migration list should stay the same after non-existent migration");
