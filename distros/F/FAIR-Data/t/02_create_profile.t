#!/usr/bin/perl

use strict;
use warnings;

use lib 't';
use lib 'lib';

use Test::Simple tests => 15;
use Log::Log4perl qw(:easy);
use RDF::Trine::Model 0.135;
use RDF::Trine::Parser 0.135;
use File::Spec::Functions;

Log::Log4perl->easy_init($WARN);


use FAIR::Profile;
use FAIR::Profile::Class;
use FAIR::Profile::Property;
use FAIR::NAMESPACES;

my %hash = (
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


ok ((my $P = FAIR::Profile->new(%hash)), "FAIR Profile core metadata created");

foreach my $key(keys %hash){
    ok ($P->$key eq $hash{$key}, "value of $key captured correctly");
}

delete $hash{'URI'};

ok (($P = FAIR::Profile->new(%hash)), "FAIR Profile core metadata created without an explicit URI");

ok ($P->URI, "Resulting Profile has a URI");
ok ($P->URI =~ /profileschemaprofile\/\S+/, "Resulting Profile has a URI that isn't empty");

ok ($P->type ~~ /FAIRProfile/, "Profile is a FAIR Profile");
ok ($P->type ~~ /ProvenanceStatement/, "Profile is a Dublin Core ProvenanceStatement");

