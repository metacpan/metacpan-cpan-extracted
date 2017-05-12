use strict;
use Test::Base;
use HTML::Selector::XPath;
use Encode qw(decode);

eval { require HTML::TreeBuilder::XPath };
plan skip_all => "HTML::TreeBuilder::XPath is not installed." if $@;

filters { selector => 'chomp', expected => [ 'lines', 'array' ] };
plan tests => 1 * blocks;

binmode STDOUT, ':encoding(UTF-8)'; # because our test names contain UTF-8
binmode STDERR, ':encoding(UTF-8)'; # because our test names contain UTF-8
# But it seems that Test::More or Test::Base or whoever mess with STDOUT/STDERR
# on their own.

run {
    my $block = shift;
    my $tree = HTML::TreeBuilder::XPath->new;
    my $input= decode( 'UTF-8', $block->input);
    $tree->parse($input);
    $tree->eof;

    my $sel= decode( 'UTF-8', scalar $block->selector );
    my $expr;
    if ($block->selector =~ m!^/!) {
        $expr = $sel;
    } else {
        $expr = HTML::Selector::XPath->new($sel)->to_xpath
    };
    my @nodes = $tree->findnodes( $expr );
    my $expected= [ map { decode( 'UTF-8', $_ )} @{ $block->expected } ];
    my $got= [ map $_->as_XML, @nodes ];
    is_deeply $got, $expected,
        $sel . " -> $expr";
}

__END__

===
--- input
<body>
<div class="foo">foo</div>
<div class="bar">foo</div>
</body>
--- selector
div.foo
--- expected
<div class="foo">foo</div>

===
--- input
<ul>
<li><a href="foo.html">bar</a></li>
<li><a href="foo.html">baz</a></li>
</ul>
--- selector
ul li
--- expected
<li><a href="foo.html">bar</a></li>
<li><a href="foo.html">baz</a></li>

===
--- input
<ul>
<li><a href="foo.html">bar</a></li>
<li><a href="foo.html">baz</a></li>
</ul>
--- selector
ul li:first-child
--- expected
<li><a href="foo.html">bar</a></li>

===
--- input
<ul>
<li><a href="foo.html">bar</a></li>
<li><a href="foo.html">blim</a></li>
<li><a href="foo.html">baz</a></li>
</ul>
--- selector
ul li:last-child
--- expected
<li><a href="foo.html">baz</a></li>

===
--- input
<ul>
<li><a href="foo.html">bar</a></li>
<li class="bar baz"><a href="foo.html">baz</a></li>
<li class="bar"><a href="foo.html">baz</a></li>
</ul>
--- selector
li.bar
--- expected
<li class="bar baz"><a href="foo.html">baz</a></li>
<li class="bar"><a href="foo.html">baz</a></li>

===
--- input
<div>foo</div>
<div id="bar">baz</div>
--- selector
div#bar
--- expected
<div id="bar">baz</div>

===
--- input
<div>foo</div>
<div id="bar">baz</div>
<div class="baz">baz</div>
--- selector
div#bar, div.baz
--- expected
<div id="bar">baz</div>
<div class="baz">baz</div>

===
--- input
<div>foo</div>
<div lang="en">baz</div>
<div lang="en-us">baz</div>
--- selector
div:not([lang|="en"])
--- expected
<div>foo</div>

===
--- input
<div>foo</div>
<div class="foo">baz</div>
<div class="foob">baz</div>
--- selector
div:not([class~="foo"])
--- expected
<div>foo</div>
<div class="foob">baz</div>

===
--- input
<div>foo</div>
<div class="foo">baz</div>
<div class="foob">baz</div>
--- selector
div:not([class])
--- expected
<div>foo</div>

===
--- SKIP
--- input
<p>foo</p>
<div class="foo">baz</div>
--- selector
*:not(p)
--- expected
<div class="foo">baz</div>

===
--- input
<p class="pastoral blue aqua marine">foo</p>
<p class="pastoral blue">bar</p>
--- selector
p.pastoral.marine
--- expected
<p class="pastoral blue aqua marine">foo</p>

===
--- input
<p>foo</p>
<p>bar</p>
--- selector
p:nth-child(1)
--- expected
<p>foo</p>

===
--- input
<p>foo</p>
<p>bar</p>
--- selector
p:nth-child(2)
--- expected
<p>bar</p>

===
--- input
<a href="no">No</a>
<a href="foobar">Foobar</a>
<a href="barred">Barred</a>
<a href="bar">bar</a>
--- selector
a[href*="bar"]
--- expected
<a href="foobar">Foobar</a>
<a href="barred">Barred</a>
<a href="bar">bar</a>

===
--- input
<a href="no">No</a>
<a href="foobar">Foobar</a>
<a href="barred">Barred</a>
<a href="bar">bar</a>

--- selector
a:not([href*="bar"])
--- expected
<a href="no">No</a>

===
--- input
<p>
<a href="no">No</a>
<div>Some description</div>
<a href="foobar">Foobar</a>
<div>Some description</div>
<a href="barred">Barred</a>
<div>Some description</div>
<a href="bar">bar</a>
</p>
--- selector
p > a:nth-of-type(3)
--- expected
<a href="barred">Barred</a>

