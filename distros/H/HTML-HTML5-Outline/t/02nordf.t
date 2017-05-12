use Test::More tests => 2;
use HTML::HTML5::Outline 0.004 rdf => 0;

ok(!HTML::HTML5::Outline->has_rdf,
	"RDF support can be disabled.");

ok(!HTML::HTML5::Outline->can('to_rdf'), "to_rdf doesn't exist");
