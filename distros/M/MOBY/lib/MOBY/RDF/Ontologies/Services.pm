#-----------------------------------------------------------------
# MOBY::RDF::Ontologies::Services
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: Services.pm,v 1.11 2009/02/03 18:05:03 kawas Exp $
#-----------------------------------------------------------------

package MOBY::RDF::Ontologies::Services;

use RDF::Core;
use RDF::Core::Storage::Memory;
use RDF::Core::Model;
use RDF::Core::Literal;
use RDF::Core::Statement;
use RDF::Core::Model::Serializer;
use RDF::Core::NodeFactory;

use Digest::MD5 qw /md5_hex/;

use XML::LibXML;

use LS::ID;

use MOBY::Client::Central;
use MOBY::Config;

use MOBY::RDF::Predicates::DC_PROTEGE;
use MOBY::RDF::Predicates::FETA;
use MOBY::RDF::Predicates::MOBY_PREDICATES;
use MOBY::RDF::Predicates::OMG_LSID;
use MOBY::RDF::Predicates::RDF;
use MOBY::RDF::Predicates::RDFS;
use MOBY::RDF::Utils;

use Data::Dumper;
use strict;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.11 $ =~ /: (\d+)\.(\d+)/;

#-----------------------------------------------------------------
# load all modules needed for my attributes
#-----------------------------------------------------------------

=head1 NAME

MOBY::RDF::Ontologies::Services - Create RDF/OWL for Moby

=head1 SYNOPSIS

	use MOBY::RDF::Ontologies::Services;

	my $x = MOBY::RDF::Ontologies::Services->new;

	# get pretty printed RDF/XML for one service
	print $x->findService({ 
		serviceName => 'MOBYSHoundGiFromGOIDListAndECode',
		authURI => 'bioinfo.icapture.ubc.ca' 
	});

	# get unformatted RDF/XML for a bunch of services from a single provider
	print $x->findService({ 
		prettyPrint => 'no',
		authURI => 'bioinfo.icapture.ubc.ca' 
	});

	# get unformatted RDF/XML for a bunch of services from a single provider without isAlive info
	print $x->findService({ 
		prettyPrint => 'no',
		authURI => 'bioinfo.icapture.ubc.ca',
		isAlive => 'no' 
	});

	# get unformatted RDF/XML for all services
	print $x->findService({ 
		prettyPrint => 'no' 
	});

=head1 DESCRIPTION

	This module aids in the creation of RDF/XML for service instances in the BioMOBY world.

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------

=head2 new

Instantiate a Services object.

Parameters: 
	* A Hash with keys:
		-> endpoint		=> the BioMOBY registry endpoint to use <optional>
		-> namespace	=> the BioMOBY registry namespace to use <optional>

=cut

sub new {
	my ( $class, %args ) = @_;

	# create an object
	my $self = bless {}, ref($class) || $class;

	# save some information retrieved from mobycentral.config
	my $CONF = MOBY::Config->new;

	# set the uris unless an endpoint was specified
	do {
		$self->{instance_uri}  = $CONF->{mobycentral}->{resourceURL}   || '';
		$self->{service_uri}   = $CONF->{mobyservice}->{resourceURL}   || '';
		$self->{datatype_uri}  = $CONF->{mobyobject}->{resourceURL}    || '';
		$self->{namespace_uri} = $CONF->{mobynamespace}->{resourceURL} || '';
	} unless $args{endpoint};

	# save the endpoint/namespace/uri if passed in
	$self->{endpoint}  = $args{endpoint} if $args{endpoint};
	$self->{namespace} = $args{endpoint} if $args{namespace};

	unless ( $self->{instance_uri} ) {
		my $moby =
		  MOBY::Client::Central->new(
					 Registries => {
						 mobycentral => {
							 URL => $self->{endpoint},
							 URI => 'http://mobycentral.cbr.nrc.ca/MOBY/Central'
						 }
					 }
		  ) if $self->{endpoint};

		# otherwise use default one
		$moby = MOBY::Client::Central->new() unless $self->{endpoint};

		# moby is a hash ref now
		$moby = $moby->retrieveResourceURLs();

		# add all uris
		$self->{instance_uri} = $moby->{ServiceInstance}->[0]
		  if $moby->{ServiceInstance}->[0];
		$self->{service_uri} = $moby->{Services}->[0] if $moby->{Services}->[0];
		$self->{namespace_uri} = $moby->{Namespaces}->[0]
		  if $moby->{Namespaces}->[0];
		$self->{datatype_uri} = $moby->{Objects}->[0] if $moby->{Objects}->[0];

		#revert to a default value if nothing is retrieved
		$self->{instance_uri} =
		  'http://biomoby.org/RESOURCES/MOBY-S/ServiceInstances/'
		  unless $moby->{ServiceInstance}->[0];
		$self->{service_uri} = 'http://biomoby.org/RESOURCES/MOBY-S/Services/'
		  unless $moby->{Services}->[0];
		$self->{namespace_uri} =
		  'http://biomoby.org/RESOURCES/MOBY-S/Namespaces/'
		  unless $moby->{Namespaces}->[0];
		$self->{datatype_uri} = 'http://biomoby.org/RESOURCES/MOBY-S/Objects/'
		  unless $moby->{Objects}->[0];
	}

	# add a / at the end of the uri if it isnt there already
	$self->{instance_uri} = $self->{instance_uri} . "/"
	  unless $self->{instance_uri} =~ m/^.*(\/{1})$/;
	$self->{service_uri} = $self->{service_uri} . "/"
	  unless $self->{service_uri} =~ m/^.*(\/{1})$/;
	$self->{namespace_uri} = $self->{namespace_uri} . "/"
	  unless $self->{namespace_uri} =~ m/^.*(\/{1})$/;
	$self->{datatype_uri} = $self->{datatype_uri} . "/"
	  unless $self->{datatype_uri} =~ m/^.*(\/{1})$/;

	#set the isAlive path
	$self->{is_alive_path} = $CONF->{mobycentral}->{service_tester_path}
	  if $ENV{MOBY_SERVER}
		  and $self->{endpoint}
		  and $ENV{MOBY_SERVER} eq $self->{endpoint};

	# done
	return $self;
}

