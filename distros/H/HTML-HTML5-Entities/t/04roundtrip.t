use Test::More tests => 1;
use HTML::HTML5::Entities qw[
	encode_entities decode_entities _decode_entities %entity2char
];

my $orig = my $in = '&eacute;&amp;&euro;';
is(
	encode_entities( decode_entities($in), qr/./ ),
	$orig,
	'more complex example',
) or diag decode_entities($orig);
