#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use lib qw(t);
use MigraineTester;

our $shared_before = 0;
our $shared_after  = 0;

my $migraine_tester = MigraineTester->new(__FILE__, plan => 17);

my $migrator = $migraine_tester->migrator;

ok($migrator);
is($migrator->latest_version, 3);
is($migrator->current_version, 0);
$migrator->migrate(version => 2, before_migrate => sub {
                                     my ($version, $path) = @_;
                                     $shared_before++;
                                     is($version, $shared_before, "Check version number for migration $shared_before\n");
                                     my $regex = sprintf("%03s-some.sql", $version);
                                     like($path, qr/$regex$/, "Check version number for migration $shared_before\n");
                                 },
                                 after_migrate => sub {
                                     my ($version, $path) = @_;
                                     $shared_after++;
                                     is($version, $shared_after, "Check version number for migration $shared_after\n");
                                     my $regex = sprintf("%03s-some.sql", $version);
                                     like($path, qr/$regex$/, "Check version number for migration $shared_after\n");
                                 });
is($migrator->current_version, 2);

is($shared_before, 2);
is($shared_after,  2);

$migrator->migrate;
is($migrator->current_version, 3);

is($shared_before, 2);
is($shared_after,  2);
