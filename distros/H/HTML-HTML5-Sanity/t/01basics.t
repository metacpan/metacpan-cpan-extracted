use Test::More tests => 3;
BEGIN { use_ok('HTML::HTML5::Sanity') };

use XML::LibXML::Debugging;

my $doc  = XML::LibXML::Document->new;
my $root = $doc->createElementNS('http://www.w3.org/1999/xhtml', 'html');
$doc->setDocumentElement($root);
$root->setAttribute('xml:lang', 'en-gb-oed');
$root->setAttribute('lang', 'en-tobyinkster');

my $fixed = fix_document($doc);

ok(
	!$fixed->documentElement->hasAttributeNS(undef, 'lang'),
	"Invalid language attribute removed.",
	);

is(
	lc $fixed->toClarkML,
	lc '<{http://www.w3.org/1999/xhtml}html {http://www.w3.org/XML/1998/namespace}lang="en-gb-oed" {http://www.w3.org/2000/xmlns/}XMLNS="http://www.w3.org/1999/xhtml"/>',
	"Things seem to be working.");