===
--- input
<a href="No">No (no preceding sibling)</a>
<p>A header</p>
<a href="Yes">Yes</a>
<div>Some description</div>
<a href="foobar">Foobar</a>
<a href="barred">Barred</a>
<p>
<a href="No">No (child, not sibling)</a>
</p>
--- selector
p ~ a
--- expected
<a href="Yes">Yes</a>
<a href="foobar">Foobar</a>
<a href="barred">Barred</a>

===
--- input
<a href="No">No (no preceding sibling)</a>
<p>A header</p>
<a class="foo" href="Yes">Yes</a>
<div>Some description</div>
<a href="foobar">Foobar</a>
<a href="barred">Barred</a>
<p>
<a class="foo" href="No">No (child, not sibling)</a>
</p>
--- selector
p ~ a.foo
--- expected
<a class="foo" href="Yes">Yes</a>

===
--- input
<a href="No">No (no preceding sibling)</a>
<p>A header</p>
<a class="foo" href="Yes">Yes</a>
<div>Some description</div>
<p>
<div>Another <b>two level deep description</b></div>
</p>
<a href="foobar">Foobar</a>
<a href="barred">Barred</a>
<p>
<a class="foo" href="No">No (child, not sibling)</a>
<div>But some description</p>
</p>
<div>Some description that is not output</div>
--- selector
p *:contains("description")
--- expected
<b>two level deep description</b>
<div>But some description</div>

===
--- input
<a href="No">No (no preceding sibling)</a>
<p>A header</p>
<a class="foo" href="Yes">Yes</a>
<div>Some description</div>
<div>Another <b>two level deep description</b></div>
<a href="foobar">Foobar</a>
<a href="barred">Barred</a>
<p>
<div>Some more description</div>
<a class="foo" href="No">No (child, not sibling)</a>
</p>
<div>Some description that is not output</div>
--- selector
p > *:contains("description")
--- expected
<div>Some more description</div>
===
--- input
<a href="No">No (no preceding sibling)</a>
<p>A header</p>
<a class="foo" href="Yes">Yes</a>
<div>Some description</div>
<div>Another <b>two level deep description</b></div>
<a href="foobar">Foobar</a>
<a href="barred">Barred</a>
<p>
<a class="foo" href="No">No (child, not sibling)</a>
</p>
<div>Some more description</div>
--- selector
*:contains("description")
--- expected
<div>Some description</div>
<b>two level deep description</b>
<div>Some more description</div>
===
--- input
<div>Some description</div>
<div id="empty"></div>
<div>Another <b>two level deep description</b></div>
<div>Some more description</div>
--- selector
:empty
--- expected
<head></head>
<div id="empty"></div>
===
--- input
<div><strong><em>here</em></strong></div>
<div><p><em>not here</em></p></div>
--- selector
div *:not(p) em
--- expected
<em>here</em>
===
--- input
<html><head></head><body>
<div><strong><em>here</em></strong></div>
<div><p><em>not here</em></p></div>
</body></html>
--- selector
//div/*[not(self::p)]/em
--- expected
<em>here</em>
===
--- input
<html><head></head><body>
<div>
    <em>here</em>
    <em>there</em>
</div>
<div><p><em>everywhere</em></p></div>
</body></html>
--- selector
div em:only-child
--- expected
<em>everywhere</em>
===
--- input
<html><head></head><body>
<div>
    <em>here</em>
    <em>there</em>
    <em>everywhere</em>
    <em>elsewhere</em>
    <em>nowhere</em>
</div>
</body></html>
--- selector
div em:nth-child(2n)
--- expected
<em>there</em>
<em>elsewhere</em>
===
--- input
<html><head></head><body>
<div>
    <em>here</em>
    <em>there</em>
    <em>everywhere</em>
    <em>elsewhere</em>
    <em>nowhere</em>
</div>
</body></html>
--- selector
div em:nth-child(2n+1)
--- expected
<em>here</em>
<em>everywhere</em>
<em>nowhere</em>
===
--- input
<html><head></head><body>
<div>
    <em>here</em>
    <em>there</em>
    <em>everywhere</em>
    <em>elsewhere</em>
    <em>nowhere</em>
    <em>anywhere</em>
</div>
</body></html>
--- selector
div em:nth-last-child(3n)
--- expected
<em>here</em>
<em>elsewhere</em>
===
--- input
<html><head></head><body>
<div>
    <em>anywhere</em>
    <em>here</em>
    <em>there</em>
    <em>everywhere</em>
    <em>elsewhere</em>
    <em>nowhere</em>
</div>
</body></html>
--- selector
div em:nth-last-child(2n+1)
--- expected
<em>here</em>
<em>everywhere</em>
<em>nowhere</em>
===
--- input
<body>
<div class="小飼弾">小飼弾</div>
<div class="bar">foo</div>
</body>
--- selector
div.小飼弾
--- expected
<div class="小飼弾">小飼弾</div>

