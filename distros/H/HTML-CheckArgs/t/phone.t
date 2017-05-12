#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

# required US phone
$config = {
	phone => {
		as => 'phone',
		required => 1,
		label => 'Phone',
		params => { country => 'US' },
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'phone' );
is( $handler->value, undef );
is( $handler->error_code, 'phone_00' );

# invalid value
$handler->validate( 'phone', '803781065' );
is( $handler->value, undef );
is( $handler->error_code, 'phone_01' );

# valid value, hyphens
$handler->validate( 'phone', '202-555-1515' );
is( $handler->value, '2025551515' );
is( $handler->error_code, undef );
