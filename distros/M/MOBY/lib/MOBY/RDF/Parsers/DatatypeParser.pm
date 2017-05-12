#-----------------------------------------------------------------
# MOBY::RDF::Parsers::DatatypeParser
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: DatatypeParser.pm,v 1.3 2008/11/25 18:05:44 kawas Exp $
#-----------------------------------------------------------------
package MOBY::RDF::Parsers::DatatypeParser;
use strict;

# imports
use RDF::Core::Model::Parser;
use RDF::Core::Model;
use RDF::Core::Storage::Memory;
use RDF::Core::Resource;

use MOBY::RDF::Utils;
use MOBY::RDF::Predicates::DC_PROTEGE;
use MOBY::RDF::Predicates::MOBY_PREDICATES;
use MOBY::RDF::Predicates::OMG_LSID;
use MOBY::RDF::Predicates::RDF;
use MOBY::RDF::Predicates::RDFS;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

DatatypeParser - An module for obtaining datatypes from the RDF Namespace ontology 

=cut

=head1 SYNOPSIS

	use MOBY::RDF::Parsers::DatatypeParser;
	use Data::Dumper;

	# construct a parser for datatypes
	my $parser = MOBY::RDF::Parsers::DatatypeParser->new();

	# get all datatypes from a URL
	my $namespace_href = $parser->getDatatypes('http://biomoby.org/RESOURCES/MOBY-S/Objects');

	# print out details regarding 'BasicGFFSequenceFeature'
	print Dumper( $datatype_href->{'BasicGFFSequenceFeature'} );

=cut

=head1 DESCRIPTION

This module contains the methods required to download and parse Namespace RDF into individual datatypes

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

=head2 new

Contructs a new DatatypeParser.

Input: none.

Example: 

	MOBY::RDF::Parsers::DatatypeParser->new()

=cut

sub new {
	my ($class) = @_;

	# create an object
	my $self = bless {}, ref($class) || $class;

	# done
	return $self;
}

=head2 getDatatypes 

Downloads RDF from $url, parses it and returns a hashref of hashes.

The key into the hashref is a datatype name and the hash value
contains information on that datatype.

The keys for the inner hash are:

   objectLSID => "urn:lsid:..."
   description => "a human-readable description of the object"
   contactEmail => "your@email.address"
   authURI => "URI of the registrar of this object"
   Relationships => {
    	relationshipType1 => [
    		{
    			object      => Object1,
    			articleName => ArticleName1, 
    			lsid        => lsid1
    		},
    		{
    			object      => Object2,
    			articleName => ArticleName2,
    			lsid        => lsid2
    		}
    	],
	    relationshipType2 => [
	    	{
	    		object      => Object3,
	    		articleName => ArticleName3, 
	    		lsid        => lsid3
	    	}
	    ]
    }

The returned hashref is the same structure as the one returned by B<MOBY::Client::Central-E<gt>retrieveObjectDefinition>

Input: a scalar URL 

Example:

	my $parser = MOBY::RDF::Parsers::DatatypeParser->new();
	my $datatype_href = $parser->getDatatypes('http://biomoby.org/RESOURCES/MOBY-S/Objects');

=cut

