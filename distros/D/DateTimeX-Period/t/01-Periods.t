#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use DateTimeX::Period qw();

my $dt = DateTimeX::Period->now();

dies_ok {
	$dt->get_start('doesnotexist')
} 'get_start() dies on unknown period';

dies_ok {
	$dt->get_end('doesnotexist')
} 'get_end() dies on unknown period';

my $keys;
lives_ok {
	$keys = $dt->get_period_keys()
} 'Can get ordered list of keys';

ok( !grep(!defined $dt->get_period_label($_), @{$keys} ),
	'all defined keys has value corresponding');

dies_ok {
	$dt->get_period_label('doesnotexist')
} 'get_period_label() dies on undefined key';

done_testing();
