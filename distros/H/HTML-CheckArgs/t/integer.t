#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 21;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

### integer required
$config = {
	number => {
		as			=> 'integer',
		required	=> 1,
		label		=> 'Number',
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'number' );
is( $handler->value, undef );
is( $handler->error_code, 'integer_00' );

# positive valid value
$handler->validate( 'number', '5' );
is( $handler->value, 5 );
is( $handler->error_code, undef );

# whitespace only
$handler->validate( 'number', '  ' );
is( $handler->value, undef );
is( $handler->error_code, 'integer_00' );

# leading whitespace
$handler->validate( 'number', '  6' );
is( $handler->value, 6 );
is( $handler->error_code, undef );


### integer not required
$config = {
	number => {
		as			=> 'integer',
		label		=> 'Number',
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'number' );
is( $handler->value, undef );
is( $handler->error_code, undef );

# valid value
$handler->validate( 'number', '5' );
is( $handler->value, 5 );
is( $handler->error_code, undef );

# negative number as string
$handler->validate( 'number', '-5' );
is( $handler->value, -5 );
is( $handler->error_code, undef );

### max and min
$config = {
	number => {
		as			=> 'integer',
		label		=> 'Number',
		params		=> { min => 0, max => 5 },
	}
};

# less than min
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'number', '-100' );
is( $handler->value, undef );
is( $handler->error_code, 'integer_02' );

# more than max
$handler->validate( 'number', '+10' );
is( $handler->value, undef );
is( $handler->error_code, 'integer_03' );

# in the middle
$handler->validate( 'number', '3' );
is( $handler->value, 3 );
is( $handler->error_code, undef );
