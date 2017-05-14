#!perl


use lib  'C:/Users/emma.EBI/Fuzzy/cpan-distribution/FuzzyRecogniser/lib';

use Test::More tests => 2;

use EBI::FGPT::FuzzyRecogniser;

# turn off info for test
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $WARN );

# create temp file from _DATA_ to get a proper filename
my $fh = File::Temp->new;
$fh->printflush(
				 do { local $/; <DATA> }
);

my $fuzzy = EBI::FGPT::FuzzyRecogniser->new( obofile => $fh->filename );    # create an object
ok( defined $fuzzy, 'new() returned something' );    # check that we got something
ok( $fuzzy->isa('EBI::FGPT::FuzzyRecogniser'), "  and it's the right class" )
  ;                                                  # and it's the right class



__DATA__
format-version: 1.2
data-version: 2.15classified
date: 05:08:2011 16:37
auto-generated-by: OWL::Simple::OBOWriter 0.06
default-namespace: efo

[Term]
id: EFO:0000001 ! experimental factor
name: experimental factor
def: "An experimental factor in Array Express which are essentially the variable aspects of an experiment design which can be used to describe an experiment  or set of experiments, in an increasingly detailed manner." []
synonym: "ExperimentalFactor" EXACT []
xref: MO:10

[Term]
id: EFO:0000002 ! CS57511
name: CS57511
def: "CS57511 is an Arabidopsis thaliana strain as described in TAIR http://www.arabidopsis.org/servlets/TairObject?type=stock&id=1000311932." []
xref: http://www.arabidopsis.org/servlets/TairObject?type=stock&id=1000311932
is_a: NCBITaxon:3702

[Term]
id: EFO:0000003 ! CS57512
name: CS57512
def: "CS57512 is an Arabidopsis thaliana strain as described in TAIR http://www.arabidopsis.org/servlets/TairObject?type=stock&id=1000311933" []
xref: http://www.arabidopsis.org/servlets/TairObject?type=stock&id=1000311933
is_a: NCBITaxon:3702

[Term]
id: EFO:0000004 ! CS57515
name: CS57515
def: "CS57515 is an Arabidopsis thaliana strain as described in TAIR http://www.arabidopsis.org/servlets/TairObject?type=stock&id=1000311936" []
xref: http://www.arabidopsis.org/servlets/TairObject?type=stock&id=1000311936
is_a: NCBITaxon:3702

[Term]
id: EFO:0000005 ! CS57520
name: CS57520
def: "CS57520 is an Arabidopsis thaliana strain as described in TAIR http://www.arabidopsis.org/servlets/TairObject?type=stock&id=1000311941" []
xref: http://www.arabidopsis.org/servlets/TairObject?type=stock&id=1000311941
is_a: NCBITaxon:3702
