#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Domain::PublicSuffix;

ok( my $dps = Domain::PublicSuffix->new({
	'use_default'             => 1,
	'domain_allow_underscore' => 1,
}) );

is( $dps->get_root_domain('m.com.ac'), 'm.com.ac', 'm.com.ac valid' );
is( $dps->suffix(), 'com.ac', 'm.com.ac -> com.ac');
is( $dps->get_root_domain('com.ac'), undef, 'com.ac invalid' );
is( $dps->suffix(), 'com.ac', 'suffix com.ac -> com.ac');
is( $dps->tld(), 'ac', 'tld com.ac -> ac');

done_testing();

1;
