use Test::More;

plan skip_all => 'requires RDF::Trine' 
	unless eval 'use RDF::Trine; 1';
	
plan tests => 4;

eval 'use HTML::HTML5::Outline 0.004 rdf => 1;';
use Scalar::Util qw[blessed];
RDF::Trine->import(qw(iri blank variable literal statement));

my $xhtml = <<'XHTML';
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-gb">
	<head>
		<title>Test</title>
	</head>
	<body>
		<h1 role=":superman">Hello</h1>
		<h2>Universe</h2>
		<h3>Possibility of a Multiverse?</h3>
		<blockquote cite="http://example.com/multiverse" xml:lang="en-us">
			<h1>What's a Multiverse?</h1>
			<h2>In Layman's Terms</h2>
			<h2>In Astrophysics</h2>
		</blockquote>
		<h2>World</h2>
		<h2>Country</h2>
		<h1>Goodbye</h1>
		<h2>Cruel World</h2>
	</body>
</html>
XHTML

my $data = HTML::HTML5::Outline
	->new($xhtml, uri => 'http://example.com/')
	->to_rdf
	;

{
	my $target;
	sub pattern_target
	{
		my $t = shift;
		ok(blessed($t) && $t->isa('RDF::Trine::Model'), 'Data is an RDF::Trine::Model.');
		$target = $t;
	}
	sub pattern_ok
	{
		my $message = pop @_;
		my $iter    = $target->get_pattern(RDF::Trine::Pattern->new(@_));
		while (my $row = $iter->next)
		{
			pass $message;
			return;
		}
		fail $message;
	}
}

require RDF::Trine::Namespace;
RDF::Trine::Namespace->import(qw[RDF RDFS OWL XSD]);
my $DC   = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');
my $OL   = RDF::Trine::Namespace->new('http://ontologi.es/outline#');
my $TYPE = RDF::Trine::Namespace->new('http://purl.org/dc/dcmitype/');
my $EX   = RDF::Trine::Namespace->new('http://example.com/');

pattern_target($data);
pattern_ok(
	statement($EX->uri(), $DC->type, $TYPE->Text),
	'Document type is dcmitype:Text.'
	);
pattern_ok(
	statement($EX->uri(), $OL->part, variable('firstpart')),
	statement(variable('firstpart'), $OL->heading, variable('heading')),
	statement(variable('heading'), $OL->tag, literal('h1', undef, $XSD->NMTOKEN->uri)),
	statement(variable('firstpart'), $DC->title, literal('Hello')),
	'Main heading.'
	);
pattern_ok(
	statement(variable('bqholder'), $OL->blockquote, variable('bq')),
	statement(variable('bq'), $OL->tag, literal('blockquote', undef, $XSD->NMTOKEN->uri)),
	statement(variable('bq'), $DC->type, $TYPE->Text),
	statement(variable('bq'), $OL->uri('part-list'), variable('list')),
	statement(variable('list'), $RDF->first, variable('part')),
	statement(variable('list'), $RDF->rest, $RDF->nil),
	statement(variable('part'), $DC->type, $TYPE->Text),
	statement(variable('part'), $DC->title, literal("What's a Multiverse?")),
	'Blockquote.'
	);
