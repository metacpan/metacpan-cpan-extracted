use Test::More tests => 7;
use HTML::HTML5::Microdata::Strategy::Heuristic;

my $S = HTML::HTML5::Microdata::Strategy::Heuristic->new;

ok($S, 'HTML::HTML5::Microdata::Strategy::Heuristic instantiated');

is($S->generate_uri(
		name => 'http://example.com/term',
		type => 'http://example.com/Class',
		),
	'http://example.com/term',
	'Property that is already a URI is passed through.',
	);

is($S->generate_uri(
		name => 'name',
		type => 'http://schema.org/Person',
		),
	'http://schema.org/name',
	'schema.org',
	);

is($S->generate_uri(
		name => 'name',
		type => 'http://schema.org/Person/Employee/AcmeCorpEmployee',
		),
	'http://schema.org/name',
	'schema.org extension',
	);

is($S->generate_uri(
		name => 'name',
		type => 'http://xmlns.com/foaf/0.1/Person',
		),
	'http://xmlns.com/foaf/0.1/name',
	'slash namespace',
	);

is($S->generate_uri(
		name => 'name',
		type => 'http://example.com/vocab#Person',
		),
	'http://example.com/vocab#name',
	'hash namespace',
	);

is($S->generate_uri(
		name => 'name',
		type => 'http://example.com/vocab/person',
		),
	'http://example.com/vocab/person#name',
	'microformat profile style namespace',
	);
