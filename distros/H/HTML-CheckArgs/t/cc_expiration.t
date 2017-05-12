#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 12;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

$config = {
	cc_expires => {
		as			=> 'cc_expiration',
		required	=> 1,
		label		=> 'Expiration Date',
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'cc_expires' );
is( $handler->value, undef );
is( $handler->error_code, 'cc_expiration_00' );

# valid value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'cc_expires', '201008' );
is( $handler->value, '201008' );
is( $handler->error_code, undef );

# invalid value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'cc_expires', '2010' );
is( $handler->value, undef );
is( $handler->error_code, 'cc_expiration_01' );

# date in past
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'cc_expires', '200312' );
is( $handler->value, undef );
is( $handler->error_code, 'cc_expiration_02' );

# bad parameter with a valid value
$config = {
	cc_expires => {
		as       => 'cc_expiration',
		required => 1,
		label    => 'Expiration Date',
		noclean  => 1,
	}
};

$handler = HTML::CheckArgs->new( $config );
eval { $handler->validate( 'cc_expires', '201008' ); };
ok( $@ ? 1 : 0 );
is( $handler->value, undef );
is( $handler->error_code, undef );

