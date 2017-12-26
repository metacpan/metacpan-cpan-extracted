package Dist::Inkt::Role::RDFModel;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.100';

use Moose::Role;
use Types::Standard -types;
use namespace::autoclean;

has model => (
	is       => 'ro',
	isa      => InstanceOf['RDF::Trine::Model'],
	lazy     => 1,
	builder  => '_build_model',
);

sub _build_model
{
	require RDF::Trine;
	return 'RDF::Trine::Model'->temporary_model;
}

has doap_project => (
	is       => 'ro',
	isa      => InstanceOf['RDF::DOAP::Project'],
	lazy     => 1,
	builder  => '_build_doap_project',
);

sub _build_doap_project
{
	my $self = shift;
	require RDF::DOAP::Project;
	'RDF::DOAP::Project'->rdf_load(
		$self->project_uri,
		$self->model,
	);
}

1;
