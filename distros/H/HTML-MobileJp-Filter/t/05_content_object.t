use strict;
use Test::More tests => 5;

use HTML::MobileJp::Filter::Content;

my $content = HTML::MobileJp::Filter::Content->new(html => '<html><div>aaa</div></html>');
ok $content->_current eq 'html';

my $xml = $content->as_xml;
ok $content->_current eq 'xml';
isa_ok $xml, 'XML::LibXML::Document';

my ($node) = $xml->findnodes('//div');
$node->appendText("zzz");
$content->update($xml);

is $content->as_html, qq(<?xml version="1.0"?>\n<html><div>aaazzz</div></html>\n);

is "$content", $content->as_html, 'stringfy';

