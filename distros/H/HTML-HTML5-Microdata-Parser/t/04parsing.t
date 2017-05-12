use Test::More tests => 4;
use Test::RDF;

use HTML::HTML5::Microdata::Parser;
use RDF::Trine qw[iri literal variable statement blank];
use RDF::Trine::Namespace qw[rdf rdfs xsd owl];
my $s = RDF::Trine::Namespace->new('http://schema.org/');

my $p = HTML::HTML5::Microdata::Parser->new(<<'MARKUP', 'http://example.com/');
<div itemscope itemtype="http://schema.org/Person">
	<h1 itemprop="name">Alice</h1>
</div>
<div itemscope itemtype="http://schema.org/Person" lang="en-AU">
	<h1 itemprop="name">Bob</h1>
</div>
<div itemscope itemtype="http://schema.org/Person" itemid="#carol">
	<h1 itemprop="name">Carol</h1>
</div>
MARKUP

pattern_target($p->graph);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Alice')),
	);

pattern_ok(
	statement(variable('x'), $rdf->type, $s->Person),
	statement(variable('x'), $s->name, literal('Bob', 'en-AU')),
	);

pattern_ok(
	statement(iri('http://example.com/#carol'), $rdf->type, $s->Person),
	statement(iri('http://example.com/#carol'), $s->name, literal('Carol')),
	);
