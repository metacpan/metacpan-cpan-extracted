#-----------------------------------------------------------------
# MOBY::RDF::Ontologies::Namespaces
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: Namespaces.pm,v 1.7 2008/09/02 13:12:46 kawas Exp $
#-----------------------------------------------------------------

package MOBY::RDF::Ontologies::Namespaces;

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
$VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /: (\d+)\.(\d+)/;

#-----------------------------------------------------------------
# load all modules needed for my attributes
#-----------------------------------------------------------------

=head1 NAME

MOBY::RDF::Ontologies::Namespaces - Create RDF/OWL for Moby

=head1 SYNOPSIS

	use MOBY::RDF::Ontologies::Namespaces;
	# iustantiate
	my $x = MOBY::RDF::Ontologies::Namespaces->new;

	# get all ontology terms in unformatted XML
	print $x->createAll({ prettyPrint => 'no' });

	# get a specific ontology term in 'pretty print XML'
	print $x->createByName({term => 'NCBI_gi' });

=head1 DESCRIPTION

This module creates RDF XML for the Namespace ontology

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
sub new {
	my ($class) = @_;

	# create an object
	my $self = bless {}, ref($class) || $class;
	
	# save some information retrieved from mobycentral.config
    my $CONF  = MOBY::Config->new;
	$self->{uri}       = $CONF->{mobynamespace}->{resourceURL} || 'http://biomoby.org/RESOURCES/MOBY-S/Namespaces#';
	$self->{uri} = $self->{uri} . "#" unless $self->{uri} =~ m/^.*(\#{1})$/;

	$self->{query_all} = <<END;
SELECT namespace_type, description, namespace_lsid, authority, contact_email FROM namespace ORDER BY namespace_type asc
END

	# done
	$self->{query} = <<END;
SELECT namespace_type, description, namespace_lsid, authority, contact_email 
FROM namespace 
WHERE namespace_type = ?
ORDER BY namespace_type asc
END

	# done
	return $self;
}

#-----------------------------------------------------------------
# createAll
#-----------------------------------------------------------------

=head2 createAll

Returns RDF XML for all nodes in the Namespace ontology as a pretty printed String of XML.
This routine consumes a hash as input with keys:
	prettyPrint: whether (yes) or not (no) to output formatted XML. Defaults to 'yes'.

=cut

sub createAll {
	my ($self, $hash) = @_;
	
	my $prettyPrint = $hash->{prettyPrint} ? $hash->{prettyPrint} : 'yes';
	
	# set up an RDF model
	my $storage = new RDF::Core::Storage::Memory;
	my $model   = new RDF::Core::Model( Storage => $storage );

	# add root of ontology
	{
		my $resource = new RDF::Core::Resource( $self->{uri}, "Namespace" );
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::RDFS->label ),
				new RDF::Core::Literal("Namespace")
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::RDFS->comment ),
				new RDF::Core::Literal(
					"a base namespace identifier, never instantiated"
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
					"urn:lsid:biomoby.org:namespacetype:Namespace"
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

	my $db = MOBY::Config->new()-> getDataAdaptor( source => "mobynamespace" )->dbh;
	my $sth  = $db->prepare( $self->{query_all} );
	$sth->execute;

	# returns an array of hash references
	while ( my $ref = $sth->fetchrow_arrayref ) {
		my $subject     = $$ref[0];
		my $description = $$ref[1];
		my $lsid        = $$ref[2];
		my $authority   = $$ref[3];
		my $email       = $$ref[4];

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

		my $parent = new RDF::Core::Resource( $self->{uri}, 'Namespace' );
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::RDFS->subClassOf ),
				$parent
			)
		);

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
	return new MOBY::RDF::Utils->prettyPrintXML( { xml => $xml } ) unless $prettyPrint eq 'no';
	return $xml;

}

=head2 createByName

Returns RDF XML for a specific node in the Namespace ontology as a pretty printed String of XML.
This routine consumes a hash as input with keys:
	term: the node to retrieve B<required>
	prettyPrint: whether (yes) or not (no) to output formatted XML. Defaults to 'yes'.

=cut

sub createByName {
	my ( $self, $hash ) = @_;
	die "No term specified!" unless $hash->{term};

	# set up the term that we care about
	my $term = $hash->{term};
	my $prettyPrint = $hash->{prettyPrint} ? $hash->{prettyPrint} : 'yes';
	
	my $termExists = 0;
	#special case where term == Namespace
	$termExists = $termExists + 1 if $term eq 'Namespace';
	
	# set up an RDF model
	my $storage = new RDF::Core::Storage::Memory;
	my $model   = new RDF::Core::Model( Storage => $storage );

	# add root of ontology
	{
		my $resource = new RDF::Core::Resource( $self->{uri}, "Namespace" );
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::RDFS->label ),
				new RDF::Core::Literal("Namespace")
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::RDFS->comment ),
				new RDF::Core::Literal(
					"a base namespace identifier, never instantiated"
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
					"urn:lsid:biomoby.org:namespacetype:Namespace"
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
		my $db = MOBY::Config->new()-> getDataAdaptor( source => "mobynamespace" )->dbh;
		my $sth  = $db->prepare( $self->{query} );
		$sth->execute( ($term) );

		$term = '';

		#base case
		$term = '' if $term eq 'Namespace';
		# returns an array of hash references
		while ( my $ref = $sth->fetchrow_arrayref ) {
			$termExists++;
			my $subject     = $$ref[0];
			my $description = $$ref[1];
			my $lsid        = $$ref[2];
			my $authority   = $$ref[3];
			my $email       = $$ref[4];

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

			# add subclassof,
			my $parent = new RDF::Core::Resource( $self->{uri}, 'Namespace' );
			$model->addStmt(
				new RDF::Core::Statement(
					$resource,
					$resource->new( MOBY::RDF::Predicates::RDFS->subClassOf ),
					$parent
				)
			);
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
	
	return new MOBY::RDF::Utils->prettyPrintXML( { xml => $xml } ) unless $prettyPrint eq 'no';
	return $xml;
}

1;
__END__
