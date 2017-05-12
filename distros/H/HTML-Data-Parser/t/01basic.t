use Test::More tests => 2;
BEGIN { use_ok('HTML::Data::Parser') };

use RDF::Trine;
use RDF::Dumper qw[Dumper];

my $html = <<'HTML';
<body>
	<div class="vcard">
		<span class="fn">Joe Bloggs</span>
	</div>
	<div typeof=":TestThing"><span property=":testAttribute">test value</span></div>
	<script type="text/turtle">
		@prefix foaf: <http://xmlns.com/foaf/0.1/> .
		<#me> a foaf:Person .
	</script>
</body>
HTML

my $parser = HTML::Data::Parser->new();
my $model  = RDF::Trine::Model->temporary_model;
$parser->parse_into_model('http://example.org/doc', $html, $model);

ok(
	$model->count_statements(
		undef,
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/xhtml/vocab#testAttribute'),
		RDF::Trine::Node::Literal->new('test value'),
	),
	'RDFa parsed.',
) or note Dumper($model);