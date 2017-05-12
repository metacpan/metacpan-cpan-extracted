#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 15;

use_ok('HTML::CheckArgs');

my ( $config, $handler );

### date required
$config = {
	date => {
		as			=> 'date',
		required	=> 1,
		label		=> 'Date',
		params		=> { format => '%Y%m%d%H%M%S', regex => qr(\d{14}) },
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'date' );
is( $handler->value, undef );
is( $handler->error_code, 'date_00' );

# invalid value
$handler->validate( 'date', '2004012612345' ); # a "date_13" ;)
is( $handler->value, undef );
is( $handler->error_code, 'date_02' );

# valid value
$handler->validate( 'date', '20040126123456' );
is( $handler->value, '20040126123456' );
is( $handler->error_code, undef );

### date not required
$config = {
	date => {
		as			=> 'date',
		label		=> 'Date',
		params		=> { format => '%Y%m%d%H%M%S', regex => qr(\d{14}) },
	}
};

# no value
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'date' );
is( $handler->value, undef );
is( $handler->error_code, undef );

# valid value
$handler->validate( 'date', '20040126123456' );
is( $handler->value, '20040126123456' );
is( $handler->error_code, undef );

### regex not in config
### DateTime should enforce strict parsing of the format!
$config = {
	date => {
		as			=> 'date',
		required	=> 1,
		label		=> 'Date',
		params		=> { format => '%Y%m%d%H%M%S' },
	}
};

# invalid value that will validate
$handler = HTML::CheckArgs->new( $config );
$handler->validate( 'date', '2004012612345' ); # a "date_13" ;)
is( $handler->value, '2004012612345' );
is( $handler->error_code, undef );

# valid value ok, too
$handler->validate( 'date', '20040126123456' );
is( $handler->value, '20040126123456' );
is( $handler->error_code, undef );

