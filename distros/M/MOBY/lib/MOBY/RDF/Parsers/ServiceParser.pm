#-----------------------------------------------------------------
# MOBY::RDF::Parsers::ServiceParser
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: ServiceParser.pm,v 1.6 2009/02/03 18:05:03 kawas Exp $
#-----------------------------------------------------------------
package MOBY::RDF::Parsers::ServiceParser;
use strict;

# imports
use RDF::Core::Model::Parser;
use RDF::Core::Model;
use RDF::Core::Storage::Memory;
use RDF::Core::Resource;

use MOBY::RDF::Utils;

use MOBY::Client::CollectionArticle;
use MOBY::Client::SimpleArticle;
use MOBY::Client::SecondaryArticle;
use MOBY::Client::ServiceInstance;

use MOBY::RDF::Predicates::DC_PROTEGE;
use MOBY::RDF::Predicates::MOBY_PREDICATES;
use MOBY::RDF::Predicates::OMG_LSID;
use MOBY::RDF::Predicates::RDF;
use MOBY::RDF::Predicates::FETA;
use MOBY::RDF::Predicates::RDFS;

use LS::ID;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

ServiceParser - An module for parsing the RDF that describes a biomoby service in the service instance ontology

=cut

=head1 SYNOPSIS

	use MOBY::RDF::Parsers::ServiceParser;
	use Data::Dumper;

	# construct a parser for service instances
	my $parser = MOBY::RDF::Parsers::ServiceParser->new();

	# get all services from a URL
	my $service_arrayref = $parser->getServices(
	    'http://biomoby.org/RESOURCES/MOBY-S/ServiceInstances/bioinfo.icapture.ubc.ca/getGoTerm'
	);

	# print out details regarding 'bioinfo.icapture.ubc.ca/getGoTerm'
	print Dumper( $service_arrayref );

=cut

=head1 DESCRIPTION

This module contains the methods required to download and parse service instance RDF into individual services

=cut

=head1 WARNING

Do not attempt to parse service instance RDF containing more than a few hundred services because the RDF is
parsed and held in memory.

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

=head2 new

Contructs a new ServiceParser.

Input: none.

Example: 

	MOBY::RDF::Parsers::ServiceParser->new()

=cut

sub new {
	my ($class) = @_;

	# create an object
	my $self = bless {}, ref($class) || $class;

	# done
	return $self;
}

=head2 getServices 

Downloads RDF from $url, parses it and returns an arrayref of C<MOBY::Client::ServiceInstance>.

Input: a scalar URL 

Example:

	my $parser = MOBY::RDF::Parsers::ServiceParser->new();
	my $service_arref = $parser->getServices('http://biomoby.org/RESOURCES/MOBY-S/ServiceInstances/bioinfo.icapture.ubc.ca/getGoTerm');

=cut

