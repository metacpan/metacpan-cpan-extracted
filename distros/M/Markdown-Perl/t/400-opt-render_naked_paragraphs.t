use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert';
use Test2::V0;

is(convert("foo\nbar", render_naked_paragraphs => 0), "<p>foo\nbar</p>\n", 'normal');
is(convert("foo\nbar", render_naked_paragraphs => 1), "foo\nbar\n", 'naked');
is(convert("foo\n\nbar", render_naked_paragraphs => 1), "foo\nbar\n", 'two_naked_paragraphs');
is(convert("- foo\n\n- bar", render_naked_paragraphs => 1), "<ul>\n<li>foo\n</li>\n<li>bar\n</li>\n</ul>\n", 'naked_loose_list');

done_testing;
