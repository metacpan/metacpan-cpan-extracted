use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert';
use Test2::V0;

my $md = "Foo\nbar\n---\nbaz\n";

is(convert($md, multi_lines_setext_headings => 'single_line'), "<p>Foo</p>\n<h2>bar</h2>\n<p>baz</p>\n", 'single_line');
is(convert($md, multi_lines_setext_headings => 'break'), "<p>Foo\nbar</p>\n<hr />\n<p>baz</p>\n", 'break');
is(convert($md, multi_lines_setext_headings => 'multi_line'), "<h2>Foo\nbar</h2>\n<p>baz</p>\n", 'multi_line');
is(convert($md, multi_lines_setext_headings => 'ignore'), "<p>Foo\nbar\n---\nbaz</p>\n", 'ignore');

done_testing;
