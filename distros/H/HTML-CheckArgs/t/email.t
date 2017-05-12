#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 27;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

### email required
$config = {
	email_address => {
		as			=> 'email',
		required	=> 1,
		label		=> 'Email address',
	}
};

# no email
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'email_address' );
is( $handler->value, undef );
is( $handler->error_code, 'email_00' );

# valid email
$handler->validate( 'email_address', 'eric@folley.net' );
is( $handler->value, 'eric@folley.net' );
is( $handler->error_code, undef );

# valid email with leading whitespace
$handler->validate( 'email_address', '   eric@folley.net' );
is( $handler->value, 'eric@folley.net' );
is( $handler->error_code, undef );

# valid email with internal whitespace
$handler->validate( 'email_address', 'eric  @  folley.net' );
is( $handler->value, 'eric@folley.net' );
is( $handler->error_code, undef );

# valid but uc email
$handler->validate( 'email_address', 'ERIC@FOLLEY.NET' );
is( $handler->value, 'eric@folley.net' );
is( $handler->error_code, undef );

# invalid email
$handler->validate( 'email_address', 'eric@aol' );
is( $handler->value, undef );
is( $handler->error_code, 'email_01' );



### email not required
$config = {
	email_address => {
		as			=> 'email',
		label		=> 'Email address',
	}
};

# no email
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'email_address' );
is( $handler->value, undef );
is( $handler->error_code, undef );

#valid email
$handler->validate( 'email_address', 'eric@folley.net' );
is( $handler->value, 'eric@folley.net' );
is( $handler->error_code, undef );

#invalid email
$handler->validate( 'email_address', 'eric@aol' );
is( $handler->value, undef );
is( $handler->error_code, 'email_01' );



### email with parameters
my @banned = ( 'rnc.org' );
$config = {
	email_address => {
		as			=> 'email',
		label		=> 'Email address',
		params		=> { no_gov_addr=>1, no_admin_addr=>1, banned_domains=>\@banned },
	}
};

# system email
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'email_address', 'postmaster@democrats.org' );
is( $handler->value, undef );
is( $handler->error_code, 'email_03' );

# .gov email
$handler->validate( 'email_address', 'eric@nasa.gov' );
is( $handler->value, undef );
is( $handler->error_code, 'email_04' );

# banned domain
$handler->validate( 'email_address', 'eric@rnc.org' );
is( $handler->value, undef );
is( $handler->error_code, 'email_05' );

# valid email
$handler->validate( 'email_address', 'eric@folley.net' );
is( $handler->value, 'eric@folley.net' );
is( $handler->error_code, undef );

