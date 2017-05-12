#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

### option required
$config = {
	language => {
		as			=> 'option',
		required	=> 1,
		label		=> 'Language',
		params		=> { options => [ 'en', 'es' ] },
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'language' );
is( $handler->value, undef );
is( $handler->error_code, 'option_00' );

# invalid value
$handler->validate( 'language', 'ef' ); # not an option
is( $handler->value, undef );
is( $handler->error_code, 'option_01' );

# valid value
$handler->validate( 'language', 'en' );
is( $handler->value, 'en' );
is( $handler->error_code, undef );

### option not required
$config = {
	language => {
		as			=> 'option',
		label		=> 'Language',
		params		=> { options => [ 'en', 'es' ] },
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'language' );
is( $handler->value, undef );
is( $handler->error_code, undef );

# invalid value
$handler->validate( 'language', 'ef' ); # not an option
is( $handler->value, undef );
is( $handler->error_code, 'option_01' );

# valid value
$handler->validate( 'language', 'en' );
is( $handler->value, 'en' );
is( $handler->error_code, undef );

### option parameter missing
$config = {
	language => {
		as			=> 'option',
		label		=> 'Language',
	}
};

$handler = HTML::CheckArgs->new( $config );
eval { $handler->validate( 'language', 'en' ); };
ok( $@ ? 1 : 0 );
is( $handler->value, undef );
is( $handler->error_code, undef );
