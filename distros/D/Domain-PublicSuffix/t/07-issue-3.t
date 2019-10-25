#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Domain::PublicSuffix;

ok( my $dps = Domain::PublicSuffix->new({
	'use_default'             => 1,
	'domain_allow_underscore' => 1,
}) );

is( $dps->get_root_domain('www.kawasaki.jp'), undef, 'www.kawasaki.jp invalid' );
is( $dps->get_root_domain('city.kawasaki.jp'), 'city.kawasaki.jp', 'city.kawasaki.jp valid' );
is( $dps->get_root_domain('example.city.kawasaki.jp'), 'city.kawasaki.jp', 'example.city.kawasaki.jp reduced to city.kawasaki.jp' );

done_testing();

1;
