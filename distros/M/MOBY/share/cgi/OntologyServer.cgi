#!/usr/bin/perl -w

use CGI qw/:standard/;
use MOBY::OntologyServer;
use strict;

my $q = CGI->new();
my @params = $q->param;
my $subroutine = $params[0];  # one call per customer

no strict "refs";
&$subroutine($q->param($subroutine), $q);  #call that subroutie with the passed value
use strict;

sub testme {
    return "yes" if $_[0] eq "correct";
    return "no";
}

sub createObject{}
sub retrieveObject{}
sub deprecateObject{}
sub deleteObject{}
sub addObjectRelationship{}
sub addServiceRelationship{}
sub createServiceType{}
sub deleteServiceType{}
sub createNamespace{}
sub deleteNamespace{}
sub retrieveAllServiceTypes{}
sub retrieveAllNamespaceTypes{}
sub retrieveAllObjectClasses{}
sub getObjectCommonName{}
sub getNamespaceCommonName{}
sub getServiceCommonName{}
sub getServiceURI{}
sub getObjectURI{}
sub getNamespaceURI{}
sub getRelationshipURI{}
# this is inconsistent with the other calls
sub getRelationshipTypes{}
sub Relationships{}
#?? sub setURI{}


sub objectExists {

    my $OS = MOBY::OntologyServer->new(ontology => "object");
    my ($success, $description, $id) = $OS->objectExists(term => $_[0]);
    print header(-type => 'text/plain'), "$success\n$description\n$id";
    
}

sub namespaceExists {
    my $OS = MOBY::OntologyServer->new(ontology => "namespace");
    my ($success, $description, $id) = $OS->namespaceExists(term => $_[0]);
    print header(-type => 'text/plain'), "$success\n$description\n$id";
    
}

sub relationshipExists {
    my ($term, $CGI) = @_;
    my $OS = MOBY::OntologyServer->new(ontology => "relationship");
    my $ontology = $CGI->param('ontology');
    my ($success, $description, $id) = $OS->relationshipExists(ontology => $ontology, term => $term);
    print header(-type => 'text/plain'), "$success\n$description\n$id";    
}

sub serviceExists {
    my $OS = MOBY::OntologyServer->new(ontology => "service");
    my ($success, $description, $id) = $OS->serviceExists(term => $_[0]);
    print header(-type => 'text/plain'), "$success\n$description\n$id";
    
}
