use lib "lib";
use HTML::HTML5::Microdata::ToRDFa;

my $html = <<HTML;

<div itemprop="x">
</div>

<p id="foo">
	<span itemprop="http://example.com/external">...</span>
</p>

<div itemscope>
</div>

<div itemtype="http://example.com/Person" itemscope itemref="foo">
	<p itemprop="sub" itemscope>...</p>
	<p itemprop="sub" itemscope itemtype="http://example.com/Place">...</p>
	<p itemprop="sub" itemscope itemid="http://example.com/home">...</p>
	<p itemprop="sub" itemscope itemtype="http://example.com/Place" itemid="http://example.com/home">...</p>
</div>

<div itemid="http://example.com/joe" itemscope>
</div>

<div itemtype="http://example.com/Person" itemid="http://example.com/joe" itemscope>
	<img itemprop="a b http://example.com/image" src="pic.jpeg">
	<img itemprop="null">
	<object data="foo.mpeg" itemprop="http://example.com/video"></object>
	<span itemprop="foo">blah</span>
	<span itemprop="foo"><b>blah</b></span>
	<a href="http://example.com/page"><span itemprop="name">Foo</span></a>
</div>

HTML

my $x = HTML::HTML5::Microdata::ToRDFa->new($html, 'http://example.com/');
print $x->get_string;