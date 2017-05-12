use 5.010;
use lib "lib";

use HTML::HTML5::DOM;
use HTML::HTML5::Parser;

my $dom = HTML::HTML5::Parser->load_html(IO => \*DATA);
XML::LibXML::Augment->rebless($dom);

my $impl = HTML::HTML5::DOM->getDOMImplementation;

my $monkey = HTML::HTML5::DOMutil::Feature->new(Monkey => '1.0');
$monkey->add_sub(
	HTMLElement => 'talk',
	sub { print "screech!\n" },
);
$impl->registerFeature($monkey);

$dom->getElementsByTagName('a')->[0]->talk
	if $impl->hasFeature(Monkey => '1.0');

__DATA__

<title>Example</title>

<form action="http://www.google.com/search" method="get">
	<label>Search: <input name="q" value="hello"></label>
	<label>Mode: <input name="mode" value="world"></label>
	<input type="submit">
</form>

<a href="http://www.google.co.uk/next" rel=next>Next</a>
