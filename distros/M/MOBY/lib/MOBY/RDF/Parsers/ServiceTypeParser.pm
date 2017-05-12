#-----------------------------------------------------------------
# MOBY::RDF::Parsers::ServiceTypeParser
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: ServiceTypeParser.pm,v 1.4 2008/11/25 18:05:44 kawas Exp $
#-----------------------------------------------------------------
package MOBY::RDF::Parsers::ServiceTypeParser;
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
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

ServiceTypeParser - An module for obtaining services from the RDF Service Type ontology 

=cut

=head1 SYNOPSIS

	use MOBY::RDF::Parsers::ServiceTypeParser;
	use Data::Dumper;

	# construct a parser for service types
	my $parser = MOBY::RDF::Parsers::ServiceTypeParser->new();

	# get all service types from a URL
	my $services_href = $parser->getNamespaces('http://biomoby.org/RESOURCES/MOBY-S/Services');

	# print out details regarding 'Analysis'
	print Dumper($services_href->{'Analysis'});

=cut

=head1 DESCRIPTION

This module contains the methods required to download and parse Service Type RDF into individual service types

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

=head2 new

Contructs a new ServiceTypeParser.

Input: none.

Example: 

	MOBY::RDF::Parsers::ServiceTypeParser->new()

=cut

sub new {
	my ($class) = @_;

	# create an object
	my $self = bless {}, ref($class) || $class;

	# done
	return $self;
}

=head2 getServiceTypes 

Downloads RDF from $url, parses it and returns a hashref of hash.
The key into the hashref is a service type name and the hash value
contains information on that service type.
The keys for the inner hash are:

	definintion
	authURI
	email
	lsid

Input: a scalar URL 

Example:

	my $parser = MOBY::RDF::Parsers::ServiceTypeParser->new();
	my $namespace_href = $parser->getServiceTypes('http://biomoby.org/RESOURCES/MOBY-S/Services');

=cut

sub getServiceTypes {

my ($self, $url) = @_;
my %hash; 
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
  my $servicetype = $statement->getSubject->getLocalValue;
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
  
  
  my $isa = $model->getObjects($statement->getSubject, new RDF::Core::Resource( MOBY::RDF::Predicates::RDFS->subClassOf ) );
  $isa = "" unless $$isa[0];
  $isa = $$isa[0]->getLocalValue if ref ($isa) eq 'ARRAY' and $$isa[0];
  
  $hash{$servicetype} = {
  	email 	   => $email,
  	authURI    => $authURI,
  	lsid	   => $lsid,
  	definition => $definition,
  	isa 	   => $isa,
  };
  $statement = $enumerator->getNext
}
$enumerator->close;

# return hash
return \%hash;

}

1;
__END__
