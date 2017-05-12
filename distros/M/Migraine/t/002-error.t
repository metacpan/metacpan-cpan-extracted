#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use lib qw(t);
use MigraineTester;

my $migraine_tester = MigraineTester->new(__FILE__, plan => 6);

my $migrator = $migraine_tester->migrator;

ok($migrator);
is($migrator->latest_version, 3);
is($migrator->current_version, 0);
$migrator->migrate(version => 2);
is($migrator->current_version, 2);
eval { $migrator->migrate; };
ok($@);
is($migrator->current_version, 2);
