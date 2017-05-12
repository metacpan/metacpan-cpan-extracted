use 5.010;
use strict;

use HTML::Embedded::Turtle 0.200;
use Data::Dumper;

my $het = HTML::Embedded::Turtle->new(<<'MARKUP', 'http://example.net/');
	<title property="http://purl.org/dc/terms/title">Test</title>
	<link rel=meta href="#endorsed">
	<script language=Turtle>
		@prefix foaf: <http://xmlns.com/foaf/0.1/> .
		[] a foaf:Person ; foaf:name "Joe Bloggs" .
	</script>
	<script type="text/turtle" id=endorsed>
		@prefix foaf: <http://xmlns.com/foaf/0.1/> .
		[] a foaf:Person ; foaf:name "Alice Smith" .
	</script>
	<script type="TEXT/TURTLE" id=unendorsed>
		@prefix foaf: <http://xmlns.com/foaf/0.1/> .
		[] a foaf:Person ; foaf:name "Bob Smith" .
	</script>
	<p>Hello</p>
MARKUP

my $iter = $het->union_graph->get_statements(undef, undef, undef, undef);
while (my $st = $iter->next)
{
	say $st->as_string;
}
say "############################";
say Dumper([ $het->endorsements ]);
