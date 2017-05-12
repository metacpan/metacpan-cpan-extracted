#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use lib 'lib';

use Test::Simple tests => 7;
use Log::Log4perl qw(:easy);
use RDF::Trine::Model 0.135;
use RDF::Trine::Parser 0.135;
use File::Spec::Functions;

Log::Log4perl->easy_init($WARN);


use FAIR::Profile;
use FAIR::Profile::Class;
use FAIR::Profile::Property;
use FAIR::NAMESPACES;

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


my %hashprop = (
    onPropertyType => "http://purl.obolibrary.org/obo/SO_0001023",  # allele
    URI => "http://example.com/#Property",
    label => "FAIR Property of some sort",
    minCount => 1,
    maxCount => 1,
           );

my $Prop = FAIR::Profile::Property->new(%hashprop);

ok ($C->add_Property($Prop), "FAIR Class allows adding a property");
ok (ref($C->hasProperty()) eq "ARRAY", "hasProperty returns arrayref");

ok ($C->add_Property($Prop), "FAIR Class allows adding another property");
my $properties = $C->hasProperty();
ok (scalar(@$properties) == 2, "hasProperties returns all properties");


ok ($P->add_Class($C), "FAIR Profie allows adding a Class");

ok (my $Class = $P->hasClass(), "Profile returns its class");

ok (($Class->URI eq $C->URI), "Class seems to be relatively intact");
