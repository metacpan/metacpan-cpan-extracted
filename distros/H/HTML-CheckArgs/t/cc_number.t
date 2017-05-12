#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 9;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

$config = {
	cc_number => {
		as			=> 'cc_number',
		required	=> 1,
		label		=> 'Card Number',
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'cc_number' );
is( $handler->value, undef );
is( $handler->error_code, 'cc_number_00' );

# valid value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'cc_number', '4111-1111-1111-1111' );
is( $handler->value, '4111111111111111' );
is( $handler->error_code, undef );

# invalid value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'cc_number', '4111-1111' );
is( $handler->value, undef );
is( $handler->error_code, 'cc_number_01' );

# noclean with a valid value
$config = {
	cc_number => {
		as			=> 'cc_number',
		required	=> 1,
		label		=> 'Card Number',
		noclean     => 1,
	}
};

$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'cc_number', '4111-1111-1111-1111' );
is( $handler->value, '4111-1111-1111-1111' );
is( $handler->error_code, undef );

