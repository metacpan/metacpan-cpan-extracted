use Test::More tests => 8;
use HTML::HTML5::Entities qw[encode_entities_numeric encode_entities];

ok($HTML::HTML5::Entities::hex, 'hex encoding by default');

$HTML::HTML5::Entities::hex = 0;
is(encode_entities('&'),               '&amp;',           'encode_entities works');
is(encode_entities('a&b'),             'a&amp;b',         'safe characters pass through');
is(encode_entities('a&b', 'a&'),       '&#97;&amp;b',     'unsafe characters can be specified');
is(encode_entities('a&b', qr/[&a-z]/), '&#97;&amp;&#98;', 'unsafe characters can be regexps');

is(encode_entities_numeric('&'), '&#38;', 'numeric encoding works');

$HTML::HTML5::Entities::hex = 1;
is(encode_entities_numeric('&'), '&#x26;', 'hex encoding works');

my $var = '&';
encode_entities($var);
is($var, '&amp;', 'in-place encoding works');
