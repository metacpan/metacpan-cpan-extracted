use 5.010;
use lib "lib";

use HTML::HTML5::DOM;
use HTML::HTML5::Parser;

my $dom = XML::LibXML->load_xml(IO => \*DATA);
XML::LibXML::Augment->rebless($dom);

my $impl = HTML::HTML5::DOM->getDOMImplementation;

say $dom->getElementsByTagName('p')->[0]->textContent
	if $impl->hasFeature(XMLVersion => '1.1');

say sprintf("%s: %s", $_->nodeName, $_->_p5_numericPath)
	for $dom->getElementsByTagName('*');

say sprintf("%s: %s", $_->nodeName, $_->_p5_numericPath)
        for $dom->childNodes;

__DATA__
<?xml version="1.1"?>
<!-- some comment -->
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>Greetings</title>
	</head>
	<body>
		<p>Hello, world!</p>
	</body> 
</html>
