use utf8;

use Test::More tests => 3;
BEGIN { use_ok('HTML::HTML5::Writer') };
use XML::LibXML;

my $input = <<INPUT;
<html xmlns="http://www.w3.org/1999/xhtml"><head><title>foo</title>
<style type="text/css"><![CDATA[
p { foo: "€"; }
]]></style>
</head><body><br foo="nar" />
<!-- ffooo-->
<p quux="xyzzy" bim='"' bum="/bat/" hidden="">foo &amp; €</p><p>foo</p>
<table>
<thead>
<tr><th></th><th>
</th></tr></thead>
<tbody><tr><th></th><td>
</td></tr></tbody><tbody><tr><th></th><td>
</td></tr></tbody></table>
</body></html>
INPUT

my $parser = XML::LibXML->new;
my $dom    = $parser->parse_string($input);

my $hwriter = HTML::HTML5::Writer->new(
	markup   => 'html',
);
my $xwriter = HTML::HTML5::Writer->new(
	markup   => 'xhtml',
	polyglot => 0,
	doctype  => HTML::HTML5::Writer::DOCTYPE_XHTML1,
);

is($hwriter->document($dom), <<HTML, 'HTML output');
<!DOCTYPE html><title>foo</title>
<style type="text/css">
p { foo: "€"; }
</style>
<br foo=nar>
<!-- ffooo-->
<p bim='"' bum="/bat/" hidden quux=xyzzy>foo &amp; €<p>foo</p>
<table>
<thead>
<tr><th><th>
</thead>
<tbody><tr><th><td>
<tr><th><td>
</table>
HTML

is($xwriter->document($dom)."\n", <<XHTML, 'XHTML output');
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head><title>foo</title>
<style type="text/css"><![CDATA[
p { foo: "€"; }
]]></style>
</head><body><br foo="nar" />
<!-- ffooo-->
<p bim='"' bum="/bat/" hidden="" quux="xyzzy">foo &amp; €</p><p>foo</p>
<table>
<thead>
<tr><th></th><th>
</th></tr></thead>
<tbody><tr><th></th><td>
</td></tr></tbody><tbody><tr><th></th><td>
</td></tr></tbody></table>
</body></html>
XHTML

