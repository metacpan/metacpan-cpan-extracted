#-----------------------------------------------------------------
# MOBY::RDF::Ontologies::Objects
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: Objects.pm,v 1.5 2008/09/02 13:12:46 kawas Exp $
#-----------------------------------------------------------------

package MOBY::RDF::Ontologies::Objects;

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

use MIME::Base64;
use CGI;
use strict;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

#-----------------------------------------------------------------
# load all modules needed for my attributes
#-----------------------------------------------------------------

=head1 NAME

MOBY::RDF::Ontologies::Objects - Create RDF/OWL for Moby datatypes

=head1 SYNOPSIS

	use MOBY::RDF::Ontologies::Objects;
	my $x = MOBY::RDF::Ontologies::Objects->new;

	# get RDF for all datatypes in unformatted XML
	my $rdf_all = $x->createAll({ prettyPrint => 'no' });

	# get RDF for a specific datatype as formatted XML
	my $rdf = $x->createByName( { term => 'DNASequence' });

=head1 DESCRIPTION

This module creates RDF/XML for the Objects ontology.

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
	$self->{uri}       = $CONF->{mobyobject}->{resourceURL} || 'http://biomoby.org/RESOURCES/MOBY-S/Objects/';
	$self->{uri} = $self->{uri} . "/" unless $self->{uri} =~ m/^.*(\/{1})$/;
	
	$self->{uri_comp} = $self->{uri};
	$self->{uri_comp} =~ s/\/MOBY\-S\//\/MOBY_SUB_COMPONENT\//;

	$self->{query_all} = <<END;
SELECT ot1.object_type, rt.relationship_type, ot2.object_type, rt.object2_articlename, ot1.description, ot1.object_lsid, ot1.authority, ot1.contact_email 
FROM object as ot1, object_term2term as rt, object as ot2 
WHERE  ot1.object_id = rt.object1_id and ot2.object_id = rt.object2_id 
ORDER BY ot1.object_type
END

	# done
	$self->{query} = <<END;
SELECT ot1.object_type, rt.relationship_type, ot2.object_type, rt.object2_articlename, ot1.description, ot1.object_lsid, ot1.authority, ot1.contact_email 
FROM object as ot1, object_term2term as rt, object as ot2 
WHERE  ot1.object_id = rt.object1_id and ot2.object_id = rt.object2_id and ot1.object_type = ?
ORDER BY ot1.object_type
END

	# done
	return $self;
}

#-----------------------------------------------------------------
# createAll
#-----------------------------------------------------------------

=head2 createAll

Return a string of RDF in XML that represents all of the 
datatypes in the objects ontology.

 This routine consumes a hash as input with keys:
	prettyPrint: whether (yes) or not (no) to output 'pretty print' formatted XML. Defaults to 'yes'.

=cut

