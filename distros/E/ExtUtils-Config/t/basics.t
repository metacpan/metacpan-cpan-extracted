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

my $config3 = $config2->but({ more => undef, less => 'more' });
%myconfig = (%Config, less => 'more');

is_deeply($config3->values_set, { less => 'more' }, 'values_set is { less => \'more\' }');
is_deeply($config3->all_config, \%myconfig, 'allconfig is myconfig');

my $set = $config->values_set;
$set->{more} = 'more3';
is($config->get('more'), $Config{more}, "more is still '$Config{more}'");

use ExtUtils::Config::MakeMaker;

my $config4 = ExtUtils::Config::MakeMaker->new({ OPTIMIZE => 'some_value' });
%myconfig = (%Config, optimize => 'some_value');

is_deeply($config4->values_set, { optimize => 'some_value' }, 'values_set is { optimize => \'some_value\' }');
is_deeply($config4->all_config, \%myconfig, 'allconfig is myconfig');

my $config5 = $config4->materialize;

is_deeply($config5->values_set, { optimize => 'some_value' }, 'values_set is { optimize => \'some_value\' }');
is_deeply($config5->all_config, \%myconfig, 'allconfig is myconfig');

done_testing;
