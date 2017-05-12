#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use lib qw(t);
use MigraineTester;

my $migraine_tester = MigraineTester->new(__FILE__, plan => 8);

my $migrator = $migraine_tester->migrator;

ok($migrator);
is($migrator->latest_version, 3);
is($migrator->current_version, 0);
$migrator->migrate(version => 2);
is($migrator->current_version, 2);

my $data = $migraine_tester->fetch_data("SELECT id FROM coucou");
cmp_deeply($data, [[5]]);

eval { $migrator->migrate(version => 1); };
is($migrator->current_version, 2);
$migrator->migrate;
is($migrator->current_version, 3);

my $updated_data = $migraine_tester->fetch_data("SELECT id FROM coucou");
cmp_deeply($updated_data, [[6]]);