sub createAll {
	my ( $self, $hash ) = @_;

	# set up an RDF model
	my $storage = new RDF::Core::Storage::Memory;
	my $model   = new RDF::Core::Model( Storage => $storage );

	my $prettyPrint = $hash->{prettyPrint} ? $hash->{prettyPrint} : 'yes';

	# add root of ontology
	$self->_addOntologyRoot($model);

	my $db = MOBY::Config->new()-> getDataAdaptor( source => "mobyobject" )->dbh;
	my $sth  = $db->prepare( $self->{query_all} );
	$sth->execute;

	# returns an array of hash references
	while ( my $ref = $sth->fetchrow_arrayref ) {
		my $subject      = $$ref[0];
		my $relationship = $$ref[1];
		my $object       = $$ref[2];
		my $articlename  = $$ref[3] || '';
		my $description  = $$ref[4];
		my $lsid         = $$ref[5];
		my $authority    = $$ref[6];
		my $email        = $$ref[7];

		my $resource = new RDF::Core::Resource( $self->{uri}, $subject );
		$self->_processDatatype(
			$model,     $resource,    $subject,     $relationship,
			$object,    $articlename, $description, $lsid,
			$authority, $email
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
	return new MOBY::RDF::Utils->prettyPrintXML( { xml => $xml } )
	  unless $prettyPrint eq 'no';
	return $xml;
}

=head2 createByName

Return a string of RDF in XML that represents a specific datatype in the
 Objects ontology. This sub routine takes one argument, 'term', 
 that represents the ontology term that you would like to create RDF
 for. For example, the term 'DNASequence' would return RDF describing
 DNASequence and all of its parents and container relationships. 

 This routine consumes a hash as input with keys:
	term: the node to retrieve B<required>
	prettyPrint: whether (yes) or not (no) to output 'pretty print' formatted XML. Defaults to 'yes'.

=cut

sub createByName {
	my ( $self, $hash ) = @_;
	die "No term specified!" unless $hash->{term};

	# set up the term that we care about
	my $term        = $hash->{term};
	my $prettyPrint = $hash->{prettyPrint} ? $hash->{prettyPrint} : 'yes';

	my $termExists = 0;
	
	$termExists++ if $term eq "Object";

	# set up an RDF model
	my $storage = new RDF::Core::Storage::Memory;
	my $model   = new RDF::Core::Model( Storage => $storage );

	# add root of ontology
	$self->_addOntologyRoot($model);
	my $node_factory = new RDF::Core::NodeFactory();

	do {
		my $db = MOBY::Config->new()-> getDataAdaptor( source => "mobyobject" )->dbh;
		my $sth  = $db->prepare( $self->{query} );
		$sth->execute( ($term) );

# this line is here, because there are some datatypes in the ontology not rooted at 'Object' and while illegal, this would kill this code.
		$term = '';

		#base case
		$term = '' if $term eq 'Object';

		# returns an array of hash references
		while ( my $ref = $sth->fetchrow_arrayref ) {
			$termExists++;
			my $subject      = $$ref[0];
			my $relationship = $$ref[1];
			my $object       = $$ref[2];
			my $articlename  = $$ref[3] || '';
			my $description  = $$ref[4];
			my $lsid         = $$ref[5];
			my $authority    = $$ref[6];
			my $email        = $$ref[7];
			my $resource = new RDF::Core::Resource( $self->{uri}, $subject );
			$self->_processDatatype(
				$model,     $resource,    $subject,     $relationship,
				$object,    $articlename, $description, $lsid,
				$authority, $email
			);
			do {
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
	return new MOBY::RDF::Utils->prettyPrintXML( { xml => $xml } )
	  unless $prettyPrint eq 'no';
	return $xml;
}


#####-----------------------Private Routines--------------------------#####

sub _addOntologyRoot {
	my ( $self, $model ) = @_;
	my $resource = new RDF::Core::Resource( $self->{uri}, "Object" );

	#		$model->addStmt(
	#			new RDF::Core::Statement(
	#				$resource,
	#				$resource->new( MOBY::RDF::Predicates::RDF->type ),
	#				new RDF::Core::Resource( MOBY::RDF::Predicates::OWL->Class )
	#			)
	#		);
	$model->addStmt(
		new RDF::Core::Statement(
			$resource,
			$resource->new( MOBY::RDF::Predicates::RDFS->label ),
			new RDF::Core::Literal("Object")
		)
	);
	$model->addStmt(
		new RDF::Core::Statement(
			$resource,
			$resource->new( MOBY::RDF::Predicates::RDFS->comment ),
			new RDF::Core::Literal(
"a base object class consisting of a namespace and an identifier"
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
				"urn:lsid:biomoby.org:objectclass:Object:2001-09-21T16-00-00Z"
			)
		)
	);
	$model->addStmt(
		new RDF::Core::Statement(
			$resource,
			$resource->new( MOBY::RDF::Predicates::DC_PROTEGE->creator ),
			new RDF::Core::Literal("jason\@openinformatics.com")
		)
	);

}

sub _processDatatype {

	my (
		$self,         $model,     $resource,    $subject,
		$relationship, $object,    $articlename, $description,
		$lsid,         $authority, $email
	  )
	  = @_;

	#		$model->addStmt(
	#			new RDF::Core::Statement(
	#				$resource,
	#				$resource->new( MOBY::RDF::Predicates::RDF->type ),
	#				new RDF::Core::Resource( MOBY::RDF::Predicates::OWL->Class )
	#			)
	#		);
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

	# add hasa container relationships
	do {
		my $container =
		  new RDF::Core::Resource( $self->{uri_comp},
			$subject . "_" . CGI::escape(encode_base64("$articlename")) );
		$model->addStmt(
			new RDF::Core::Statement(
				$container,
				$container->new( MOBY::RDF::Predicates::RDF->type ),
				new RDF::Core::Resource( $self->{uri}, $object )
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::MOBY_PREDICATES->hasa ),
				$container
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$container,
				$container->new(
					MOBY::RDF::Predicates::MOBY_PREDICATES->articleName
				),
				new RDF::Core::Literal($articlename)
			)
		);
		$self->_processISAs( $model, $object );

	} if $relationship =~ m/.*\:hasa$/;

	# add has container relationship
	do {
		my $container =
		  new RDF::Core::Resource( $self->{uri_comp},
			$subject . "_" .  CGI::escape (encode_base64("$articlename")));
		$model->addStmt(
			new RDF::Core::Statement(
				$container,
				$container->new( MOBY::RDF::Predicates::RDF->type ),
				new RDF::Core::Resource( $self->{uri}, $object )
			)
		);

		$model->addStmt(
			new RDF::Core::Statement(
				$resource,
				$resource->new( MOBY::RDF::Predicates::MOBY_PREDICATES->has ),
				$container
			)
		);
		$model->addStmt(
			new RDF::Core::Statement(
				$container,
				$container->new(
					MOBY::RDF::Predicates::MOBY_PREDICATES->articleName
				),
				new RDF::Core::Literal($articlename)
			)
		);
		$self->_processISAs( $model, $object );

	} if $relationship =~ m/.*\:has$/;
}

sub _processISAs {
	my ( $self, $model, $term ) = @_;

	my $termExists = 0;
	
	
	do {
		my $db = MOBY::Config->new()-> getDataAdaptor( source => "mobyobject" )->dbh;
		my $sth  = $db->prepare( $self->{query} );
		$sth->execute( ($term) );

# this line is here, because there are some datatypes in the ontology not rooted at 'Object' and while illegal, this would kill this code.
		$term = '';

		#base case
		$term = '' if $term eq 'Object';

		# returns an array of hash references
		while ( my $ref = $sth->fetchrow_arrayref ) {
			$termExists++;
			my $subject      = $$ref[0];
			my $relationship = $$ref[1];
			my $object       = $$ref[2];
			my $articlename  = $$ref[3] || '';
			my $description  = $$ref[4];
			my $lsid         = $$ref[5];
			my $authority    = $$ref[6];
			my $email        = $$ref[7];
			my $resource = new RDF::Core::Resource( $self->{uri}, $subject );
			$self->_processDatatype(
				$model,     $resource,    $subject,     $relationship,
				$object,    $articlename, $description, $lsid,
				$authority, $email
			);
			do {
				$term = $object;
			} if $relationship =~ m/.*\:isa$/;

		}
		$sth->finish();
		$db->disconnect();

	} while ( $term && $term ne '' );
}

1;
__END__
