#!/usr/bin/perl -w

use strict;
use warnings FATAL => 'all';
use Test::More 0.88;

use Config;

use ExtUtils::Config;

my $config = ExtUtils::Config->new;

ok($config->exists('path_sep'), "'path_sep' is set");
is($config->get('path_sep'), $Config{path_sep}, "'path_sep' is the same for \$Config");

ok(!$config->exists('nonexistent'), "'nonexistent' is still nonexistent");

ok(!defined $config->get('nonexistent'), "'nonexistent' is not defined");

is_deeply($config->all_config, \%Config, 'all_config is \%Config');

my $config2 = ExtUtils::Config->new({ more => 'nomore' });
my %myconfig = (%Config, more => 'nomore');

is_deeply($config2->values_set, { more => 'nomore' }, 'values_set is { more => \'nomore\'}');
is_deeply($config2->all_config, \%myconfig, 'allconfig is myconfig');

my $set = $config->values_set;
$set->{more} = 'more3';
is($config->get('more'), $Config{more}, "more is still '$Config{more}'");

done_testing;
