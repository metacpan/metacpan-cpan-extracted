#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 13;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

### US state required
$config = {
	state => {
		as			=> 'state',
		required	=> 1,
		label		=> 'State',
		params		=> { country => 'US' },
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'state' );
is( $handler->value, undef );
is( $handler->error_code, 'state_00' );

# invalid value
$handler->validate( 'state', 'foobar' );
is( $handler->value, undef );
is( $handler->error_code, 'state_01' );

# valid value
$handler->validate( 'state', 'NC' );
is( $handler->value, 'NC' );
is( $handler->error_code, undef );

# valid value lowercase
$handler->validate( 'state', 'nc' );
is( $handler->value, 'NC' );
is( $handler->error_code, undef );

# valid value with trailing whitespace
$handler->validate( 'state', 'NC ' );
is( $handler->value, 'NC' );
is( $handler->error_code, undef );

# valid value with leading whitespace
$handler->validate( 'state', ' NC' );
is( $handler->value, 'NC' );
is( $handler->error_code, undef );

