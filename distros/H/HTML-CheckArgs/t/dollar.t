#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 31;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

### dollar required
$config = {
	amount => {
		as			=> 'dollar',
		required	=> 1,
		label		=> 'Amount',
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'amount' );
is( $handler->value, undef );
is( $handler->error_code, 'dollar_00' );

# positive valid value
$handler->validate( 'amount', '5' );
is( $handler->value, '5.00' );
is( $handler->error_code, undef );

# whitespace only
$handler->validate( 'amount', '  ' );
is( $handler->value, undef );
is( $handler->error_code, 'dollar_00' );

# leading whitespace
$handler->validate( 'amount', '  6' );
is( $handler->value, '6.00' );
is( $handler->error_code, undef );

# positive valid value with single decimal
$handler->validate( 'amount', '5.9' );
is( $handler->value, '5.90' );
is( $handler->error_code, undef );

# positive valid value with double decimal
$handler->validate( 'amount', '5.93' );
is( $handler->value, '5.93' );
is( $handler->error_code, undef );

# positive valid value with triple decimal
$handler->validate( 'amount', '5.937' );
is( $handler->value, '5.93' );
is( $handler->error_code, undef );

# positive valid value with letter
$handler->validate( 'amount', '5.a8' );
is( $handler->value, undef );
is( $handler->error_code, 'dollar_01' );

# positive valid value with a dollar sign and comma
$handler->validate( 'amount', '$1,500.01' );
is( $handler->value, '1500.01' );
is( $handler->error_code, undef );

### integer not required
$config = {
	amount => {
		as			=> 'dollar',
		label		=> 'Amount',
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'amount' );
is( $handler->value, undef );
is( $handler->error_code, undef );

# valid value
$handler->validate( 'amount', '5' );
is( $handler->value, '5.00' );
is( $handler->error_code, undef );

# negative dollar as string
$handler->validate( 'amount', '-5' );
is( $handler->value, '-5.00' );
is( $handler->error_code, undef );

### max and min
$config = {
	amount => {
		as			=> 'dollar',
		label		=> 'Amount',
		params		=> { min => 0, max => 5 },
	}
};

# less than min
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'amount', '-100' );
is( $handler->value, undef );
is( $handler->error_code, 'dollar_02' );

# more than max
$handler->validate( 'amount', '+10' );
is( $handler->value, undef );
is( $handler->error_code, 'dollar_03' );

# in the middle
$handler->validate( 'amount', '3' );
is( $handler->value, '3.00' );
is( $handler->error_code, undef );
