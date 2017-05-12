package Dist::Inkt::Role::WriteDOAP;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.022';

use Moose::Role;
use RDF::TrineX::Functions 'serialize';
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'DOAP';
};

sub Build_DOAP
{
	my $self = shift;
	my $file = $self->targetfile('doap.ttl');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	$self->rights_for_generated_files->{'doap.ttl'} ||= [
		$self->_inherited_rights
	] if $self->DOES('Dist::Inkt::Role::WriteCOPYRIGHT');
	
	my $serializer = eval {
		require RDF::TrineX::Serializer::MockTurtleSoup;
		'RDF::TrineX::Serializer::MockTurtleSoup'->new;
	} || 'RDF::Trine::Serializer::Turtle'->new;
	
	serialize(
		$self->model,
		to    => $file->openw,
		using => $serializer,
	);
}

1;
