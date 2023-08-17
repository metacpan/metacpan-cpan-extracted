use strict;
use Test::Base;
use HTML::Selector::XPath;
use Encode qw(decode);
use Data::Dumper;


my $have_treebuilder = eval {
    require HTML::TreeBuilder::XPath;
    diag "Using HTML::TreeBuilder::XPath $HTML::TreeBuilder::XPath::VERSION";
    1
};

my $have_libxml = eval {
    require XML::LibXML;
    diag "Using XML::LibXML $XML::LibXML::VERSION";
    1
};

filters { selector => 'chomp', expected => [ 'lines', 'array' ] };
plan tests => 4 * blocks;

binmode STDOUT, ':encoding(UTF-8)'; # because our test names contain UTF-8
binmode STDERR, ':encoding(UTF-8)'; # because our test names contain UTF-8
# But it seems that Test::More or Test::Base or whoever mess with STDOUT/STDERR
# on their own.

sub normalize_node {
    my( $node ) = @_;
    $node =~ s!\s+$!!;

    # LibXML gives us minimal nodes but TreeBuilder wants expanded nodes
    $node =~ s!^<(\w+)(.*?)/>!<$1$2></$1>!;

    return $node
}

run {
    my $block = shift;
    my $input= $block->input;

    my $sel= decode( 'UTF-8', scalar $block->selector );
    my $expr;
    if ($block->selector =~ m!^/!) {
        $expr = $sel;
    } else {
        $expr = HTML::Selector::XPath->new($sel)->to_xpath;
        $expr =  $expr;
    };

    my $expected= [ map { my $s = decode( 'UTF-8', $_ ); $s =~ s!\s+$!!s; $s } @{ $block->expected } ];

    # Check with XML::LibXML, if we have it
    if( $have_libxml ) {
        my $parser = XML::LibXML->new();
        my $dom = $parser->parse_html_string( $input, { recover => 2, encoding => 'UTF-8' });

        my @nodes;
        my $ok = eval { @nodes = $dom->findnodes( $expr ); 1 };
        my $err = $@;
        SKIP: {
            if( ! ok $ok, "LibXML can parse '$expr'" ) {
                diag "Error: '$err'";
                skip "XPath parse error", 1;
            }

            my $got= [ map { normalize_node($_->toString) } @nodes ];

            is_deeply $got, $expected,
                $sel . " -> $expr (LibXML)"
                or diag Dumper [
                    'Document', $dom->toString,
                    'expected',$expected,
                    'got', $got,
                ];
        }
    } else {
        SKIP: {
            skip "XML::LibXML not loaded", 2;
        }
    }

    # Check with HTML::TreeBuilder::XPath, if we have it
    if( $have_treebuilder ) {
        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse(decode('UTF-8', $input));
        $tree->eof;

        my @nodes = ();
        my $ok = eval { @nodes = $tree->findnodes( $expr ); 1 };
        my $err = $@;
        SKIP: {
            if( ! ok $ok, "TreeBuilder can parse '$expr'" ) {
                diag "Error: '$err'";
                skip "XPath parse error", 1;
            }

            my $got= [ map { normalize_node($_->toString) } @nodes ];
            is_deeply $got, $expected,
                $sel . " -> $expr (TreeBuilder)"
                or diag Dumper $got;
        }
    } else {
        SKIP: {
            skip "HTML::TreeBuilder not loaded", 2;
        }
    }
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
<span>
<p>First stuff that is not a link</p>
<a href="no">No</a>
<div>Some description</div>
<a href="foobar">Foobar</a>
<div>Some description</div>
<a href="barred">Barred</a>
<div>Some description</div>
<a href="bar">bar</a>
</span>
--- selector
span > a:first-of-type
--- expected
<a href="no">No</a>

===
--- input
<span>
<p>First stuff that is not a link</p>
<a href="no">No</a>
<div>Some description</div>
<a href="foobar">Foobar</a>
<div>Some description</div>
<a href="barred">Barred</a>
<div>Some description</div>
<a href="bar">bar</a>
<b>More stuff that is not a link</b>
</span>
--- selector
span > a:last-of-type
--- expected
<a href="bar">bar</a>

===
--- input
<span>
<a href="no">No</a>
<div>Some description</div>
<a href="foobar">Foobar</a>
<div>Some description</div>
<a href="barred">Barred</a>
<div>Some description</div>
<a href="bar">bar</a>
</span>
--- selector
span > a:nth-of-type(3)
--- expected
<a href="barred">Barred</a>

===
--- input
<span>
<a href="no">No</a>
<div>Some description</div>
<a href="foobar">Foobar</a>
<div>Some description</div>
<a href="barred">Barred</a>
<div>Some description</div>
<a href="bar">bar</a>
</span>
--- selector
span > a:nth-of-type(n+3)
--- expected
<a href="barred">Barred</a>
<a href="bar">bar</a>

===
--- input
<span>
<a href="no">No</a>
<div>Some description</div>
<a href="foobar">Foobar</a>
<div>Some description</div>
<a href="barred">Barred</a>
<div>Some description</div>
<a href="bar">bar</a>
</span>
--- selector
span > a:nth-of-type(2n)
--- expected
<a href="foobar">Foobar</a>
<a href="bar">bar</a>

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
<span>Another <b>two level deep description</b></span>
</p>
<a href="foobar">Foobar</a>
<a href="barred">Barred</a>
<p>
<a class="foo" href="No">No (child, not sibling)</a>
<span>But some description</span>
</p>
</p>
<div>Some description that is not output</div>
--- selector
p *:contains("description")
--- expected
<b>two level deep description</b>
<span>But some description</span>

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
<span>Some more description</span>
<a class="foo" href="No">No (child, not sibling)</a>
</p>
<div>Some description that is not output</div>
--- selector
p > *:contains("description")
--- expected
<span>Some more description</span>
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
<head></head>
<body>
<div>Some description</div>
<div id="empty"></div>
<div>Another <b>two level deep description</b></div>
<div>Some more description</div>
</body>
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
</div>
</body></html>
--- selector
div em:nth-child(-n+2)
--- expected
<em>here</em>
<em>there</em>
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
div em:nth-child(-2n + 3)
--- expected
<em>here</em>
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
div em:nth-last-child(-n + 3)
--- expected
<em>everywhere</em>
<em>elsewhere</em>
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
</div>
</body></html>
--- selector
div em:nth-last-child(-2n + 3)
--- expected
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

