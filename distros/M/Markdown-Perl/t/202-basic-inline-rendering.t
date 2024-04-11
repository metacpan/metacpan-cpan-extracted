use strict;
use warnings;
use utf8;

use Markdown::Perl;
use Test2::V0;

sub run {
  &Markdown::Perl::convert;
}

is(run("abc"), "<p>abc</p>\n", 'line1');
is(run("abc\n"), "<p>abc</p>\n", 'line2');
is(run(" abc "), "<p>abc</p>\n", 'line3');

is(run("abc\ndef\n"), "<p>abc\ndef</p>\n", 'soft_break');
is(run("abc  \ndef\n", two_spaces_hard_line_breaks => 1), "<p>abc<br />\ndef</p>\n", 'hard_break1');
is(run("abc\ndef  \n"), "<p>abc\ndef</p>\n", 'hard_break2');
is(run("abc\\\ndef"), "<p>abc<br />\ndef</p>\n", 'hard_break3');
is(run("abc\\\\\ndef"), "<p>abc\\\ndef</p>\n", 'hard_break4');
is(run("abc\\\\\\\ndef"), "<p>abc\\<br />\ndef</p>\n", 'hard_break5');

is(run("abc `def` ghi"), "<p>abc <code>def</code> ghi</p>\n", 'code1');
is(run("abc`def`ghi"), "<p>abc<code>def</code>ghi</p>\n", 'code2');
is(run("abc``def`ghi``"), "<p>abc<code>def`ghi</code></p>\n", 'code3');
is(run("`` ` ``"), "<p><code>`</code></p>\n", 'code4');
is(run("``  ``"), "<p><code>  </code></p>\n", 'code5');

is(run("`abc`def`"), "<p><code>abc</code>def`</p>\n", 'escaped_code1');
is(run("\\`abc`def`"), "<p>`abc<code>def</code></p>\n", 'escaped_code2');
is(run("`abc\\`def`"), "<p><code>abc\\</code>def`</p>\n", 'escaped_code3');
is(run("\\\\`abc`def`"), "<p>\\<code>abc</code>def`</p>\n", 'escaped_code4');

is(run("&="), "<p>&amp;=</p>\n", 'html_escape1');
is(run("&amp;"), "<p>&amp;</p>\n", 'html_escape2');
is(run("`&amp;`"), "<p><code>&amp;amp;</code></p>\n", 'html_escape3');

is(run("&copy;"), "<p>©</p>\n", 'html_decode1');
is(run("`&copy;`"), "<p><code>&amp;copy;</code></p>\n", 'html_decode2');

is(run('<http://foo>'), "<p><a href=\"http://foo\">http://foo</a></p>\n", 'autolink1');
is(run('<http:>'), "<p><a href=\"http:\">http:</a></p>\n", 'autolink2');
is(run('<http:foo&bar>'), "<p><a href=\"http:foo&amp;bar\">http:foo&amp;bar</a></p>\n", 'autolink3');

is(run('[foo](/bar)'), "<p><a href=\"/bar\">foo</a></p>\n", 'link1');
is(run('[](/bar)'), "<p><a href=\"/bar\"></a></p>\n", 'link2');
is(run('[foo]()'), "<p><a href=\"\">foo</a></p>\n", 'link3');
is(run('[foo](/bar "title")'), "<p><a href=\"/bar\" title=\"title\">foo</a></p>\n", 'link4');
is(run('[foo](</bar/baz>)'), "<p><a href=\"/bar/baz\">foo</a></p>\n", 'link5');
is(run('[foo](</bar/baz> "title")'), "<p><a href=\"/bar/baz\" title=\"title\">foo</a></p>\n", 'link6');

is(run('*foo*'), "<p><em>foo</em></p>\n", 'em1');
is(run('_foo_'), "<p><em>foo</em></p>\n", 'em2');
is(run('**foo**'), "<p><strong>foo</strong></p>\n", 'strong1');
is(run('__foo__'), "<p><strong>foo</strong></p>\n", 'strong2');
is(run('*foo*bar*'), "<p><em>foo</em>bar*</p>\n", 'em3');
is(run('*foo_bar*baz_'), "<p><em>foo_bar</em>baz_</p>\n", 'em4');
is(run('*foo**bar**baz*'), "<p><em>foo<strong>bar</strong>baz</em></p>\n", 'emphasis1');
is(run('*_*'), "<p><em>_</em></p>\n", 'emphasis2');
is(run('*foo __bar *baz__ bam*'), "<p><em>foo <strong>bar *baz</strong> bam</em></p>\n", 'emphasis3');

is(run('foo<div>bar'), "<p>foo<div>bar</p>\n", 'html1');

done_testing;
