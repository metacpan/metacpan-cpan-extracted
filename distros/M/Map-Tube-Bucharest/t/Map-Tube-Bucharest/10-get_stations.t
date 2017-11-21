# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use English;
use Map::Tube::Bucharest;
use Test::More tests => 3;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Bucharest->new;
eval {
	$map->get_stations('foo');
};
like($EVAL_ERROR, qr{^Map::Tube::get_stations\(\): ERROR: Invalid Line Name \[foo\]. \(status: 105\)},
	'Invalid line name.');

# Test.
my $ret_ar = $map->get_stations('Linia M1');
my @ret = map { $_->name } @{$ret_ar};
is_deeply(
	\@ret,
	[
		'Dristor 2',
		decode_utf8('Piața Muncii'),
		'Iancului',
		'Obor',
		decode_utf8('Ștefan cel Mare'),
		decode_utf8('Piața Victoriei'),
		'Gara de Nord',
		'Basarab',
		decode_utf8('Crângași'),
		'Petrache Poenaru',
		decode_utf8('Grozăvești'),
		'Eroilor',
		'Izvor',
		decode_utf8('Piața Unirii 1'),
		'Timpuri Noi',
		'Mihai Bravu',
		'Dristor 1',
		'Nicolae Grigorescu',
		'Titan',
		'Costin Georgian',
		'Republica',
		'Pantelimon',
	],
	"Get stations for line 'Linia M1'.",
);
