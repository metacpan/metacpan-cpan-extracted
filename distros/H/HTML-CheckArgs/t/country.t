#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 15;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

$config = {
	country => {
		as			=> 'country',
		required	=> 1,
		label		=> 'Country',
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'country' );
is( $handler->value, undef );
is( $handler->error_code, 'country_00' );

# invalid value
$handler->validate( 'country', 'foobar' );
is( $handler->value, undef );
is( $handler->error_code, 'country_01' );

# valid value, two letter code
$handler->validate( 'country', 'US' );
is( $handler->value, 'US' );
is( $handler->error_code, undef );

# valid value, name
$handler->validate( 'country', 'Argentina' );
is( $handler->value, 'AR' );
is( $handler->error_code, undef );

# valid value with trailing whitespace
$handler->validate( 'country', 'US ' );
is( $handler->value, 'US' );
is( $handler->error_code, undef );

# valid value with leading whitespace
$handler->validate( 'country', ' US' );
is( $handler->value, 'US' );
is( $handler->error_code, undef );

# only whitespace
$handler->validate( 'country', '  ' );
is( $handler->value, undef );
is( $handler->error_code, 'country_00' );

