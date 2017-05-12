#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Domain::PublicSuffix;

ok( my $dps = Domain::PublicSuffix->new({
	'use_default'             => 1,
	'domain_allow_underscore' => 1,
}) );

is( $dps->get_root_domain('s3.amazonaws.com'), undef, 's3 invalid' );
is( $dps->get_root_domain('foo.s3.amazonaws.com'), 'foo.s3.amazonaws.com', 'foo.s3 valid' );
is( $dps->suffix(), 's3.amazonaws.com', 'foo.s3 suffix is s3' );

done_testing();

1;