sub getServices {

	my ( $self, $url ) = @_;
	my @services;
	return \@services unless $url;

	# download string from url
	my $rdf = undef;

	# 'try/catch'
	eval { $rdf = MOBY::RDF::Utils->new()->getHttpRequestByURL($url); };
	return \@services unless $rdf;

	# create RDF model and populate
	my $storage = new RDF::Core::Storage::Memory;
	my $model = new RDF::Core::Model( Storage => $storage );
	my %options = (
					Model      => $model,
					Source     => $rdf,
					SourceType => 'string',
					BaseURI    => "$url",
	);
	my $parser = new RDF::Core::Model::Parser(%options);
	$parser->parse;

	# get information from the model
	my $enumerator = $model->getStmts(
									   undef, undef,
									   new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->serviceDescription(
													   )
									   )
	);
	my $statement = $enumerator->getFirst;
	while ( defined $statement ) {
		my $instance = MOBY::Client::ServiceInstance->new;

		# set the name for the service
		my $val = $model->getObjects(
									  $statement->getSubject,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->hasServiceNameText
									  )
		);
		$val = "" unless $$val[0];
		$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
		$instance->name( MOBY::RDF::Utils::trim($val) );

		# set the category
		$val = $model->getObjects(
								   $statement->getSubject,
								   new RDF::Core::Resource(
									   MOBY::RDF::Predicates::DC_PROTEGE->format
								   )
		);
		$val = "" unless $$val[0];
		$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
		$instance->category( MOBY::RDF::Utils::trim($val) );

		# set the lsid
		$val = $model->getObjects(
								   $statement->getSubject,
								   new RDF::Core::Resource(
											   MOBY::RDF::Predicates::DC_PROTEGE
												 ->identifier
								   )
		);
		$val = "" unless $$val[0];
		$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
		$instance->LSID( MOBY::RDF::Utils::trim($val) );

		# set the signatureURL
		$val = $model->getObjects(
								   $statement->getSubject,
								   new RDF::Core::Resource(
											   MOBY::RDF::Predicates::FETA
												 ->hasServiceDescriptionLocation
								   )
		);
		$val = "" unless $$val[0];
		$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
		$instance->signatureURL( MOBY::RDF::Utils::trim($val) );

		# set the url
		$val = $model->getObjects(
								   $statement->getSubject,
								   new RDF::Core::Resource(
										MOBY::RDF::Predicates::FETA->locationURI
								   )
		);
		$val = "" unless $$val[0];
		$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
		$instance->URL( MOBY::RDF::Utils::trim($val) );

		# set the service description text
		$val = $model->getObjects(
								   $statement->getSubject,
								   new RDF::Core::Resource(
												   MOBY::RDF::Predicates::FETA
													 ->hasServiceDescriptionText
								   )
		);
		$val = "" unless $$val[0];
		$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
		$instance->description( MOBY::RDF::Utils::trim($val) );

		# get providedBy node
		my $providedBy =
		  $model->getObjects(
							  $statement->getSubject,
							  new RDF::Core::Resource(
										 MOBY::RDF::Predicates::FETA->providedBy
							  )
		  );
		$providedBy = [] unless @$providedBy;
		$providedBy = $$providedBy[0]
		  if ref($providedBy) eq 'ARRAY' and $$providedBy[0];
		if ($providedBy) {

			# set the authoritative
			$val = $model->getObjects(
									   $providedBy,
									   new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->authoritative
									   )
			);
			$val = "" unless $$val[0];
			$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
			$instance->authoritative(
							 MOBY::RDF::Utils::trim($val) =~ m/true/i ? 1 : 0 );

			# set the contact email
			$val = $model->getObjects(
									   $providedBy,
									   new RDF::Core::Resource(
											   MOBY::RDF::Predicates::DC_PROTEGE
												 ->creator
									   )
			);
			$val = "" unless $$val[0];
			$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
			$instance->contactEmail( MOBY::RDF::Utils::trim($val) );

			# set the authority uri
			$val = $model->getObjects(
									   $providedBy,
									   new RDF::Core::Resource(
											   MOBY::RDF::Predicates::DC_PROTEGE
												 ->publisher
									   )
			);
			$val = "" unless $$val[0];
			$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
			$instance->authority( MOBY::RDF::Utils::trim($val) );
		}

		# no longer need the providedBy node
		$providedBy = undef;

		# get hasOperation node
		my $hasOperation =
		  $model->getObjects(
							  $statement->getSubject,
							  new RDF::Core::Resource(
									   MOBY::RDF::Predicates::FETA->hasOperation
							  )
		  );
		$hasOperation = [] unless @$hasOperation;
		$hasOperation = $$hasOperation[0]
		  if ref($hasOperation) eq 'ARRAY' and $$hasOperation[0];

		# if this is missing ... what's the point?
		next unless $hasOperation;

		# process any inputs
		my $inputs = $model->getObjects(
								 $hasOperation,
								 new RDF::Core::Resource(
									 MOBY::RDF::Predicates::FETA->inputParameter
								 )
		);
		$inputs = [] unless @$inputs;
		foreach my $input (@$inputs) {

			# check the type of param (simple, secondary, collection)
			my $node =
			  $model->getObjects(
								  $input,
								  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->hasParameterType
								  )
			  );
			$node = [] unless @$node;
			$node = $$node[0] if ref($node) eq 'ARRAY' and $$node[0];
			$val = $model->getObjects(
									   $node,
									   new RDF::Core::Resource(
												MOBY::RDF::Predicates::RDF->type
									   )
			);
			$val = "" unless $$val[0];
			$val = $$val[0]->getURI if ref($val) eq 'ARRAY' and $$val[0];

			# process the datatype
			if ( $val eq MOBY::RDF::Predicates::FETA->simpleParameter ) {
				my $param = MOBY::Client::SimpleArticle->new();

				# get any namespaces
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->inNamespaces
									  )
				  );
				$val = [] unless @$val;
				foreach my $ns (@$val) {
					$val =
					  $model->getObjects(
										  $ns,
										  new RDF::Core::Resource(
												MOBY::RDF::Predicates::RDF->type
										  )
					  );
					if ( $$val[0] ) {
						for my $uri (@$val) {
							$param->addNamespace( $self->_unwrap_namespace( $uri->getURI ) )
							  if $uri->getURI ne MOBY::RDF::Predicates::FETA
								  ->parameterNamespace;
						}
					}

				}

				# get the articlename
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->hasParameterNameText
									  )
				  );
				$val = "" unless $$val[0];
				$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
				$param->articleName($val);

				# get the datatype name
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->objectType
									  )
				  );
				$val = undef unless $$val[0];
				$val = $$val[0] if ref($val) eq 'ARRAY' and $$val[0];
				$val =
				  $model->getObjects(
									  $val,
									  new RDF::Core::Resource(
												MOBY::RDF::Predicates::RDF->type
									  )
				  );
				if ( $$val[0] ) {
					$param->objectType( $self->_unwrap_datatype($$val[0]->getURI) );
				}

				# add the param to the service
				push @{ $instance->input }, $param;
				$param = undef;
			}
			elsif ( $val eq MOBY::RDF::Predicates::FETA->collectionParameter ) {
				my $param      = MOBY::Client::SimpleArticle->new();
				my $collection = MOBY::Client::CollectionArticle->new();

				# get any namespaces
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->inNamespaces
									  )
				  );
				$val = [] unless @$val;
				foreach my $ns (@$val) {
					$val =
					  $model->getObjects(
										  $ns,
										  new RDF::Core::Resource(
												MOBY::RDF::Predicates::RDF->type
										  )
					  );
					if ( $$val[0] ) {
						for my $uri (@$val) {
							$param->addNamespace( $self->_unwrap_namespace( $uri->getURI ) )
							  if $uri->getURI ne MOBY::RDF::Predicates::FETA
								  ->parameterNamespace;
						}
					}

				}

				# get the articlename
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->hasParameterNameText
									  )
				  );
				$val = "" unless $$val[0];
				$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
				$collection->articleName($val);

				# get the datatype name
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->objectType
									  )
				  );
				$val = undef unless $$val[0];
				$val = $$val[0] if ref($val) eq 'ARRAY' and $$val[0];
				$val =
				  $model->getObjects(
									  $val,
									  new RDF::Core::Resource(
												MOBY::RDF::Predicates::RDF->type
									  )
				  );
				if ( $$val[0] ) {
					$param->objectType( $self->_unwrap_datatype($$val[0]->getURI) );
				}
				$collection->addSimple($param);

				# add the param to the service
				push @{ $instance->input }, $collection;
				$param = undef;
			}
			elsif ( $val eq MOBY::RDF::Predicates::FETA->secondaryParameter ) {
				my $param = MOBY::Client::SecondaryArticle->new;

				# get the articlename
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->hasParameterNameText
									  )
				  );
				$val = undef unless $$val[0];
				$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
				$param->articleName($val);

				# get the datatype name
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
										   MOBY::RDF::Predicates::FETA->datatype
									  )
				  );
				$val = undef unless $$val[0];
				$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
				$param->datatype($val);

				# get the max
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
												MOBY::RDF::Predicates::FETA->max
									  )
				  );
				$val = undef unless $$val[0];
				$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
				$param->max($val);

				# get the min
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
												MOBY::RDF::Predicates::FETA->min
									  )
				  );
				$val = undef unless $$val[0];
				$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
				$param->min($val);

				# get any enums
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
											   MOBY::RDF::Predicates::FETA->enum
									  )
				  );
				$val = [] unless $$val[0];
				foreach my $v ( @{$val} ) {
					$param->addEnum( $v->getValue );
				}

				# get the default
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->hasDefaultValue
									  )
				  );
				$val = undef unless $$val[0];
				$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
				$param->default($val);

				# get the description
				$val =
				  $model->getObjects(
									  $input,
									  new RDF::Core::Resource(
												 MOBY::RDF::Predicates::FETA
												   ->hasParameterDescriptionText
									  )
				  );
				$val = "" unless $$val[0];
				$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
				$param->description($val);

				# add the secondary to the service
				push @{ $instance->secondary }, $param;
				$param = undef;
			}
		}

		# dont need $inputs
		$inputs = undef;

		# process any outputs
		my $outputs = $model->getObjects(
								$hasOperation,
								new RDF::Core::Resource(
									MOBY::RDF::Predicates::FETA->outputParameter
								)
		);
		$outputs = [] unless @$outputs;
		foreach my $output (@$outputs) {

			# check the type of param (simple, secondary, collection)
			my $node =
			  $model->getObjects(
								  $output,
								  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->hasParameterType
								  )
			  );
			$node = [] unless @$node;
			$node = $$node[0] if ref($node) eq 'ARRAY' and $$node[0];
			$val = $model->getObjects(
									   $node,
									   new RDF::Core::Resource(
												MOBY::RDF::Predicates::RDF->type
									   )
			);
			$val = "" unless $$val[0];
			$val = $$val[0]->getURI if ref($val) eq 'ARRAY' and $$val[0];

			# process the datatype
			if ( $val eq MOBY::RDF::Predicates::FETA->simpleParameter ) {
				my $param = MOBY::Client::SimpleArticle->new();

				# get any namespaces
				$val =
				  $model->getObjects(
									  $output,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->inNamespaces
									  )
				  );
				$val = [] unless @$val;
				foreach my $ns (@$val) {
					$val =
					  $model->getObjects(
										  $ns,
										  new RDF::Core::Resource(
												MOBY::RDF::Predicates::RDF->type
										  )
					  );
					if ( $$val[0] ) {
						for my $uri (@$val) {
							$param->addNamespace( $self->_unwrap_namespace( $uri->getURI ) )
							  if $uri->getURI ne MOBY::RDF::Predicates::FETA
								  ->parameterNamespace;
						}
					}

				}

				# get the articlename
				$val =
				  $model->getObjects(
									  $output,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->hasParameterNameText
									  )
				  );
				$val = "" unless $$val[0];
				$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
				$param->articleName($val);

				# get the datatype name
				$val =
				  $model->getObjects(
									  $output,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->objectType
									  )
				  );
				$val = undef unless $$val[0];
				$val = $$val[0] if ref($val) eq 'ARRAY' and $$val[0];
				$val =
				  $model->getObjects(
									  $val,
									  new RDF::Core::Resource(
												MOBY::RDF::Predicates::RDF->type
									  )
				  );
				if ( $$val[0] ) {
					$param->objectType( $self->_unwrap_datatype($$val[0]->getURI) );
				}

				# add the param to the service
				push @{ $instance->output }, $param;
				$param = undef;
			}
			elsif ( $val eq MOBY::RDF::Predicates::FETA->collectionParameter ) {
				my $param      = MOBY::Client::SimpleArticle->new();
				my $collection = MOBY::Client::CollectionArticle->new();

				# get any namespaces
				$val =
				  $model->getObjects(
									  $output,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->inNamespaces
									  )
				  );
				$val = [] unless @$val;
				foreach my $ns (@$val) {
					$val =
					  $model->getObjects(
										  $ns,
										  new RDF::Core::Resource(
												MOBY::RDF::Predicates::RDF->type
										  )
					  );
					if ( $$val[0] ) {
						for my $uri (@$val) {
							$param->addNamespace( $self->_unwrap_namespace( $uri->getURI ) )
							  if $uri->getURI ne MOBY::RDF::Predicates::FETA
								  ->parameterNamespace;
						}
					}
				}

				# get the articlename
				$val =
				  $model->getObjects(
									  $output,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->hasParameterNameText
									  )
				  );
				$val = "" unless $$val[0];
				$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
				$collection->articleName($val);

				# get the datatype name
				$val =
				  $model->getObjects(
									  $output,
									  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->objectType
									  )
				  );
				$val = undef unless $$val[0];
				$val = $$val[0] if ref($val) eq 'ARRAY' and $$val[0];
				$val =
				  $model->getObjects(
									  $val,
									  new RDF::Core::Resource(
												MOBY::RDF::Predicates::RDF->type
									  )
				  );
				if ( $$val[0] ) {
					$param->objectType( $self->_unwrap_datatype($$val[0]->getURI) );
				}
				$collection->addSimple($param);

				# add the param to the service
				push @{ $instance->output }, $collection;
				$param = undef;
			}
		}

		# dont need $outputs
		$outputs = undef;

		# process the performsTask
		# get performsTask node
		my $performs =
		  $model->getObjects(
							  $hasOperation,
							  new RDF::Core::Resource(
									   MOBY::RDF::Predicates::FETA->performsTask
							  )
		  );
		$performs = [] unless @$performs;
		$performs = $$performs[0]
		  if ref($performs) eq 'ARRAY' and $$performs[0];
		$val = $model->getObjects(
								   $performs,
								   new RDF::Core::Resource(
												MOBY::RDF::Predicates::RDF->type
								   )
		);
		if ( $$val[0] ) {
			for my $uri (@$val) {
				$val = $uri->getURI
				  if $uri->getURI ne
					  MOBY::RDF::Predicates::FETA->operationTask();
				last
				  if $uri->getURI ne
					  MOBY::RDF::Predicates::FETA->operationTask();
			}
		}
		$val = "" if ref($val) eq 'ARRAY';
		$instance->type( $self->_unwrap_servicetype ( MOBY::RDF::Utils::trim($val) ) );

		# dont need the performsTask node anymore
		$performs = undef;

		# process any unit test information
		my $unit_test =
		  $model->getObjects(
							  $hasOperation,
							  new RDF::Core::Resource(
										MOBY::RDF::Predicates::FETA->hasUnitTest
							  )
		  );
		$unit_test = [] unless @$unit_test;
		foreach my $ut (@$unit_test) {
			my $unit = new MOBY::Client::MobyUnitTest;

			# get example input
			$val =
			  $model->getObjects(
								  $ut,
								  new RDF::Core::Resource(
									   MOBY::RDF::Predicates::FETA->exampleInput
								  )
			  );
			$val = "" unless $$val[0];
			$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
			$unit->example_input( MOBY::RDF::Utils::trim($val) );

			# get example output
			$val =
			  $model->getObjects(
								  $ut,
								  new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->validOutputXML
								  )
			  );
			$val = "" unless $$val[0];
			$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
			$unit->expected_output( MOBY::RDF::Utils::trim($val) );

			# get regex
			$val =
			  $model->getObjects(
								  $ut,
								  new RDF::Core::Resource(
										 MOBY::RDF::Predicates::FETA->validREGEX
								  )
			  );
			$val = "" unless $$val[0];
			$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
			$unit->regex( MOBY::RDF::Utils::trim($val) );

			# get xpath
			$val =
			  $model->getObjects(
								  $ut,
								  new RDF::Core::Resource(
										 MOBY::RDF::Predicates::FETA->validXPath
								  )
			  );
			$val = "" unless $$val[0];
			$val = $$val[0]->getValue if ref($val) eq 'ARRAY' and $$val[0];
			$unit->xpath( MOBY::RDF::Utils::trim($val) );

			# set the unit test in the service
			push @{ $instance->unitTests }, $unit;

			#$instance->unitTest($unit);
		}

		# this service is done ...
		push @services, $instance;

		# next if any
		$statement = $enumerator->getNext;
	}
	$enumerator->close;

	# return array ref
	return \@services;

}

