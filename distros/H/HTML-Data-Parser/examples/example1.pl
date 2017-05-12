#!/usr/bin/perl

use lib "lib";
use lib "../HTML-Microformats/lib";
use HTML::Data::Parser;
use RDF::TrineShortcuts;

my $html = <<'HTML';
<body>
	<h1>This is a test</h1>
	<div class="vcard">
		<span class="fn">Joe Bloggs</span>
	</div>
	<div typeof=":TestThing" property=":testAttribute">test value</div>
	<script type="text/turtle">
		@prefix foaf: <http://xmlns.com/foaf/0.1/> .
		<#me> a foaf:Person .
	</script>
</body>
HTML

my $parser = HTML::Data::Parser->new(parse_outline=>1);
my $model  = rdf_parse();

$parser->parse_into_model('http://example.org/doc', $html, $model);

print rdf_string($model => 'RDFXML');

