use strict;
use Test::More tests => 36;
use HTML::TagCloud::Extended::TagColors;

my $colors = HTML::TagCloud::Extended::TagColors->new;

$colors->set( earliest => '#333333' );

is( $colors->{earliest}{link},    '333333' );
is( $colors->{earliest}{hover},   '333333' );
is( $colors->{earliest}{visited}, '333333' );
is( $colors->{earliest}{active},  '333333' );

$colors->set( earlier => '#666' );

is( $colors->{earlier}{link},    '666' );
is( $colors->{earlier}{hover},   '666' );
is( $colors->{earlier}{visited}, '666' );
is( $colors->{earlier}{active},  '666' );

eval{ $colors->set( later => 'zzzzzz' ); };

like( $@, qr/Wrong color-code format/ );

eval{ $colors->set( lateest => '#666666' ); };

like( $@, qr/Choose type from/ );

$colors->set( later => '#CCCCCC', latest => '#FFFFFF' );

is( $colors->{later}{link},     'CCCCCC' );
is( $colors->{later}{hover},    'CCCCCC' );
is( $colors->{later}{visited},  'CCCCCC' );
is( $colors->{later}{active},   'CCCCCC' );
is( $colors->{latest}{link},    'FFFFFF' );
is( $colors->{latest}{hover},   'FFFFFF' );
is( $colors->{latest}{visited}, 'FFFFFF' );
is( $colors->{latest}{active},  'FFFFFF' );

$colors->set( earliest => {
	link    => '#000000'
} );

is( $colors->{earliest}{link},    '000000' );
is( $colors->{earliest}{hover},   '333333' );
is( $colors->{earliest}{visited}, '333333' );
is( $colors->{earliest}{active},  '333333' );

$colors->set( earlier => {
	link    => '000000',
	hover   => '333333',
	visited => '666666',
	active  => 'CCCCCC',
} );


is( $colors->{earlier}{link},    '000000' );
is( $colors->{earlier}{hover},   '333333' );
is( $colors->{earlier}{visited}, '666666' );
is( $colors->{earlier}{active},  'CCCCCC' );

$colors->set(
	later => {
		link    => '000000',
		hover   => '333333',
		visited => '666666',
		active  => 'CCCCCC',
	},
	latest => {
		link    => '000000',
		hover   => '333333',
		visited => '666666',
		active  => 'CCCCCC',
	}
);
is( $colors->{later}{link},     '000000' );
is( $colors->{later}{hover},    '333333' );
is( $colors->{later}{visited},  '666666' );
is( $colors->{later}{active},   'CCCCCC' );
is( $colors->{latest}{link},    '000000' );
is( $colors->{latest}{hover},   '333333' );
is( $colors->{latest}{visited}, '666666' );
is( $colors->{latest}{active},  'CCCCCC' );

eval{ $colors->set( earliest => { hovar => '#333333' } ) };

like( $@, qr/Choose attribute from/ );

eval{ $colors->set( earlier => { hover => 'pppppp' } ) };

like( $@, qr/Wrong color-code format/ );
