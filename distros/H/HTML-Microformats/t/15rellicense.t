use Test::More tests => 8;
use HTML::Microformats;

my $html = <<'HTML';
<html lang=en>
	<a rel="license" href="l" title="License"><span class="value">Lic</span>ense</a>
HTML

my $document = HTML::Microformats->new_document($html, 'http://example.com/');
$document->assume_all_profiles;

my ($l) = $document->objects('RelLicense');

is($l->get_href,
	'http://example.com/l',
	'License URI correct.');

is($l->get_title,
	'License',
	'License title correct');

is($l->get_label,
	'Lic',
	'License label correct');
	
my $model = $document->model;

foreach my $uri (qw(http://creativecommons.org/ns#license
	http://www.w3.org/1999/xhtml/vocab#license
	http://purl.org/dc/terms/license))
{
	ok($model->count_statements(
			RDF::Trine::Node::Resource->new('http://example.com/'),
			RDF::Trine::Node::Resource->new($uri),
			RDF::Trine::Node::Resource->new('http://example.com/l')),
		"RDF Predicate <$uri> set");
}

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/'),
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		RDF::Trine::Node::Resource->new('http://creativecommons.org/ns#Work')),
	"cc:Work set");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/l'),
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		RDF::Trine::Node::Resource->new('http://creativecommons.org/ns#License')),
	"cc:License set");
