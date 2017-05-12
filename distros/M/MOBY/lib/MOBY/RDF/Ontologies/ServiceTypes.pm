#-----------------------------------------------------------------
# MOBY::RDF::Ontologies::ServiceTypes
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: ServiceTypes.pm,v 1.4 2008/09/02 13:12:46 kawas Exp $
#-----------------------------------------------------------------

package MOBY::RDF::Ontologies::ServiceTypes;

use RDF::Core;
use RDF::Core::Storage::Memory;
use RDF::Core::Model;
use RDF::Core::Literal;
use RDF::Core::Statement;
use RDF::Core::Model::Serializer;
use RDF::Core::NodeFactory;

use MOBY::Config;

use MOBY::RDF::Predicates::DC_PROTEGE;
use MOBY::RDF::Predicates::MOBY_PREDICATES;
use MOBY::RDF::Predicates::OMG_LSID;
use MOBY::RDF::Predicates::RDF;
use MOBY::RDF::Predicates::RDFS;

use MOBY::RDF::Utils;
use strict;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

#-----------------------------------------------------------------
# load all modules needed for my attributes
#-----------------------------------------------------------------


=head1 NAME

MOBY::RDF::Ontologies::ServiceTypes - Create RDF/OWL for Moby

=head1 SYNOPSIS

	use MOBY::RDF::Ontologies::ServiceTypes;
	# iustantiate
	my $x = MOBY::RDF::Ontologies::ServiceTypes->new;

	# get all ontology terms in unformatted XML
	print $x->createAll({ prettyPrint => 'no' });

	# get a specific ontology term in 'pretty print XML'
	print $x->createByName({term => 'Retrieval' });

=head1 DESCRIPTION

This module creates RDF XML for the Services ontology

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut



=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------
sub new {
    my ($class) = @_;

    # create an object
    my $self = bless {}, ref ($class) || $class;
    
    # save some information retrieved from mobycentral.config
    my $CONF  = MOBY::Config->new;
	$self->{uri}       = $CONF->{mobyservice}->{resourceURL} || 'http://biomoby.org/RESOURCES/MOBY-S/Services/';
	$self->{uri} = $self->{uri} . "/" unless $self->{uri} =~ m/^.*(\/{1})$/;
	
	$self->{query_all} = <<END;
SELECT ot1.service_type, rt.relationship_type, ot2.service_type, ot1.description, ot1.service_lsid, ot1.authority, ot1.contact_email, ot2.service_lsid 
FROM service as ot1, service_term2term as rt, service as ot2 
WHERE ot1.service_id = rt.service1_id and ot2.service_id = rt.service2_id order by ot1.service_type
END

	# done
	$self->{query} = <<END;
SELECT ot1.service_type, rt.relationship_type, ot2.service_type, ot1.description, ot1.service_lsid, ot1.authority, ot1.contact_email, ot2.service_lsid 
FROM service as ot1, service_term2term as rt, service as ot2 
WHERE ot1.service_id = rt.service1_id and ot2.service_id = rt.service2_id and ot1.service_type = ?
order by ot1.service_type
END

    # done
    return $self;
}


#-----------------------------------------------------------------
# createAll
#-----------------------------------------------------------------

=head2 createAll

Returns RDF XML for all nodes in the service type ontology as a pretty printed String of XML.
This routine consumes a hash as input with keys:
	prettyPrint: whether (yes) or not (no) to output formatted XML. Defaults to 'yes'.

=cut

sub createAll {
    my ($self, $hash) = @_;

	# set up an RDF model
	my $storage = new RDF::Core::Storage::Memory;
	my $model   = new RDF::Core::Model( Storage => $storage );

	my $prettyPrint = $hash->{prettyPrint} ? $hash->{prettyPrint} : 'yes';

	# add root of ontology
	{
		my $resource = new RDF::Core::Resource( $self->{uri}, "Service" );
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::RDFS->label ),
				new RDF::Core::Literal("Service")
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::RDFS->comment ),
				new RDF::Core::Literal(
"a base Service class, never instantiated"
				)
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->publisher ),
				new RDF::Core::Literal("openinformatics.com")
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->identifier ),
				new RDF::Core::Literal(
"urn:lsid:biomoby.org:servicetype:Service:2001-09-21T16-00-00Z"
				)
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->creator ),
				new RDF::Core::Literal("markw\@illuminae.com")
			)
		);
	}

	my $db = MOBY::Config->new()-> getDataAdaptor( source => "mobyservice" )->dbh;
	my $sth  = $db->prepare( $self->{query_all} );
	$sth->execute;

	# returns an array of hash references
	while ( my $ref = $sth->fetchrow_arrayref ) {
		my $subject      = $$ref[0];
		my $relationship = $$ref[1];
		my $object       = $$ref[2];
		my $description  = $$ref[3];
		my $lsid         = $$ref[4];
		my $authority    = $$ref[5];
		my $email        = $$ref[6];
		my $object_lsid  = $$ref[7];

		my $resource = new RDF::Core::Resource( $self->{uri}, $subject );
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::RDFS->label ),
				new RDF::Core::Literal($subject)
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::RDFS->comment ),
				new RDF::Core::Literal($description)
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->publisher ),
				new RDF::Core::Literal($authority)
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->identifier ),
				new RDF::Core::Literal($lsid)
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->creator ),
				new RDF::Core::Literal($email)
			)
		);

		# add subclassof, if applicable
		do {
			my $parent = new RDF::Core::Resource( $self->{uri}, $object );
			$model->addStmt(
				new RDF::Core::Statement(
					$resource,
					$resource->new( MOBY::RDF::Predicates::RDFS->subClassOf ),
					$parent
				)
			);
		} if $relationship =~ m/.*\:isa$/;
	}
	$sth->finish();
	$db->disconnect();

	my $xml        = '';
	my $serializer = new RDF::Core::Model::Serializer(
		Model   => $model,
		Output  => \$xml,
		BaseURI => 'URI://BASE/',
	);
	$serializer->serialize;
	return new MOBY::RDF::Utils->prettyPrintXML({xml => $xml}) unless $prettyPrint eq 'no';
	return $xml;

}

