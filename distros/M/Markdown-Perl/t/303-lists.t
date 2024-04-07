use strict;
use warnings;
use utf8;

use Markdown::Perl;
use Test2::V0;

sub run {
  &Markdown::Perl::convert;
}

is(run("* a\n* b\n* c\n\n\nfoo"), "<ul>\n<li>a</li>\n<li>b</li>\n<li>c</li>\n</ul>\n<p>foo</p>\n", 'list is tight');
is(run("1.\tfoo\n\n\tbar"), "<ol>\n<li><p>foo</p>\n<p>bar</p>\n</li>\n</ol>\n", 'indent_with_tabs_after_marker');
is(run(">1.\tfoo\n>\n>    bar"), "<blockquote>\n<ol>\n<li><p>foo</p>\n<p>bar</p>\n</li>\n</ol>\n</blockquote>\n", 'indent_with_tabs_after_marker_inside_block');

done_testing;
