use Test::More tests => 7;
use HTML::HTML5::Entities qw[
	encode_entities decode_entities _decode_entities %entity2char
];

is(decode_entities('&amp;'),            '&',   'decode_entities works');
is(decode_entities('a&amp;b'),          'a&b', 'non-entities passed though');
is(decode_entities('&#97;&amp;b'),      'a&b', 'numeric entity decoded');
is(decode_entities('&#97&amp&#98'),     'a&b', 'sloppy entities decoded');

my $var = '&amp;';
decode_entities($var);
is($var, '&', 'in-place decoding works');

$var = 'f&ampck';
_decode_entities($var, \%entity2char, 1);
is($var, 'f&ck', 'expand_prefix works');

$var = 'f&ampck';
_decode_entities($var, \%entity2char, 0);
is($var, 'f&ampck', 'expand_prefix can be disabled');
