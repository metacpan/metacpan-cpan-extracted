#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use lib 'lib';

use Test::Simple tests => 8;
use Log::Log4perl qw(:easy);
use RDF::Trine::Model 0.135;
use RDF::Trine::Parser 0.135;
use File::Spec::Functions;

Log::Log4perl->easy_init($WARN);


use FAIR::Profile;
use FAIR::Profile::Class;
use FAIR::Profile::Property;
use FAIR::NAMESPACES;

#
#has URI => (
#
#has type => (
#	default => sub {[FAIR.'FAIRClass']},
#	);
#
#has label => (
#
#has onClassType => (  # represents the OWL Class URI 

my %hash = (
    onClassType => "http://purl.obolibrary.org/obo/SO_0001023",  # allele
    URI => "http://example.com/#Class",
    label => "FAIR Class of some sort",
           );

ok ((my $C = FAIR::Profile::Class->new(%hash)), "FAIR Class Created");

foreach my $key(keys %hash){
    ok ($C->$key eq $hash{$key}, "value of $key captured correctly");
}

delete $hash{'URI'};

ok (($C = FAIR::Profile::Class->new(%hash)), "FAIR Class created without an explicit URI");

ok ($C->URI, "Resulting Class has a URI");
ok ($C->URI =~ /profileschemaclass\/\S+/, "Resulting Class has a URI that isn't empty");

ok ($C->type ~~ /FAIRClass/, "Profile is a FAIR Class");

