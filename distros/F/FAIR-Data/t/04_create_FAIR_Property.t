#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use lib 'lib';

use Test::Simple tests => 13;
use Log::Log4perl qw(:easy);
use RDF::Trine::Model 0.135;
use RDF::Trine::Parser 0.135;
use File::Spec::Functions;

Log::Log4perl->easy_init($WARN);


use FAIR::Profile;
use FAIR::Profile::Class;
use FAIR::Profile::Property;
use FAIR::NAMESPACES;


#has label => (
#
#has onPropertyType => (
#
#has allowedValues => (
#
#has minCount => (
#
#has maxCount => (
#
#has type => (
#	default => sub {[FAIR.'FAIRProperty']},
#	);
#
#has URI => (


my %hash = (
    onPropertyType => "http://purl.obolibrary.org/obo/SO_0001023",  # allele
    URI => "http://example.com/#Property",
    label => "FAIR Property of some sort",
    minCount => 1,
    maxCount => 1,
           );

ok (my $P = FAIR::Profile::Property->new(%hash), "Success in creating FAIR Property");

foreach my $key(keys %hash){
    ok ($P->$key eq $hash{$key}, "value of $key captured correctly");
}
delete $hash{'URI'};

ok (($P = FAIR::Profile::Property->new(%hash)), "FAIR Property created without an explicit URI");

ok ($P->URI, "Resulting Property has a URI");

ok ($P->URI =~ /profileschemaproperty\/\S+/, "Resulting Property has a URI that isn't empty");

ok ($P->type ~~ /FAIRProperty/, "Property is a FAIR Property");

my $value = "http://biordf.org/DataFairPort/ConceptSchemes/xsdstring";

ok ($P->add_AllowedValue($value), "Called add_AllowedValue");

ok (ref($P->allowedValues) eq "ARRAY", "allowedValues returns arrayref");

my $values = $P->allowedValues();

ok ($values->[0] eq $value, "allowedValues captured the allowed value $value");




