use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert';
use Test2::V0;

is(convert("foo\nbar", two_spaces_hard_line_breaks => 0), "<p>foo\nbar</p>\n", 'soft_opt_off');
is(convert("foo\nbar", two_spaces_hard_line_breaks => 1), "<p>foo\nbar</p>\n", 'soft_opt_on');
is(convert("foo\\\nbar", two_spaces_hard_line_breaks => 0), "<p>foo<br />\nbar</p>\n", 'hard_with_backslash_opt_off');
is(convert("foo\\\nbar", two_spaces_hard_line_breaks => 1), "<p>foo<br />\nbar</p>\n", 'hard_with_backslash_opt_on');
is(convert("foo  \nbar", two_spaces_hard_line_breaks => 0), "<p>foo\nbar</p>\n", 'hard_with_spaces_opt_off');
is(convert("foo  \nbar", two_spaces_hard_line_breaks => 1), "<p>foo<br />\nbar</p>\n", 'hard_with_spaces_opt_on');

done_testing;
