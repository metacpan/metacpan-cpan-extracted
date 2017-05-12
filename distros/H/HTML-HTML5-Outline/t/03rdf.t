use Test::More;

plan skip_all => 'requires RDF::Trine' 
	unless eval 'use RDF::Trine; 1';
plan tests => 2;

eval 'use HTML::HTML5::Outline 0.004 rdf => 1;';

ok(HTML::HTML5::Outline->has_rdf,
	"RDF support can be enabled.");

ok(HTML::HTML5::Outline->can('to_rdf'), 'to_rdf exists');
