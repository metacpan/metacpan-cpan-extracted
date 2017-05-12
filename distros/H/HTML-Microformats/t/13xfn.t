use Test::More tests => 6;
use HTML::Microformats;

my $html = <<'HTML';
<html lang=en>
	<head profile="http://xen.adactio.com/">

		<div class="vcard">
			<span class="fn">Alice</span>
		</div>

		<a href="mailto:bob@example.com" rel="met friend">Bob</a>

		<span class="vcard"><a class="url fn" href="http://carol.example.com/" rel="met nemesis">Carol</a>

HTML

my $document = HTML::Microformats->new_document($html, 'http://alice.example.com/');
$document->assume_all_profiles;
my $model = $document->model;

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://alice.example.com/'),
		RDF::Trine::Node::Resource->new('http://vocab.sindice.com/xfn#met-hyperlink'),
		RDF::Trine::Node::Resource->new('mailto:bob@example.com'),
		),
	"XFN vocab *-hyperlink works."
	);

my $iter = $model->get_statements(
	undef,
	RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/page'),
	RDF::Trine::Node::Resource->new('http://carol.example.com/'),
	);
my $st = $iter->next;
my $carol = $st->subject;

ok($model->count_statements(
		undef,
		RDF::Trine::Node::Resource->new('http://vocab.sindice.com/xfn#met'),
		$carol,
		),
	"Alice met Carol."
	);

ok($model->count_statements(
		$carol,
		RDF::Trine::Node::Resource->new('http://vocab.sindice.com/xfn#met'),
		undef,
		),
	"Carol met Alice."
	);

ok($model->count_statements(
		undef,
		RDF::Trine::Node::Resource->new('http://buzzword.org.uk/rdf/xen#nemesis'),
		$carol,
		),
	"XEN profile detected."
	);

ok($model->count_statements(
		undef,
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/knows'),
		$carol,
		),
	"Infer foaf:knowses."
	);

ok($model->count_statements(
		undef,
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/mbox'),
		RDF::Trine::Node::Resource->new('mailto:bob@example.com'),
		),
	"mailto: links treated as mbox rather than page."
	);

#use RDF::TrineShortcuts;
#$RDF::TrineShortcuts::Namespaces->{'vx'}    = 'http://buzzword.org.uk/rdf/vcardx#';
#$RDF::TrineShortcuts::Namespaces->{'hcard'} = 'http://purl.org/uF/hCard/terms/';
#$RDF::TrineShortcuts::Namespaces->{'xfn'}   = 'http://vocab.sindice.com/xfn#';
#$RDF::TrineShortcuts::Namespaces->{'xen'}   = 'http://buzzword.org.uk/rdf/xen#';
#diag rdf_string($model => 'rdfxml');
