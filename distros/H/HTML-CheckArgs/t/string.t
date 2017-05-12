#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 17;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

### required
$config = {
	username => {
		as			=> 'string',
		required	=> 1,
		label		=> 'Username',
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'username' );
is( $handler->value, undef );
is( $handler->error_code, 'string_00' );

# valid value
$handler->validate( 'username', 'eric' );
is( $handler->value, 'eric' );
is( $handler->error_code, undef );


### not required
$config = {
	username => {
		as			=> 'string',
		label		=> 'Username',
	}
};

#no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'username' );
is( $handler->value, undef );
is( $handler->error_code, undef );

# valid value
$handler->validate( 'username', 'eric' );
is( $handler->value, 'eric' );
is( $handler->error_code, undef );


### truncate_with_ellipses
$config = {
	title => {
		as			=> 'string',
		label		=> 'Title',
		params		=> {truncate_with_ellipses => 10 },
	}
};

$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'title', 'this and that' );
is( $handler->value, 'this an...' );
is( $handler->error_code, undef );


### truncate
$config = {
	title => {
		as			=> 'string',
		label		=> 'Title',
		params		=> {truncate => 10 },
	}
};

$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'title', 'this and that' );
is( $handler->value, 'this and t' );
is( $handler->error_code, undef );


### regex
$config = {
	title => {
		as			=> 'string',
		label		=> 'Title',
		params		=> { regex => qr{the} },
	}
};

# no match
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'title', 'this and that' );
is( $handler->value, undef );
is( $handler->error_code, 'string_01' );

# match
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'title', 'this and the other thing' );
is( $handler->value, 'this and the other thing' );
is( $handler->error_code, undef );

