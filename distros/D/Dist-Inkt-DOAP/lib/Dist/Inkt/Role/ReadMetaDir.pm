package Dist::Inkt::Role::ReadMetaDir;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.100';

use Moose::Role;
use RDF::TrineX::Functions 'parse';
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

after PopulateModel => sub {
	my $self = shift;
	for my $file ($self->sourcefile('meta')->children)
	{
		next unless $file =~ /\.(pret|pretdsl|ttl|turtle|nt|ntriples|rdf|rdfx)$/i;
		
		$self->log('Reading %s', $file);
		$file =~ /\.pret$/
			? do {
				require RDF::TrineX::Parser::Pretdsl;
				parse($file, into => $self->model, using => 'RDF::TrineX::Parser::Pretdsl'->new)
			}: parse($file, into => $self->model);
	}
};

1;
