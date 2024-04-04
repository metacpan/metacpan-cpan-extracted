use strict;
use warnings;
use utf8;

use Markdown::Perl;
use Test2::V0;

sub run {
  &Markdown::Perl::convert;
}

is(run('***'), "<hr />\n", 'break1');
is(run(' -  - -'), "<hr />\n", 'break2');
is(run('   ___        __     '), "<hr />\n", 'break3');

is(run('# test'), "<h1>test</h1>\n", 'atx_heading1');
is(run('#'), "<h1></h1>\n", 'atx_heading2');
is(run('## '), "<h2></h2>\n", 'atx_heading3');
is(run('#### ###'), "<h4></h4>\n", 'atx_heading4');
is(run('## other   '), "<h2>other</h2>\n", 'atx_heading5');

is(run("abc\n===\n"), "<h1>abc</h1>\n", 'setext_heading1');
is(run("abc\ndef\n===\n"), "<h1>abc\ndef</h1>\n", 'setext_heading2');
is(run("abc\n---\n"), "<h2>abc</h2>\n", 'setext_heading3');
is(run("   abc\n===\n"), "<h1>abc</h1>\n", 'setext_heading4');
is(run("abc\n   =\n"), "<h1>abc</h1>\n", 'setext_heading5');

is(run('    test'), "<pre><code>test</code></pre>\n", 'indented_code1');
is(run("    test\n      next\n"), "<pre><code>test\n  next\n</code></pre>\n", 'indented_code2');
is(run("\t  test\n\t  next\n"), "<pre><code>  test\n  next\n</code></pre>\n", 'indented_code3');

is(run("```\ntest\n```"), "<pre><code>test\n</code></pre>\n", 'fenced_code1');
is(run("  ```\ntest\n   other\n```"), "<pre><code>test\n other\n</code></pre>\n", 'fenced_code2');
is(run("~~~~\ntest\n~~~~"), "<pre><code>test\n</code></pre>\n", 'fenced_code3');
is(run("~~~~\ntest\n~~~\n~~~~"), "<pre><code>test\n~~~\n</code></pre>\n", 'fenced_code4');
is(run("```abc\ntest\n```"), "<pre><code class=\"language-abc\">test\n</code></pre>\n", 'fenced_code5');
is(run("```abc def\ntest\n```"), "<pre><code class=\"language-abc\">test\n</code></pre>\n", 'fenced_code6');

is(run("abc"), "<p>abc</p>\n", 'paragraph1');
is(run("abc\ndef"), "<p>abc\ndef</p>\n", 'paragraph2');
is(run("abc\n\ndef"), "<p>abc</p>\n<p>def</p>\n", 'paragraph3');
is(run("foo\r\nbar"), "<p>foo\nbar</p>\n", 'paragraph4');

is(run("<pre>\nabc\n</pre>\n"), "<pre>\nabc\n</pre>\n", 'html1');
is(run("<pre>\nabc\n"), "<pre>\nabc\n", 'html2');
is(run("<h1>\nabc\n"), "<h1>\nabc\n", 'html3');
is(run("<h1>\nabc\n\ndef"), "<h1>\nabc\n<p>def</p>\n", 'html4');
is(run("<SomeTag value = 'abc'>\n*abc*\n\ndef"), "<SomeTag value = 'abc'>\n*abc*\n<p>def</p>\n", 'html5');

done_testing;
