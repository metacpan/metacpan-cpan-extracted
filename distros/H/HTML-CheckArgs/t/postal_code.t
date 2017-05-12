#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 11;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

### US ZIP code required
$config = {
	zip => {
		as			=> 'postal_code',
		required	=> 1,
		label		=> 'ZIP code',
		params      => { country => 'US' },
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'zip' );
is( $handler->value, undef );
is( $handler->error_code, 'postal_code_00' );

# valid value
$handler->validate( 'zip', '28202' );
is( $handler->value, '28202' );
is( $handler->error_code, undef );

# invalid value
$handler->validate( 'zip', '28202678' );
is( $handler->value, undef );
is( $handler->error_code, 'postal_code_01' );

### Non-US postal code required
$config = {
	zip => {
		as			=> 'postal_code',
		required	=> 1,
		label		=> 'ZIP code',
		params      => { country => 'CA' },
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'zip' );
is( $handler->value, undef );
is( $handler->error_code, 'postal_code_00' );

# valid value
$handler->validate( 'zip', 'M5W 1E6' );
is( $handler->value, 'M5W 1E6' );
is( $handler->error_code, undef );

