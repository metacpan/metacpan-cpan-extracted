use strict;
use warnings;
use utf8;

use Markdown::Perl;
use Test2::V0;

sub run {
  &Markdown::Perl::convert;
}

is(run("> ```\n> abc\n> def\n> ```"), "<blockquote>\n<pre><code>abc\ndef\n</code></pre>\n</blockquote>\n", 'fenced_code_in_quotes');
is(run(">     abc\n>     def\n"), "<blockquote>\n<pre><code>abc\ndef\n</code></pre>\n</blockquote>\n", 'indented_code_in_quotes');
is(run(">    abc"), "<blockquote>\n<p>abc</p>\n</blockquote>\n", 'not_indented_code_in_quotes');
is(run(">\t\tabc\n"), "<blockquote>\n<pre><code>  abc\n</code></pre>\n</blockquote>\n", 'indented_code_in_quotes_tabs');

is(run("> abc\n> - def\n> - ghi\n"), "<blockquote>\n<p>abc</p>\n<ul>\n<li>def</li>\n<li>ghi</li>\n</ul>\n</blockquote>\n", 'list_in_quotes');

is(run("> abc\n===\n"), "<blockquote>\n<p>abc\n===</p>\n</blockquote>\n", 'no_lazy_setext_heading');
is(run("> abc\n---\n"), "<blockquote>\n<p>abc</p>\n</blockquote>\n<hr />\n", 'no_lazy_thematic_break');

is(run("> <pre>\n> abc\n\nfoo"), "<blockquote>\n<pre>\nabc\n</blockquote>\n<p>foo</p>\n", 'html_in_block');

is(run("-     abc"), "<ul>\n<li><pre><code>abc</code></pre>\n</li>\n</ul>\n", 'indented_code_in_list');
is(run("-    abc"), "<ul>\n<li>abc</li>\n</ul>\n", 'not_indented_code_in_list');

is(run("[foo]\n\n> [foo]:\n> /url\n"), "<p><a href=\"/url\">foo</a></p>\n<blockquote>\n</blockquote>\n", 'multi-line link reference definition in container block');

done_testing;