sub _unwrap_datatype {
	my ($self, $uri) = @_;
	
	# process the objectType, i.e. check to see if it is an LSID, or uri, etc
	if ( $uri =~ m/RESOURCES\/MOBY\-S\/Objects(\/[A-Za-z0-9_\-]*)?$/ ) {
		$uri = substr $1, 1 if $1;
	} elsif (
		 $uri =~ m/RESOURCES\/MOBY\-S\/Objects(\#[A-Za-z0-9_\-]*)?$/ ) {
		$uri = substr $1, 1 if $1;
	} elsif ( $uri =~ m/^urn\:lsid/i ) {
		#my $lsid = LS::ID->new( $uri );
		#$uri =  $lsid->object if $lsid;
	}
	return $uri;
}

sub _unwrap_namespace {
	my ($self, $n) = @_;
	# get only the namespace name (strip from lsid or URI)
	if ($n =~ m/RESOURCES\/MOBY\-S\/Namespaces(\/[A-Za-z0-9_\-]*)?$/) {
		$n = substr $1, 1 if $1;
	} elsif ($n =~ m/RESOURCES\/MOBY\-S\/Namespaces(\#[A-Za-z0-9_\-]*)?$/ ){
		$n = substr $1, 1 if $1;
	} elsif( $n =~ m/^urn\:lsid/i) {
		#my $lsid = LS::ID->new($n);
		#$n = $lsid->object if $lsid;
	}
	return $n;
}

sub _unwrap_servicetype {
	my ($self, $n) = @_;
	# get only the servicetype name (strip from lsid or URI)
	if ($n =~ m/RESOURCES\/MOBY\-S\/Services(\/[A-Za-z0-9_\-]*)?$/) {
		$n = substr $1, 1 if $1;
	} elsif ($n =~ m/RESOURCES\/MOBY\-S\/Services(\#[A-Za-z0-9_\-]*)?$/ ){
		$n = substr $1, 1 if $1;
	} elsif( $n =~ m/^urn\:lsid/i) {
		#my $lsid = LS::ID->new($n);
		#$n = $lsid->object if $lsid;
	}
	return $n;
}


1;
__END__