sub getDatatypes {

my ($self, $url) = @_;
my %hash = ();
return \%hash unless $url;

# download string from url
my $rdf = undef;

# 'try/catch'
eval {
	$rdf = MOBY::RDF::Utils->new()->getHttpRequestByURL($url);
};
return \%hash unless $rdf;

# create RDF model and populate
my $storage = new RDF::Core::Storage::Memory;
my $model = new RDF::Core::Model (Storage => $storage);
my %options = (Model => $model,
              Source => $rdf,
              SourceType => 'string',
              BaseURI => "$url",
             );
my $parser = new RDF::Core::Model::Parser(%options);
$parser->parse;

# get information from the model
my $enumerator = $model->getStmts(undef, new RDF::Core::Resource( MOBY::RDF::Predicates::DC_PROTEGE->publisher ), undef);
my $statement = $enumerator->getFirst;
while (defined $statement) {
  my $datatype = $statement->getSubject->getLocalValue;
  my $authURI = $statement->getObject->getValue;
  
  my $definition = $model->getObjects($statement->getSubject, new RDF::Core::Resource( MOBY::RDF::Predicates::RDFS->comment ) );
  $definition = "" unless $$definition[0];
  $definition =  $$definition[0]->getValue if ref ($definition) eq 'ARRAY' and $$definition[0];
  
  my $email = $model->getObjects($statement->getSubject, new RDF::Core::Resource( MOBY::RDF::Predicates::DC_PROTEGE->creator ) );
  $email = "" unless $$email[0];
  $email = $$email[0]->getValue if ref ($email) eq 'ARRAY' and $$email[0];
  
  my $lsid = $model->getObjects($statement->getSubject, new RDF::Core::Resource( MOBY::RDF::Predicates::DC_PROTEGE->identifier ) );
  $lsid = "" unless $$lsid[0];
  $lsid = $$lsid[0]->getValue if ref ($lsid) eq 'ARRAY' and $$lsid[0];

  #process relationships
  my $isa = undef;
  do {
	  $isa = $model->getObjects($statement->getSubject, new RDF::Core::Resource( MOBY::RDF::Predicates::RDFS->subClassOf ) );
	  $isa = "" unless $$isa[0];
	  $isa =  $$isa[0]->getLocalValue if ref ($isa) eq 'ARRAY' and $$isa[0];
  } unless $datatype eq 'Object';
  
  
  $hash{$datatype} = {
  	contactEmail => $email,
  	authURI => $authURI,
  	objectLSID => $lsid,
  	description => $definition,	
  };
  push @ {$hash{$datatype}{Relationships}{ISA}},  {object => $isa, lsid =>'', articleName =>''} if $isa;
  
  #process has relationships
  my $has = $model->getObjects($statement->getSubject, new RDF::Core::Resource( MOBY::RDF::Predicates::MOBY_PREDICATES->has ) );
  if ($has and ref ($has) eq 'ARRAY') {
  	for my $resource (@{$has}) {
  		my $type = $model->getObjects($resource, new RDF::Core::Resource( MOBY::RDF::Predicates::RDF->type ) );
  		$type = "" unless $$type[0];
  		$type=  $$type[0]->getLocalValue if ref ($type) eq 'ARRAY' and $$type[0];
  		
  		my $name = $model->getObjects($resource, new RDF::Core::Resource( MOBY::RDF::Predicates::MOBY_PREDICATES->articleName ) );
  		$name = "" unless $$name[0];
  		$name=  $$name[0]->getValue if ref ($name) eq 'ARRAY' and $$name[0];
  		push @ {$hash{$datatype}{Relationships}{HAS}},  {object => $type, lsid =>'', articleName =>$name};
  	}
  }
  
  #process hasa relationships
  my $hasa = $model->getObjects($statement->getSubject, new RDF::Core::Resource( MOBY::RDF::Predicates::MOBY_PREDICATES->hasa ) );
  if ($hasa and ref ($hasa) eq 'ARRAY') {
  	for my $resource (@{$hasa}) {
  		my $type = $model->getObjects($resource, new RDF::Core::Resource( MOBY::RDF::Predicates::RDF->type ) );
  		$type = "" unless $$type[0];
  		$type=  $$type[0]->getLocalValue if ref ($type) eq 'ARRAY' and $$type[0];
  		
  		my $name = $model->getObjects($resource, new RDF::Core::Resource( MOBY::RDF::Predicates::MOBY_PREDICATES->articleName ) );
  		$name = "" unless $$name[0];
  		$name=  $$name[0]->getValue if ref ($name) eq 'ARRAY' and $$name[0];		
  		push @ {$hash{$datatype}{Relationships}{HASA}},  {object => $type, lsid =>'', articleName =>$name};
  	}
  }
  
  $statement = $enumerator->getNext;
}
$enumerator->close;

# return hash
return \%hash;

}

1;
__END__
