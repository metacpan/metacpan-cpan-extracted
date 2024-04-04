use strict;
use warnings;
use utf8;

use Markdown::Perl;
use Test2::V0;

sub run {
  &Markdown::Perl::convert;
}

is(run("> abc"), "<blockquote>\n<p>abc</p>\n</blockquote>\n", 'quote1');
is(run("> abc\n> def\n"), "<blockquote>\n<p>abc\ndef</p>\n</blockquote>\n", 'quote2');
is(run("> abc\n\ndef\n"), "<blockquote>\n<p>abc</p>\n</blockquote>\n<p>def</p>\n", 'quote3');
is(run("> abc\n> > def\n"), "<blockquote>\n<p>abc</p>\n<blockquote>\n<p>def</p>\n</blockquote>\n</blockquote>\n", 'quote4');
is(run("> abc\ndef\n"), "<blockquote>\n<p>abc\ndef</p>\n</blockquote>\n", 'quote5');
is(run("> abc\n>\ndef\n"), "<blockquote>\n<p>abc</p>\n</blockquote>\n<p>def</p>\n", 'quote6');

is(run("- abc"), "<ul>\n<li>abc</li>\n</ul>\n", 'ul1');
is(run("- abc\n- def"), "<ul>\n<li>abc</li>\n<li>def</li>\n</ul>\n", 'ul2');
is(run("- abc\n\n- def"), "<ul>\n<li><p>abc</p>\n</li>\n<li><p>def</p>\n</li>\n</ul>\n", 'ul3');
is(run("- abc\n  def\n"), "<ul>\n<li>abc\ndef</li>\n</ul>\n", 'ul4');
is(run("- abc\n\n  def\n"), "<ul>\n<li><p>abc</p>\n<p>def</p>\n</li>\n</ul>\n", 'ul5');
is(run("- abc\n* def"), "<ul>\n<li>abc</li>\n</ul>\n<ul>\n<li>def</li>\n</ul>\n", 'ul6');
is(run("- abc\n\n* def"), "<ul>\n<li>abc</li>\n</ul>\n<ul>\n<li>def</li>\n</ul>\n", 'ul7');
is(run("-   abc\n    -   def\n        -   ghi\n"), "<ul>\n<li>abc<ul>\n<li>def<ul>\n<li>ghi</li>\n</ul>\n</li>\n</ul>\n</li>\n</ul>\n", 'ul8');
is(run("-abc"), "<p>-abc</p>\n", 'no_ul1');

is(run("1. abc"), "<ol>\n<li>abc</li>\n</ol>\n", 'ol1');
is(run("2. abc"), "<ol start=\"2\">\n<li>abc</li>\n</ol>\n", 'ol2');
is(run("1. abc\n3. def"), "<ol>\n<li>abc</li>\n<li>def</li>\n</ol>\n", 'ol3');
is(run("1.abc"), "<p>1.abc</p>\n", 'no_ol1');

done_testing;
