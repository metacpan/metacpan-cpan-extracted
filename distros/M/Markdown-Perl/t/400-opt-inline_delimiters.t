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

done_testing;
