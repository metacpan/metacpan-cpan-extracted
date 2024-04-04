use strict;
use warnings;
use utf8;

use Markdown::Perl::HTML ':all';
use Test2::V0;

is(decode_entities('&copy;'), '©', 'html_entity_name1');
is(decode_entities('&OpenCurlyDoubleQuote;'), '“', 'html_entity_name2');
is(decode_entities('&copy'), '&copy', 'not_html_entity_name1');
is(decode_entities('copy;'), 'copy;', 'not_html_entity_name2');
is(decode_entities('&unknownEntity;'), '&unknownEntity;', 'not_html_entity_name3');

is(decode_entities('&#65;'), 'A', 'html_numeric_entity1');
is(decode_entities('&#0;'), "\x{fffd}", 'html_numeric_entity2');
is(decode_entities('&#;'), "&#;", 'no_html_numeric_entity1');
is(decode_entities('&#12345678;'), "&#12345678;", 'no_html_numeric_entity1');

is(decode_entities('&#X41;'), 'A', 'html_hex_entity1');
is(decode_entities('&#x41;'), 'A', 'html_hex_entity2');
is(decode_entities('&#;'), "&#;", 'no_html_hex_entity1');
is(decode_entities('&#X1234567;'), "&#X1234567;", 'no_html_hex_entity2');

{
  my $html = '<test>';
  remove_disallowed_tags($html, [qw(foo bar)]);
  is($html, '<test>', 'remove_disallowed_tags1');
  remove_disallowed_tags($html, [qw(foo bar test)]);
  is($html, '&lt;test>', 'remove_disallowed_tags2');
}
done_testing;
