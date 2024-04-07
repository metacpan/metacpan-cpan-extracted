use strict;
use warnings;
use utf8;

use Markdown::Perl;
use Test2::V0;

sub run {
  &Markdown::Perl::convert;
}

todo 'New lines are forbidden in link dest' => sub {
  # This fails because the inner brackets are parsed as HTML and the code does
  # not check for new-line inside non-text nodes, inside the span delimited by
  # the outer brackets (like it does if the link destination is not in
  # brackets).
  is(run("[link](<dest <foo\nbar>>)"), "<p>[link](&lt;dest <foo\nbar>&gt;)</p>\n", 'newline in bracket in bracket in link');
};

todo 'Multi-line constructs mis-categorized as lazy paragraph continuation' => sub {
  is(run("> foo\n[ref]:\n/url\n"), "<blockquote>\n<p>foo\n</p></blockquote>\n<pre><code>bar\n</code></pre>\n", 'link reference definition is not lazy');
  # Note that this fails only when the fenced_code_blocks_must_be_closed option
  # is set to true (our default, but not the cmark default).
  is(run("> foo\n```\nbar\n```"), "<blockquote>\n<p>foo</p>\n</blockquote>\n<pre><code>bar\n</code></pre>\n", 'fenced code is not lazy');  
};

done_testing;
