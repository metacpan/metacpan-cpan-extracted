#!/usr/bin/perl

use strict;
use warnings;

use lib qw(t);
use Test::More;
use File::Basename;

use MigraineTester;

my $migraine_tester = MigraineTester->new(__FILE__, plan => 6);

our ($count, $passes, $name_passes) = (1, 0, 0);
my $migrator = $migraine_tester->migrator;

ok($migrator);
is($migrator->latest_version, 11);
is($migrator->current_version, 0);
$migrator->migrate(after_migrate => sub {
                                            $passes++ if $_[0] eq $count;
                                            $name_passes++ if basename($_[1]) eq sprintf("%03s-some.sql", $_[0]);
                                            $count++;
                                        });
is($migrator->current_version, 11);
is($passes, 11);
is($name_passes, 11);
