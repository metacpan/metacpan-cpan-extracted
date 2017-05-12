use Test::More tests => 7;
use HTML::HTML5::Microdata::Strategy::Microdata0;

my $S = HTML::HTML5::Microdata::Strategy::Microdata0->new;

ok($S, 'HTML::HTML5::Microdata::Strategy::Microdata0 instantiated');

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
	'http://www.w3.org/1999/xhtml/microdata#http%3A%2F%2Fschema.org%2FPerson%23%3Aname',
	'schema.org',
	);

is($S->generate_uri(
		name => 'name',
		type => 'http://schema.org/Person/Employee/AcmeCorpEmployee',
		),
	'http://www.w3.org/1999/xhtml/microdata#http%3A%2F%2Fschema.org%2FPerson%2FEmployee%2FAcmeCorpEmployee%23%3Aname',
	'schema.org extension',
	);

is($S->generate_uri(
		name => 'name',
		type => 'http://xmlns.com/foaf/0.1/Person',
		),
	'http://www.w3.org/1999/xhtml/microdata#http%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2FPerson%23%3Aname',
	'slash namespace',
	);

is($S->generate_uri(
		name => 'name',
		type => 'http://example.com/vocab#Person',
		),
	'http://www.w3.org/1999/xhtml/microdata#http%3A%2F%2Fexample.com%2Fvocab%23Person%3Aname',
	'hash namespace',
	);

is($S->generate_uri(
		name => 'name',
		type => 'http://example.com/vocab/person',
		),
	'http://www.w3.org/1999/xhtml/microdata#http%3A%2F%2Fexample.com%2Fvocab%2Fperson%23%3Aname',
	'microformat profile style namespace',
	);
