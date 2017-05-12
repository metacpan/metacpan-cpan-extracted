
use strict;
use warnings;

use HTML::Microdata;

use Test::More;
use Test::Base;
use Test::Differences;
use JSON;

plan tests => 1 * blocks;

filters {
	input    => [qw/chomp/],
	expected => [qw/chomp/],
	base     => [qw/chomp/],
};

run {
	my ($block) = @_;
	my $microdata = HTML::Microdata->extract($block->input,
		base => $block->base || undef
	);
	my $expected  = decode_json $block->expected;
	eq_or_diff decode_json($microdata->as_json), $expected, $block->name;
};

__END__

=== basic
--- input
<html>
<body>
<div itemscope>
	<span itemprop="foo bar">bar</span>
</div>
</body>
</html>
--- expected
{
	"items" : [
		{
			"properties" : {
				"foo" : [ "bar" ],
				"bar" : [ "bar" ]
			}
		}
	]
}

=== itemid
--- input
<html>
<body>
<div itemscope itemid="urn:test:foo">
	<span itemprop="foo">bar</span>
</div>
</body>
</html>
--- expected
{
	"items" : [
		{
			"id" : "urn:test:foo",
			"properties" : {
				"foo" : [ "bar" ]
			}
		}
	]
}

=== order
--- input
<html>
<body>
<div itemscope itemid="urn:test:foo">
	<span itemprop="foo">bar</span>
</div>
<div itemscope itemid="urn:test:foo">
	<span itemprop="foo">baz</span>
</div>
</body>
</html>
--- expected
{
	"items" : [
		{
			"id" : "urn:test:foo",
			"properties" : {
				"foo" : [ "bar" ]
			}
		},
		{
			"id" : "urn:test:foo",
			"properties" : {
				"foo" : [ "baz" ]
			}
		}
	]
}


=== order
--- input
<html>
<body>
<div itemscope itemid="urn:test:foo" id="zzz">
	<span itemprop="foo">bar</span>
</div>
<div itemscope itemid="urn:test:foo" id="aaa">
	<span itemprop="foo">baz</span>
</div>
</body>
</html>
--- expected
{
	"items" : [
		{
			"id" : "urn:test:foo",
			"properties" : {
				"foo" : [ "bar" ]
			}
		},
		{
			"id" : "urn:test:foo",
			"properties" : {
				"foo" : [ "baz" ]
			}
		}
	]
}


=== itemref
--- input
<html>
<body>

<div itemscope id="amanda" itemref="a b"></div>

<p id="a">Name: <span itemprop="name">Amanda</span></p>

<div id="b" itemprop="band" itemscope itemref="c"></div>

<div id="c">
	<p>Band: <span itemprop="name">Jazz Band</span></p>
	<p>Size: <span itemprop="size">12</span> players</p>
</div>

</body>
</html>
--- expected
{
	"items" : [
		{
			"properties" : {
				"name" : [ "Amanda" ],
				"band" : [
					{
						"properties" : {
							"name" : [ "Jazz Band" ],
							"size" : [ "12" ]
						}
					}
				]
			}
		}
	]
}


=== typed
--- input
<html>
<body>


<section itemscope itemtype="http://example.org/animals#cat">
	<h1 itemprop="name">Hedral</h1>
	<p itemprop="desc">description</p>
	<img itemprop="img" src="hedral.jpeg" alt="" title="Hedral, age 18 months">
</section>

</body>
</html>
--- expected
{
	"items" : [
		{
			"type" : "http://example.org/animals#cat",
			"properties" : {
				"name" : [ "Hedral" ],
				"desc" : [ "description" ],
				"img"  : [ "hedral.jpeg" ]
			}
		}
	]
}

=== url
--- base
http://example.com/
--- input
<html>
<body>


<section itemscope>
	<a itemprop="empty" />
	<a itemprop="a" href="foo.html"/>
	<area itemprop="area" href="foo.html"/>
	<audio itemprop="audio" src="foo.ogg"/>
	<embed itemprop="embed" src="foo.dat"/>
	<iframe itemprop="iframe" src="foo.html"/>
	<img itemprop="img" src="foo.jpg" alt=""/>
	<link itemprop="link" href="foo.html"/>
	<object itemprop="object" data="foo.jpg"/>
	<source itemprop="source" src="foo"/>
	<track itemprop="track" src="foo"/>
	<video itemprop="video" src="foo.ogm"/>
</section>

</body>
</html>
--- expected
{
	"items" : [
		{
			"properties" : {
				"empty"  : [ "" ],
				"a"  : [ "http://example.com/foo.html" ],
				"area"  : [ "http://example.com/foo.html" ],
				"audio"  : [ "http://example.com/foo.ogg" ],
				"embed"  : [ "http://example.com/foo.dat" ],
				"iframe"  : [ "http://example.com/foo.html" ],
				"img"  : [ "http://example.com/foo.jpg" ],
				"link"  : [ "http://example.com/foo.html" ],
				"object"  : [ "http://example.com/foo.jpg" ],
				"source"  : [ "http://example.com/foo" ],
				"track"  : [ "http://example.com/foo" ],
				"video"  : [ "http://example.com/foo.ogm" ]
			}
		}
	]
}

=== infinate loop
--- SKIP
--- input
<html>
<body>

<div id="foo" itemscope itemref="bar">
	<meta itemprop="foo" content="bar"/>
</div>

<div id="bar" itemprop="unko" itemscope itemref="foo">
	<meta itemprop="baz" content="bar"/>
</div>

</body>
</html>
--- expected
{
	"items" : [
		{
			"properties" : {
				"foo" : [ "bar" ]
			}
		}
	]
}

=== error
--- input
<html>
<meta itemprop="name" content="foobar"/>
<body>
</body>
</html>
--- expected
{
	"items" : []
}