#-----------------------------------------------------------------
# findService
#-----------------------------------------------------------------

=head2 findService

Return a string of RDF in XML service instances in the service ontology.
 This routine consumes a hash as input with keys:
	authURI: the service provider URI <optional>
	serviceName: the name of a particular service <optional>
	isAlive    : whether (yes) or not (no) to add isAlive information. Defaults to 'yes'.
	prettyPrint: whether (yes) or not (no) to output 'pretty print' formatted XML. Defaults to 'yes'.

#TODO should i add all parameters from findService here?

=cut

sub findService {
	my ( $self, $hash ) = @_;

	my $authURI = $hash->{authURI}     || '';
	my $name    = $hash->{serviceName} || '';
	my $prettyPrint = $hash->{prettyPrint} ? $hash->{prettyPrint} : 'yes';
	my $addIsAlive  = $hash->{isAlive}     ? $hash->{isAlive}     : 'yes';
	my $services    = [];
	my $RegObject;

	# use the passed in endpoint if applicable
	my $moby =
	  MOBY::Client::Central->new(
					 Registries => {
						 mobycentral => {
							 URL => $self->{endpoint},
							 URI => 'http://mobycentral.cbr.nrc.ca/MOBY/Central'
						 }
					 }
	  ) if $self->{endpoint};

	# otherwise use default one
	$moby = MOBY::Client::Central->new() unless $self->{endpoint};

	if ( $name ne '' or $authURI ne '' ) {
		( $services, $RegObject ) =
		  $moby->findService( authURI => $authURI, serviceName => $name );

	}
	else {
		my (@URIS) = $moby->retrieveServiceProviders();
		foreach my $provider (@URIS) {
			my ( $instances, $RegObject ) =
			  $moby->findService( authURI => $provider );
			push @$services, @$instances;
		}

	}
	my $xml = $self->_createRDFModel( \@$services, $addIsAlive );
	return new MOBY::RDF::Utils->prettyPrintXML( { xml => $xml } )
	  unless $prettyPrint =~ /no/i;
	return $xml;
}

#-----------------------------------------------------------------
# _createRDFModel
#-----------------------------------------------------------------

=head2 _createRDFModel

this routine takes an array of MOBY::Client::ServiceInstance objects and
creates and RDF model for them all.

=cut

