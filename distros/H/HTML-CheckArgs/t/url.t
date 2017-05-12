#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 13;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

### url required
$config = {
	url => {
		as			=> 'url',
		required	=> 1,
		label		=> 'URL',
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'url' );
is( $handler->value, undef );
is( $handler->error_code, 'url_00' );

# invalid value
$handler->validate( 'url', 'www.google.com' );
is( $handler->value, undef );
is( $handler->error_code, 'url_01' );

# valid value
$handler->validate( 'url', 'http://www.google.com/' );
is( $handler->value, 'http://www.google.com/' );
is( $handler->error_code, undef );

SKIP: {
	my $havenet = 1;
	my $ua = LWP::UserAgent->new;
	my $response = $ua->get( 'http://www.google.com/' );
	$havenet = 0 if $response->is_error;
	skip 'no internet connection detected', 4 unless $havenet;

### url verified
$config = {
	url => {
		as			=> 'url',
		required	=> 1,
		label		=> 'URL',
		params		=> { verify => 1 },
	}
};

# valid url
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'url', 'http://www.google.com/' );
is( $handler->value, 'http://www.google.com/' );
is( $handler->error_code, undef );

# nonexistant url
$handler->validate( 'url', 'http://www.dkjfdkjfkdjfkdjf.org/' );
is( $handler->value, undef );
is( $handler->error_code, 'url_02' );

};

### max_chars
$config = {
	url => {
		as			=> 'url',
		required	=> 1,
		label		=> 'URL',
		params		=> { max_chars => 50 },
	}
};

# over max_chars
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'url', 'http://www.google.com/thisisaverylongurlthatisoverthelengthlimit' );
is( $handler->value, undef );
is( $handler->error_code, 'url_03' );
