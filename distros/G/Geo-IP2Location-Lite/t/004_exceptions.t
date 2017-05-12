#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

plan tests => 17;

my $good_file = 'samples/IP-COUNTRY-SAMPLE.BIN';

if ( ! -f $good_file ) {
	BAIL_OUT( "no IP2Location binary data file found" );
}

use_ok( 'Geo::IP2Location::Lite' );

throws_ok(
	sub { Geo::IP2Location::Lite->open },
	qr/\Qopen() requires a database path name\E/,
	'open with no arg throws',
);

throws_ok(
	sub { Geo::IP2Location::Lite->open( 'bad_file_path' ) },
	qr/\Qerror opening bad_file_path: \E\w+/,
	'open with bad file throws',
);

throws_ok(
	sub { Geo::IP2Location::Lite->open( undef ) },
	qr/\Qrequires a database path name\E/,
	'open with no file throws',
);

isa_ok(
	my $obj = Geo::IP2Location::Lite->open( $good_file ),
	'Geo::IP2Location::Lite'
);

cmp_deeply(
	[ $obj->get_all( 'bad' ) ],
	[ 'INVALID IP ADDRESS' x 20 ],
	"lookup with no arg"
);

is( $obj->get_country_short,'INVALID IP ADDRESS',"lookup with no arg" );
is( $obj->get_country_short( 'foo' ),'INVALID IP ADDRESS',"lookup with bad IP" );
is( $obj->get_country_short( '0.0.3.4' ),'-',"lookup with missing IP" );
is( $obj->get_country_short( '255.255.255.254' ),'??',"lookup with not covered IP" );

is(
	$obj->get_latitude( '0.0.3.4' ),
	'This parameter is unavailable in selected .BIN data file. Please upgrade data file.',
	'data unsupported function'
);

note( '"private" methods' );

is(
	[ $obj->get_record( 1234,100 ) ]->[0],
	'-',
	"get_record with no arg (all)"
);

cmp_deeply(
	$obj->get_record( '' ),
	'MISSING IP ADDRESS',
	"get_record with no arg"
);

cmp_deeply(
	[ $obj->get_record( '',100 ) ],
	[ 'MISSING IP ADDRESS' x 20 ],
	"get_record with no arg (all)"
);

cmp_deeply(
	$obj->get_record( 4294967295,1 ),
	'??',
	"get_record (max IP range)",
);

is( $obj->name2ip( undef ),'',"name2ip" );
lives_ok(
	sub { $obj->name2ip( 'localhost' ) },
	"name2ip (localhost)"
);
