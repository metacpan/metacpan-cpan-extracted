#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Domain::PublicSuffix;

ok( my $dps = Domain::PublicSuffix->new({
	'use_default'        => 1,
	'allow_unlisted_tld' => 0,
}) );

is( $dps->get_root_domain('www.example.com.'), 'example.com',
    'Trailing dots do work.' );

done_testing();

1;
