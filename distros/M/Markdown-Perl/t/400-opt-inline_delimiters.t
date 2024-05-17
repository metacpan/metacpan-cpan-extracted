use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert';
use Test2::V0;

is(convert("~test~"), "<p><s>test</s></p>\n", 'default_tilde');
is(convert("~test~", inline_delimiters => {}), "<p>~test~</p>\n", 'no_tilde_hash');
is(convert("~test~", inline_delimiters => ""), "<p>~test~</p>\n", 'no_tilde_string');
is(convert("⚛test⚛", inline_delimiters => {'⚛' => 'atomic'}), "<p><atomic>test</atomic></p>\n", 'custom_delimiter_hash');
is(convert("⚛test⚛", inline_delimiters => "⚛=atomic"), "<p><atomic>test</atomic></p>\n", 'custom_delimiter_string');
is(convert("~~test~~"), "<p><del>test</del></p>\n", 'default_double_tilde');

is(convert("**test**", inline_delimiters => '*=em'), "<p><em><em>test</em></em></p>\n", 'non_repeated_delimiter');

like (dies { convert('foo', inline_delimiters => '***=em') }, qr/keys must/, 'invalid key');
like (dies { convert('foo', inline_delimiters => '*_=em') }, qr/keys must/, 'invalid key2');
like (dies { convert('foo', inline_delimiters => '*=1em') }, qr/values must/, 'invalid value');

is(convert("~test~", inline_delimiters=>'~=.foo'), "<p><span class=\"foo\">test</span></p>\n", 'insert span');

done_testing;
