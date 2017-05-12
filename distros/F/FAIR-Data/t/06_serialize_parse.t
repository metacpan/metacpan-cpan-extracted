#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use lib 'lib';

use Test::Simple tests => 5;
use Log::Log4perl qw(:easy);
use RDF::Trine::Model 0.135;
use RDF::Trine::Parser 0.135;
use File::Spec::Functions;

Log::Log4perl->easy_init($WARN);


use FAIR::Profile;
use FAIR::Profile::Parser;

my %hashp = (
                label => 'FAIR Profile Allele',
		title => "FAIR Profile of Descriptive Allele records", 
		description => "FAIR Profile Allele record properties, using textual descriptions and links to Gene Records",
                license => "Anyone may use this freely",
                issued => "May 21, 2015",
                modified => "May 21, 2015",
    		organization => "wilkinsonlab.info",
		identifier => "doi:Mark.Dragon.P1",
                URI => "http://example.com/#Profile",
           );


my $P = FAIR::Profile->new(%hashp);

my %hashc = (
    onClassType => "http://purl.obolibrary.org/obo/SO_0001023",  # allele
    URI => "http://example.com/#Class",
    label => "FAIR Class of some sort",
           );

my $C = FAIR::Profile::Class->new(%hashc);


my %hashprop1 = (
    onPropertyType => "http://purl.obolibrary.org/obo/SO_0001023",  # allele
    URI => "http://example.com/#Property",
    label => "FAIR Property of some sort",
    minCount => 1,
    maxCount => 1,
           );

my %hashprop2 = (
    onPropertyType => "http://purl.obolibrary.org/obo/SO_0001024",  # allele
    URI => "http://example.com/#Property2",
    label => "another FAIR Property of some sort",
    minCount => 0,
    maxCount => 2,
           );

my $Prop = FAIR::Profile::Property->new(%hashprop1);
$C->add_Property($Prop);
my $Prop2 = FAIR::Profile::Property->new(%hashprop2);
$C->add_Property($Prop2);
$P->add_Class($C);

ok ($P->serialize, "Profile is capable of serializing");

ok ($P->serialize =~ /rdf:RDF/, "Profile serialized to RDF");

ok (my $parser = FAIR::Profile::Parser->new(data => $P->serialize(), data_format => 'rdfxml'), "Parser initialized correctly");

ok (my $Profile = $parser->parse(), "Parser ate its own dogfood...");

ok ($Profile->serialize('turtle') eq $P->serialize('turtle'), "and the data round-tripped with no changes");

