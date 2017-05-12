# these tests are taken from HTML::ResolveLink, written by miyagawa
use strict;
use Test::More tests => 3;
use HTML::RewriteAttributes::Links;

my $base = "http://www.example.com/base/";
my $resolver = "HTML::RewriteAttributes::Links";

my $html = $resolver->rewrite(<<'HTML', $base);
<a href="/foo">foo</a><img src="/bar.gif" alt="foo &amp; bar" /> foobar
<a href="mailto:foobar@example.com">hey &amp;</a>
<a href="foo.html" onclick="foobar()">bar</a><br />
<a href="http://www.example.net/">bar</a>
<!-- hello -->
HTML

is $html, <<'HTML';
<a href="http://www.example.com/foo">foo</a><img src="http://www.example.com/bar.gif" alt="foo &amp; bar" /> foobar
<a href="mailto:foobar@example.com">hey &amp;</a>
<a href="http://www.example.com/base/foo.html" onclick="foobar()">bar</a><br />
<a href="http://www.example.net/">bar</a>
<!-- hello -->
HTML

$html = $resolver->rewrite(<<'HTML', $base);
<base href="http://www.google.com/">
<a href="baz">foo</a>
<base href="http://www.example.com/">
<a href="baz">foo</a>
HTML

is $html, <<'HTML', '<base>';
<base href="http://www.google.com/">
<a href="http://www.google.com/baz">foo</a>
<base href="http://www.example.com/">
<a href="http://www.example.com/baz">foo</a>
HTML
    ;

$html = $resolver->rewrite(<<'HTML', $base);
<a href="baz">&amp;</a>
&quot;foo&quot;
HTML

is $html, <<'HTML', 'HTML entities';
<a href="http://www.example.com/base/baz">&amp;</a>
&quot;foo&quot;
HTML
    ;
