	use HTML::Microformats;
	use LWP::Simple qw[get];
	use RDF::Query;
	
	my $page  = 'http://twitter.com/t' || 'http://tantek.com/';
	my $graph = HTML::Microformats
	               ->new_document(get($page), $page)
	               ->assume_all_profiles
	               ->parse_microformats
	               ->model;
	
	my $query = RDF::Query->new(<<SPARQL);
	PREFIX foaf: <http://xmlns.com/foaf/0.1/>
	SELECT DISTINCT ?friendname ?friendpage
	WHERE {
		<$page> ?p ?friendpage .
		?person foaf:name ?friendname ;
			foaf:page ?friendpage .
		FILTER (
			isURI(?friendpage)
			&& isLiteral(?friendname) 
			&& regex(str(?p), "^http://vocab.sindice.com/xfn#(.+)-hyperlink")
		)
	}
SPARQL
	
	my $results = $query->execute($graph);
	while (my $result = $results->next)
	{
		printf("%s <%s>\n",
			$result->{friendname}->literal_value,
			$result->{friendpage}->uri,
			);
	}
