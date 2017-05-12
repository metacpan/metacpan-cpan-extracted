#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use lib "lib";
use HTML::HTML5::Microdata::Parser;
use RDF::TrineShortcuts;

my $h = <<HTML;
<html lang="">
<head>
	<title >Foo bar</title>
	<link rel="up up up FOOBLE alternate stylesheet fooble http://EXAMPLE.COM/" href="foo.css">
	<meta name="http://search.cpan.org/dist/HTML-HTML5-Microdata-Parser/#auto_config"
	  content="xhtml_time=1" />
	  <meta  http-equiv=content-language content=en-gb-oed>
	</head>

<div itemscope>
 <p>My name is <span itemprop="name">Elizabeth</span>.</p>
</div>

<div itemscope>
 <p>My name is <span itemprop="name">Daniel</span>.</p>
</div>

<div itemscope>
 <p>My name is <span itemprop="name">Neil</span>.</p>
 <p>My band is called <span itemprop="band">Four Parts Water</span>.</p>
 <p>I am <span itemprop="nationality">British</span>.</p>
 <p itemprop="http://example.net/">Foo</p>
</div>

<section xml:lang="en-us" itemref="fooble" itemscope itemid="#hedral" itemtype="http://example.org/animals#cat">
 <h1 itemprop="name">Hedral</h1>
 <p itemprop="desc">Hedral is a male american domestic
 shorthair, with a fluffy black fur with white paws and belly.</p>
 <img itemprop="img" src="hedral.jpeg" alt="" title="Hedral, age 18 months">
</section>

<p id="fooble">
  <time itemprop="some-date" datetime="2009-12">this month</time>
</p>

HTML

my $p = HTML::HTML5::Microdata::Parser->new($h, 'http://example.com/', {'auto_config'=>1});
$p->consume;

print rdf_string($p->graph, 'turtle');
