use lib "lib";
use HTML::Microformats::Format::adr;
use HTML::Microformats::_context;
use HTML::HTML5::Parser;
use strict;
use Data::Dumper;
use RDF::TrineShortcuts;

my $html = <<HTML;
<div class="adr">
	<span class="locality">Foo</span>
	<span class="locality">Bar</span>
	<span class="region">Foobar</span>
	
	<div class="vcard">
		<div class="adr">
			<span class="type">intl</span>:
			<span class="fn country-name">France</span>
			<span class="geo">
				<span class="reference-frame">My crazy <span class="body">Earth</span> co-ordinates</span>
				12.34,56.78
			</span>
		</div>
	</div>
	
</div>
HTML

my $parser = HTML::HTML5::Parser->new;
my $dom    = $parser->parse_string($html);

my $ctx    = HTML::Microformats::_context->new($dom, 'http://example.net/');

my @adrs = HTML::Microformats::Format::adr->extract_all($dom, $ctx);

my $model = rdf_parse;

foreach my $a (@adrs)
{
	$a->add_to_model($model);
	print Dumper($a->data);
}

print rdf_string($model, 'rdfxml');