=head2 createByName

Returns RDF XML for a specific node in the Service Type ontology as a pretty printed String of XML.
This routine consumes a hash as input with keys:
	term: the node to retrieve B<required>
	prettyPrint: whether (yes) or not (no) to output formatted XML. Defaults to 'yes'.

=cut

sub createByName {
  my ( $self, $hash ) = @_;
	die "No term specified!" unless $hash && $hash->{term};

	# set up the term that we care about
	my $term = $hash->{term};
	my $prettyPrint = $hash->{prettyPrint} ? $hash->{prettyPrint} : 'yes';
	
	my $termExists = 0;
	$termExists++ if $term eq 'Service';

	# set up an RDF model
	my $storage = new RDF::Core::Storage::Memory;
	my $model   = new RDF::Core::Model( Storage => $storage );

	# add root of ontology
	{
		my $resource = new RDF::Core::Resource( $self->{uri}, "Service" );
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::RDFS->label ),
				new RDF::Core::Literal("Service")
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::RDFS->comment ),
				new RDF::Core::Literal(
"a base Service class, never instantiated"
				)
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->publisher ),
				new RDF::Core::Literal("openinformatics.com")
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->identifier ),
				new RDF::Core::Literal(
"urn:lsid:biomoby.org:servicetype:Service:2001-09-21T16-00-00Z"
				)
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->creator ),
				new RDF::Core::Literal("markw\@illuminae.com")
			)
		);
	}

	my $node_factory = new RDF::Core::NodeFactory();

	do {
		my $db = MOBY::Config->new()-> getDataAdaptor( source => "mobyservice" )->dbh;
		my $sth  = $db->prepare( $self->{query} );
		$sth->execute( ($term) );

		$term = '';

		#base case
		$term = '' if $term eq 'Service';

		# returns an array of hash references
		while ( my $ref = $sth->fetchrow_arrayref ) {
			$termExists++;
			my $subject      = $$ref[0];
			my $relationship = $$ref[1];
			my $object       = $$ref[2];
			my $description  = $$ref[3];
			my $lsid         = $$ref[4];
			my $authority    = $$ref[5];
			my $email        = $$ref[6];
			my $object_lsid  = $$ref[7];
			
			my $resource = new RDF::Core::Resource( $self->{uri}, $subject );
			$model->addStmt(
				new RDF::Core::Statement(
					$resource,
					$resource->new( MOBY::RDF::Predicates::RDFS->label ),
					new RDF::Core::Literal($subject)
				)
			);
			$model->addStmt(
				new RDF::Core::Statement(
					$resource,
					$resource->new( MOBY::RDF::Predicates::RDFS->comment ),
					new RDF::Core::Literal($description)
				)
			);
			$model->addStmt(
				new RDF::Core::Statement(
					$resource,
					$resource->new(
						MOBY::RDF::Predicates::DC_PROTEGE->publisher
					),
					new RDF::Core::Literal($authority)
				)
			);
			$model->addStmt(
				new RDF::Core::Statement(
					$resource,
					$resource->new(
						MOBY::RDF::Predicates::DC_PROTEGE->identifier
					),
					new RDF::Core::Literal($lsid)
				)
			);
			$model->addStmt(
				new RDF::Core::Statement(
					$resource,
					$resource->new(
						MOBY::RDF::Predicates::DC_PROTEGE->creator
					),
					new RDF::Core::Literal($email)
				)
			);

			# add subclassof, if applicable
			do {
				my $parent = new RDF::Core::Resource( $self->{uri}, $object );
				$model->addStmt(
					new RDF::Core::Statement(
						$resource,
						$resource->new(
							MOBY::RDF::Predicates::RDFS->subClassOf
						),
						$parent
					)
				);
				$term = $object;
			} if $relationship =~ m/.*\:isa$/;
		}
		$sth->finish();
		$db->disconnect();

	} while ( $term && $term ne '' );
	my $xml        = '';
	my $serializer = new RDF::Core::Model::Serializer(
		Model   => $model,
		Output  => \$xml,
		BaseURI => 'URI://BASE/',
	);
	$serializer->serialize;
	# dont output anything unless term exists!
	unless ( $termExists > 0 ) {
		$xml = <<END;
	<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"></rdf:RDF>
END
	}

	return new MOBY::RDF::Utils->prettyPrintXML({xml => $xml}) unless $prettyPrint eq 'no';
	return $xml;
}

1;
__END__