sub _createRDFModel {
	my ( $self, $services, $addIsAlive ) = @_;

	# set up an RDF model
	my $storage      = new RDF::Core::Storage::Memory;
	my $model        = new RDF::Core::Model( Storage => $storage );
	my $node_factory = new RDF::Core::NodeFactory();

	foreach my $SI (@$services) {

		# used for computing checksums
		my $service_name      = $SI->name;
		my $service_authority = $SI->authority;

		my $resource = new RDF::Core::Resource( $self->{instance_uri},
											 $SI->authority . "," . $SI->name );
		$model->addStmt(
						 new RDF::Core::Statement(
							 $resource,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
								 MOBY::RDF::Predicates::FETA->serviceDescription
							 )
						 )
		);
		$model->addStmt(
				new RDF::Core::Statement(
					$resource,
					$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->format ),
					new RDF::Core::Literal( $SI->category )
				)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->identifier ),
				new RDF::Core::Literal( $SI->LSID )
			)
		);
		$model->addStmt(
				 new RDF::Core::Statement(
					 $resource,
					 $resource->new( MOBY::RDF::Predicates::FETA->locationURI ),
					 new RDF::Core::Literal( $SI->URL )
				 )
		);
		$model->addStmt(
				  new RDF::Core::Statement(
					  $resource,
					  $resource->new(
						  MOBY::RDF::Predicates::FETA->hasServiceDescriptionText
					  ),
					  new RDF::Core::Literal( $SI->description )
				  )
		);
		$model->addStmt(
			  new RDF::Core::Statement(
				  $resource,
				  $resource->new(
					  MOBY::RDF::Predicates::FETA->hasServiceDescriptionLocation
				  ),
				  new RDF::Core::Literal( $SI->signatureURL )
			  )
		);
		$model->addStmt(
						 new RDF::Core::Statement(
							 $resource,
							 $resource->new(
								 MOBY::RDF::Predicates::FETA->hasServiceNameText
							 ),
							 new RDF::Core::Literal( $SI->name )
						 )
		);
		eval {
			do {

				# add is alive information if necessary
				if (     $self->{is_alive_path}
					 and -e $self->{is_alive_path}
					 and -r $self->{is_alive_path} . "/isAliveStats.xml" )
				{
					my $parser = XML::LibXML->new();
					my $doc =
					  $parser->parse_file(
								 $self->{is_alive_path} . '/isAliveStats.xml' );
					my $value    = "true";
					my $id       = $SI->authority . "," . $SI->name;
					my @nodelist = $doc->getElementsByTagName("service");
					for my $node (@nodelist) {
						next unless ( $node->getAttribute('id') eq $id );
						$value = $node->textContent;
						last;
					}
					$model->addStmt(
									new RDF::Core::Statement(
										$resource,
										$resource->new(
											MOBY::RDF::Predicates::FETA->isAlive
										),
										new RDF::Core::Literal($value)
									)
					);
				}
				else {

					# by default, state the service is alive ...
					$model->addStmt(
									new RDF::Core::Statement(
										$resource,
										$resource->new(
											MOBY::RDF::Predicates::FETA->isAlive
										),
										new RDF::Core::Literal('true')
									)
					);
				}
			} unless $addIsAlive =~ /no/i;
		};

		# add the authoring statements
		my $bnode =
		  new RDF::Core::Resource(
								   $self->{instance_uri},
								   md5_hex(
											"$service_authority/$service_name/"
											  . MOBY::RDF::Predicates::FETA
											  ->providedBy
								   )
		  );    #$node_factory->newResource;
		$model->addStmt(
				  new RDF::Core::Statement(
					  $resource,
					  $resource->new( MOBY::RDF::Predicates::FETA->providedBy ),
					  $bnode
				  )
		);
		$model->addStmt(
			   new RDF::Core::Statement(
				   $bnode,
				   $resource->new( MOBY::RDF::Predicates::FETA->authoritative ),
				   new RDF::Core::Literal(
									  $SI->authoritative == 0 ? "false" : "true"
				   )
			   )
		);
		$model->addStmt(
			   new RDF::Core::Statement(
				   $bnode,
				   $resource->new( MOBY::RDF::Predicates::DC_PROTEGE->creator ),
				   new RDF::Core::Literal( $SI->contactEmail )
			   )
		);
		$model->addStmt(
			 new RDF::Core::Statement(
				 $bnode,
				 $resource->new( MOBY::RDF::Predicates::DC_PROTEGE->publisher ),
				 new RDF::Core::Literal( $SI->authority )
			 )
		);
		$model->addStmt(
						 new RDF::Core::Statement(
							 $bnode,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
									   MOBY::RDF::Predicates::FETA->organisation
							 )
						 )
		);

		# add parameter statements
		my $operation =
		  new RDF::Core::Resource(
								   $self->{instance_uri},
								   md5_hex(
											"$service_authority/$service_name/"
											  . MOBY::RDF::Predicates::FETA
											  ->hasOperation
								   )
		  );    # $node_factory->newResource;
		$model->addStmt(
				new RDF::Core::Statement(
					$resource,
					$resource->new( MOBY::RDF::Predicates::FETA->hasOperation ),
					$operation
				)
		);
		$model->addStmt(
					   new RDF::Core::Statement(
						   $operation,
						   $resource->new(
							   MOBY::RDF::Predicates::FETA->hasOperationNameText
						   ),
						   new RDF::Core::Literal( $SI->name )
					   )
		);
		$model->addStmt(
						 new RDF::Core::Statement(
							 $operation,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
										MOBY::RDF::Predicates::FETA->operation )
						 )
		);
		$bnode = new RDF::Core::Resource(
							   $self->{instance_uri},
							   md5_hex(
								   "$service_authority/$service_name/"
									 . MOBY::RDF::Predicates::FETA->performsTask
							   )
		);    # $node_factory->newResource;
		$model->addStmt(
				new RDF::Core::Statement(
					$operation,
					$resource->new( MOBY::RDF::Predicates::FETA->performsTask ),
					$bnode
				)
		);
		$model->addStmt(
						 new RDF::Core::Statement(
							 $bnode,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
									  MOBY::RDF::Predicates::FETA->operationTask
							 )
						 )
		);
		# add the service type		
		$model->addStmt(
				 new RDF::Core::Statement(
					 $bnode,
					 $resource->new( MOBY::RDF::Predicates::RDF->type ),
					 new RDF::Core::Resource($self->{service_uri} . $SI->type )
				 )
		);

		# add unit test data here ...
		if ( $SI->unitTests ) {
			my $unitTests = $SI->unitTests;
			my $utils = new MOBY::RDF::Utils;
			foreach my $unit_test (@$unitTests) {
				$bnode =
				  new RDF::Core::Resource(
						  $self->{instance_uri},
						  md5_hex(
							  "$service_authority/$service_name/"
								. (
									  $unit_test->example_input
									? $utils->trim($unit_test->example_input)
									: ""
								)
								. (
									  $unit_test->expected_output
									? $utils->trim($unit_test->expected_output)
									: ""
								)
								. ( $unit_test->regex ? $utils->trim($unit_test->regex) : "" )
								. ( $unit_test->xpath ? $utils->trim($unit_test->xpath) : "" )
								."/"
								. MOBY::RDF::Predicates::FETA->unitTest
						  )
				  );

				# add the type
				$model->addStmt(
						 new RDF::Core::Statement(
							 $bnode,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
										   MOBY::RDF::Predicates::FETA->unitTest
							 )
						 )
				);

				# add the example input if defined
				$model->addStmt(
						 new RDF::Core::Statement(
							 $bnode,
							 $resource->new(
									   MOBY::RDF::Predicates::FETA->exampleInput
							 ),
							 new RDF::Core::Literal( $unit_test->example_input )
						 )
				  )
				  if $unit_test->example_input
					  and $unit_test->example_input ne '';

				# add the valid output xml if defined
				$model->addStmt(
					   new RDF::Core::Statement(
						   $bnode,
						   $resource->new(
									 MOBY::RDF::Predicates::FETA->validOutputXML
						   ),
						   new RDF::Core::Literal( $unit_test->expected_output )
					   )
				  )
				  if $unit_test->expected_output
					  and $unit_test->expected_output ne '';

				# add the valid regex if defined
				$model->addStmt(
								 new RDF::Core::Statement(
									 $bnode,
									 $resource->new(
										 MOBY::RDF::Predicates::FETA->validREGEX
									 ),
									 new RDF::Core::Literal( $unit_test->regex )
								 )
				  )
				  if $unit_test->regex
					  and $unit_test->regex ne '';

				# add the valid xpath expression if defined
				$model->addStmt(
								 new RDF::Core::Statement(
									 $bnode,
									 $resource->new(
										 MOBY::RDF::Predicates::FETA->validXPath
									 ),
									 new RDF::Core::Literal( $unit_test->xpath )
								 )
				  )
				  if $unit_test->xpath
					  and $unit_test->xpath ne '';

				$model->addStmt(
								new RDF::Core::Statement(
									$operation,
									$resource->new(
										MOBY::RDF::Predicates::FETA->hasUnitTest
									),
									$bnode
								)
				);
			}
		}

		my $inputs = $SI->input;
		foreach (@$inputs) {
			my $inputParameter =
			  new RDF::Core::Resource(
							$self->{instance_uri},
							md5_hex(
								"$service_authority/$service_name/"
								  . (
									$_->isSimple ? "isSimple/" : "isCollection/"
								  )
								  . MOBY::RDF::Predicates::FETA->inputParameter
								  . "/"
								  . $_->articleName
							)
			  );    # $node_factory->newResource;
			$model->addStmt(
							 new RDF::Core::Statement(
								 $operation,
								 $resource->new(
									 MOBY::RDF::Predicates::FETA->inputParameter
								 ),
								 $inputParameter
							 )
			);
			if ( $_->isSimple ) {
				$model->addStmt(
					   new RDF::Core::Statement(
						   $inputParameter,
						   $resource->new(
							   MOBY::RDF::Predicates::FETA->hasParameterNameText
						   ),
						   new RDF::Core::Literal( $_->articleName )
					   )
				);
				$model->addStmt(
						 new RDF::Core::Statement(
							 $inputParameter,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
										  MOBY::RDF::Predicates::FETA->parameter
							 )
						 )
				);
							
				my $oType =
				  new RDF::Core::Resource(
					   $self->{instance_uri},
					   md5_hex(
						       "$service_authority/$service_name/"
							 . ( $_->isSimple ? "isSimple/" : "isCollection/" )
							 . MOBY::RDF::Predicates::FETA->inputParameter . "/"
							 . $_->articleName . "/"
							 . $_->objectType
					   )
				  );    # $node_factory->newResource;
				$model->addStmt(
								 new RDF::Core::Statement(
									 $inputParameter,
									 $resource->new(
										 MOBY::RDF::Predicates::FETA->objectType
									 ),
									 $oType
								 )
				);
								
				$model->addStmt(
					new RDF::Core::Statement(
						$oType,
						$resource->new( MOBY::RDF::Predicates::RDF->type ),
						new RDF::Core::Resource(
							# check for lsids
							LS::ID->new($_->objectType) ? 
								$_->objectType : $self->{datatype_uri} . $_->objectType
						)
					)
				);

				my $pType =
				  new RDF::Core::Resource(
					 $self->{instance_uri},
					 md5_hex(
						     "$service_authority/$service_name/"
						   . ( $_->isSimple ? "isSimple/" : "isCollection/" )
						   . MOBY::RDF::Predicates::FETA->hasParameterType . "/"
						   . $_->articleName
					 )
				  );           # $node_factory->newResource;
				$model->addStmt(
						   new RDF::Core::Statement(
							   $inputParameter,
							   $resource->new(
								   MOBY::RDF::Predicates::FETA->hasParameterType
							   ),
							   $pType
						   )
				);
				$model->addStmt(
						 new RDF::Core::Statement(
							 $pType,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
									MOBY::RDF::Predicates::FETA->simpleParameter
							 )
						 )
				);
				my $namespaces = $_->namespaces;
				foreach my $n (@$namespaces) {
					my $inNamespaces =
					  new RDF::Core::Resource(
						$self->{instance_uri},
						md5_hex(
							    "$service_authority/$service_name/"
							  . ( $_->isSimple ? "isSimple/" : "isCollection/" )
							  . MOBY::RDF::Predicates::FETA->inputParameter
							  . "/"
							  . $_->articleName . "/"
							  . $n
						)
					  );    # $node_factory->newResource;
					$model->addStmt(
							   new RDF::Core::Statement(
								   $inputParameter,
								   $resource->new(
									   MOBY::RDF::Predicates::FETA->inNamespaces
								   ),
								   $inNamespaces
							   )
					);
					$model->addStmt(
						 new RDF::Core::Statement(
							 $inNamespaces,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
								 MOBY::RDF::Predicates::FETA->parameterNamespace
							 )
						 )
					);
					$model->addStmt(
						new RDF::Core::Statement(
							$inNamespaces,
							$resource->new( MOBY::RDF::Predicates::RDF->type ),
							new RDF::Core::Resource(
								LS::ID->new($n) ? 
									$n : $self->{namespace_uri} . $n
							  )  # check for lsids
						)
					);
				}
			}
			elsif ( $_->isCollection ) {

				$model->addStmt(
					   new RDF::Core::Statement(
						   $inputParameter,
						   $resource->new(
							   MOBY::RDF::Predicates::FETA->hasParameterNameText
						   ),
						   new RDF::Core::Literal( $_->articleName )
					   )
				);
				$model->addStmt(
						 new RDF::Core::Statement(
							 $inputParameter,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
										  MOBY::RDF::Predicates::FETA->parameter
							 )
						 )
				);

				my $pType =
				  new RDF::Core::Resource(
					 $self->{instance_uri},
					 md5_hex(
						     "$service_authority/$service_name/"
						   . ( $_->isSimple ? "isSimple/" : "isCollection/" )
						   . MOBY::RDF::Predicates::FETA->hasParameterType . "/"
						   . $_->articleName
					 )
				  );    # $node_factory->newResource;
				$model->addStmt(
						   new RDF::Core::Statement(
							   $inputParameter,
							   $resource->new(
								   MOBY::RDF::Predicates::FETA->hasParameterType
							   ),
							   $pType
						   )
				);
				$model->addStmt(
						new RDF::Core::Statement(
							$pType,
							$resource->new( MOBY::RDF::Predicates::RDF->type ),
							new RDF::Core::Resource(
								MOBY::RDF::Predicates::FETA->collectionParameter
							)
						)
				);

				my $simples = $_->Simples;
				foreach my $simp (@$simples) {
					my $oType =
					  new RDF::Core::Resource(
						$self->{instance_uri},
						md5_hex(
							    "$service_authority/$service_name/"
							  . ( $_->isSimple ? "isSimple/" : "isCollection/" )
							  . MOBY::RDF::Predicates::FETA->inputParameter
							  . "/"
							  . $_->articleName . "/"
							  . $simp->objectType
						)
					  );    # $node_factory->newResource;
					$model->addStmt(
								 new RDF::Core::Statement(
									 $inputParameter,
									 $resource->new(
										 MOBY::RDF::Predicates::FETA->objectType
									 ),
									 $oType
								 )
					);
					$model->addStmt(
						new RDF::Core::Statement(
							$oType,
							$resource->new( MOBY::RDF::Predicates::RDF->type ),
							new RDF::Core::Resource(
								LS::ID->new($simp->objectType) ? 
									$simp->objectType : $self->{datatype_uri} . $simp->objectType	   
							  )# check for lsids
						)
					);
					my $namespaces = $simp->namespaces;
					foreach my $n (@$namespaces) {
						my $inNamespaces =
						  new RDF::Core::Resource(
							$self->{instance_uri},
							md5_hex(
								"$service_authority/$service_name/"
								  . (
									$_->isSimple ? "isSimple/" : "isCollection/"
								  )
								  . MOBY::RDF::Predicates::FETA->inputParameter
								  . "/"
								  . $_->articleName . "/"
								  . $n
							)
						  );    # $node_factory->newResource;
						$model->addStmt(
							   new RDF::Core::Statement(
								   $inputParameter,
								   $resource->new(
									   MOBY::RDF::Predicates::FETA->inNamespaces
								   ),
								   $inNamespaces
							   )
						);
						$model->addStmt(
										new RDF::Core::Statement(
											$inNamespaces,
											$resource->new(
												MOBY::RDF::Predicates::RDF->type
											),
											new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->parameterNamespace
											)
										)
						);
						$model->addStmt(
							new RDF::Core::Statement(
								$inNamespaces,
								$resource->new(
												MOBY::RDF::Predicates::RDF->type
								),
								new RDF::Core::Resource(
									LS::ID->new($n) ? 
										$n : $self->{namespace_uri} . $n
								  )# check for lsids
							)
						);
					}
				}
			}
		}

		my $secondaries = $SI->secondary;

		foreach (@$secondaries) {
			next unless $_->isSecondary;
			my $inputParameter =
			  new RDF::Core::Resource(
							 $self->{instance_uri},
							 md5_hex(
								     "$service_authority/$service_name/"
								   . "isSecondaryInputParameter/"
								   . MOBY::RDF::Predicates::FETA->inputParameter
								   . "/"
								   . $_->articleName
							 )
			  );    #$node_factory->newResource;
			$model->addStmt(
							 new RDF::Core::Statement(
								 $operation,
								 $resource->new(
									 MOBY::RDF::Predicates::FETA->inputParameter
								 ),
								 $inputParameter
							 )
			);
			$model->addStmt(
						 new RDF::Core::Statement(
							 $inputParameter,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
										  MOBY::RDF::Predicates::FETA->parameter
							 )
						 )
			);

			my $pType =
			  new RDF::Core::Resource(
						   $self->{instance_uri},
						   md5_hex(
							       "$service_authority/$service_name/"
								 . "isSecondary/"
								 . MOBY::RDF::Predicates::FETA->hasParameterType
								 . "/"
								 . $_->articleName
						   )
			  );    # $node_factory->newResource;
			$model->addStmt(
						   new RDF::Core::Statement(
							   $inputParameter,
							   $resource->new(
								   MOBY::RDF::Predicates::FETA->hasParameterType
							   ),
							   $pType
						   )
			);
			$model->addStmt(
						 new RDF::Core::Statement(
							 $pType,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
								 MOBY::RDF::Predicates::FETA->secondaryParameter
							 )
						 )
			);

			$model->addStmt(
					   new RDF::Core::Statement(
						   $inputParameter,
						   $resource->new(
							   MOBY::RDF::Predicates::FETA->hasParameterNameText
						   ),
						   new RDF::Core::Literal( $_->articleName )
					   )
			);

			$model->addStmt(
						 new RDF::Core::Statement(
							 $inputParameter,
							 $resource->new( MOBY::RDF::Predicates::FETA->min ),
							 new RDF::Core::Literal( $_->min )
						 )
			) if defined( $_->min );

			$model->addStmt(
						 new RDF::Core::Statement(
							 $inputParameter,
							 $resource->new( MOBY::RDF::Predicates::FETA->max ),
							 new RDF::Core::Literal( $_->max )
						 )
			) if defined( $_->max );

			$model->addStmt(
				new RDF::Core::Statement(
					$inputParameter,
					$resource->new(
						MOBY::RDF::Predicates::FETA->hasParameterDescriptionText
					),
					new RDF::Core::Literal( $_->description )
				)
			);

			$model->addStmt(
							new RDF::Core::Statement(
								$inputParameter,
								$resource->new(
									MOBY::RDF::Predicates::FETA->hasDefaultValue
								),
								new RDF::Core::Literal( $_->default )
							)
			) if defined( $_->default );

			$model->addStmt(
					new RDF::Core::Statement(
						$inputParameter,
						$resource->new( MOBY::RDF::Predicates::FETA->datatype ),
						new RDF::Core::Literal( $_->datatype )
					)
			);
			foreach my $e ( @{ $_->enum } ) {
				$model->addStmt(
						new RDF::Core::Statement(
							$inputParameter,
							$resource->new( MOBY::RDF::Predicates::FETA->enum ),
							new RDF::Core::Literal($e)
						)
				);
			}
		}

		my $outputs = $SI->output;
		foreach (@$outputs) {
			my $outputParameter =
			  new RDF::Core::Resource(
						  $self->{instance_uri},
						  md5_hex(
							  "$service_authority/$service_name/"
								. (
								  $_->isSimple ? "isSimple/" : "isCollection/" )
								. MOBY::RDF::Predicates::FETA->outputParameter
								. "/"
								. $_->articleName
						  )
			  );    # $node_factory->newResource;
			$model->addStmt(
							new RDF::Core::Statement(
								$operation,
								$resource->new(
									MOBY::RDF::Predicates::FETA->outputParameter
								),
								$outputParameter
							)
			);
			if ( $_->isSimple ) {
				$model->addStmt(
					   new RDF::Core::Statement(
						   $outputParameter,
						   $resource->new(
							   MOBY::RDF::Predicates::FETA->hasParameterNameText
						   ),
						   new RDF::Core::Literal( $_->articleName )
					   )
				);
				$model->addStmt(
						 new RDF::Core::Statement(
							 $outputParameter,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
										  MOBY::RDF::Predicates::FETA->parameter
							 )
						 )
				);

				my $oType =
				  new RDF::Core::Resource(
					  $self->{instance_uri},
					  md5_hex(
						      "$service_authority/$service_name/"
							. ( $_->isSimple ? "isSimple/" : "isCollection/" )
							. MOBY::RDF::Predicates::FETA->outputParameter . "/"
							. $_->articleName . "/"
							. $_->objectType
					  )
				  );    # $node_factory->newResource;
				$model->addStmt(
								 new RDF::Core::Statement(
									 $outputParameter,
									 $resource->new(
										 MOBY::RDF::Predicates::FETA->objectType
									 ),
									 $oType
								 )
				);
				$model->addStmt(
					new RDF::Core::Statement(
						$oType,
						$resource->new( MOBY::RDF::Predicates::RDF->type ),
						new RDF::Core::Resource(
							LS::ID->new($_->objectType) ? 
								$_->objectType : $self->{datatype_uri} . $_->objectType
						  )# check for lsids
					)
				);

				my $pType =
				  new RDF::Core::Resource(
					 $self->{instance_uri},
					 md5_hex(
						     "$service_authority/$service_name/"
						   . ( $_->isSimple ? "isSimple/" : "isCollection/" )
						   . MOBY::RDF::Predicates::FETA->hasParameterType . "/"
						   . $_->articleName
					 )
				  );           # $node_factory->newResource;
				$model->addStmt(
						   new RDF::Core::Statement(
							   $outputParameter,
							   $resource->new(
								   MOBY::RDF::Predicates::FETA->hasParameterType
							   ),
							   $pType
						   )
				);
				$model->addStmt(
						 new RDF::Core::Statement(
							 $pType,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
									MOBY::RDF::Predicates::FETA->simpleParameter
							 )
						 )
				);
				my $namespaces = $_->namespaces;
				foreach my $n (@$namespaces) {
					my $inNamespaces =
					  new RDF::Core::Resource(
						$self->{instance_uri},
						md5_hex(
							    "$service_authority/$service_name/"
							  . ( $_->isSimple ? "isSimple/" : "isCollection/" )
							  . MOBY::RDF::Predicates::FETA->outputParameter
							  . "/"
							  . $_->articleName . "/"
							  . $n
						)
					  );    # $node_factory->newResource;
					$model->addStmt(
							   new RDF::Core::Statement(
								   $outputParameter,
								   $resource->new(
									   MOBY::RDF::Predicates::FETA->inNamespaces
								   ),
								   $inNamespaces
							   )
					);
					$model->addStmt(
						 new RDF::Core::Statement(
							 $inNamespaces,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
								 MOBY::RDF::Predicates::FETA->parameterNamespace
							 )
						 )
					);
					$model->addStmt(
						new RDF::Core::Statement(
							$inNamespaces,
							$resource->new( MOBY::RDF::Predicates::RDF->type ),
							new RDF::Core::Resource(
								LS::ID->new($n) ? 
									$n : $self->{namespace_uri} . $n
							  )# check for lsids
						)
					);
				}
			}
			elsif ( $_->isCollection ) {

				$model->addStmt(
					   new RDF::Core::Statement(
						   $outputParameter,
						   $resource->new(
							   MOBY::RDF::Predicates::FETA->hasParameterNameText
						   ),
						   new RDF::Core::Literal( $_->articleName )
					   )
				);
				$model->addStmt(
						 new RDF::Core::Statement(
							 $outputParameter,
							 $resource->new( MOBY::RDF::Predicates::RDF->type ),
							 new RDF::Core::Resource(
										  MOBY::RDF::Predicates::FETA->parameter
							 )
						 )
				);

				my $pType =
				  new RDF::Core::Resource(
					 $self->{instance_uri},
					 md5_hex(
						     "$service_authority/$service_name/"
						   . ( $_->isSimple ? "isSimple/" : "isCollection/" )
						   . MOBY::RDF::Predicates::FETA->hasParameterType . "/"
						   . $_->articleName
					 )
				  );    # $node_factory->newResource;
				$model->addStmt(
						   new RDF::Core::Statement(
							   $outputParameter,
							   $resource->new(
								   MOBY::RDF::Predicates::FETA->hasParameterType
							   ),
							   $pType
						   )
				);
				$model->addStmt(
						new RDF::Core::Statement(
							$pType,
							$resource->new( MOBY::RDF::Predicates::RDF->type ),
							new RDF::Core::Resource(
								MOBY::RDF::Predicates::FETA->collectionParameter
							)
						)
				);

				my $simples = $_->Simples;
				foreach my $simp (@$simples) {
					my $oType =
					  new RDF::Core::Resource(
						$self->{instance_uri},
						md5_hex(
							    "$service_authority/$service_name/"
							  . ( $_->isSimple ? "isSimple/" : "isCollection/" )
							  . MOBY::RDF::Predicates::FETA->outputParameter
							  . "/"
							  . $_->articleName . "/"
							  . $simp->objectType
						)
					  );    # $node_factory->newResource;
					$model->addStmt(
								 new RDF::Core::Statement(
									 $outputParameter,
									 $resource->new(
										 MOBY::RDF::Predicates::FETA->objectType
									 ),
									 $oType
								 )
					);
					$model->addStmt(
						new RDF::Core::Statement(
							$oType,
							$resource->new( MOBY::RDF::Predicates::RDF->type ),
							new RDF::Core::Resource(
								LS::ID->new($simp->objectType) ? 
									$simp->objectType : $self->{datatype_uri} . $simp->objectType
							  )# check for lsids
						)
					);
					my $namespaces = $simp->namespaces;
					foreach my $n (@$namespaces) {
						my $inNamespaces =
						  new RDF::Core::Resource(
							$self->{instance_uri},
							md5_hex(
								"$service_authority/$service_name/"
								  . (
									$_->isSimple ? "isSimple/" : "isCollection/"
								  )
								  . MOBY::RDF::Predicates::FETA->outputParameter
								  . "/"
								  . $_->articleName . "/"
								  . $n
							)
						  );    # $node_factory->newResource;
						$model->addStmt(
							   new RDF::Core::Statement(
								   $outputParameter,
								   $resource->new(
									   MOBY::RDF::Predicates::FETA->inNamespaces
								   ),
								   $inNamespaces
							   )
						);
						$model->addStmt(
										new RDF::Core::Statement(
											$inNamespaces,
											$resource->new(
												MOBY::RDF::Predicates::RDF->type
											),
											new RDF::Core::Resource(
													 MOBY::RDF::Predicates::FETA
													   ->parameterNamespace
											)
										)
						);
						$model->addStmt(
							new RDF::Core::Statement(
								$inNamespaces,
								$resource->new(
												MOBY::RDF::Predicates::RDF->type
								),
								new RDF::Core::Resource(
								LS::ID->new($n) ? 
									$n : $self->{namespace_uri} . $n
								  )
							)
						);
					}
				}
			}
		}
	}
	my $xml = '';
	my $serializer =
	  new RDF::Core::Model::Serializer(
										Model   => $model,
										Output  => \$xml,
										BaseURI => 'URI://BASE/',
	  );
	$serializer->serialize;
	return $xml;
}

1;
__END__
