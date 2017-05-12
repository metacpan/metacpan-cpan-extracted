#!perl

use lib '../lib';

# turn off info for test
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init( $ERROR );

use File::Temp;
use MeSH::Parser::ASCII;
use Test::More tests => 7;

# create temp file from _DATA_ to get a proper filename
my $fh = File::Temp->new;
$fh->printflush(
	do { local $/; <DATA> }
);

# instantiate the parser
my $parser = MeSH::Parser::ASCII->new( meshfile => $fh->filename );
#my $parser = MeSH::Parser::ASCII->new( meshfile => 'd2010.bin' );
ok( $parser, 'Instantiated the parser' );

# parse the file
ok( $parser->parse(), 'Parsed the file' );

my $heading = $parser->heading->{'D000001'};
ok( defined $heading,             'Heading found' );
ok( defined $heading->{label},    'Has label' );
ok( defined $heading->{synonyms}, 'Has synonyms' );
ok( defined $heading->{parents}, 'Has parents' );

# test the code from synopsis
while ( my ( $id, $heading ) = each %{ $parser->heading } ) {
	print $id . ' - ' . $heading->{label} . "\n";
	for my $synonym ( @{ $heading->{synonyms} } ) {
		print "\t$synonym\n";
	}
	for my $parent ( @{ $heading->{parents} } ) {
		print "\t" . $parent->{label} . "\n";
	}
}
pass('SYNOPSIS');

__DATA__
*NEWRECORD
RECTYPE = D
MH = Calcimycin
AQ = AA AD AE AG AI AN BI BL CF CH CL CS CT DU EC HI IM IP ME PD PK PO RE SD ST TO TU UR
ENTRY = A-23187|T109|T195|LAB|NRW|NLM (1991)|900308|abbcdef
ENTRY = A23187|T109|T195|LAB|NRW|UNK (19XX)|741111|abbcdef
ENTRY = Antibiotic A23187|T109|T195|NON|NRW|NLM (1991)|900308|abbcdef
ENTRY = A 23187
ENTRY = A23187, Antibiotic
MN = D03.438.221.173
PA = Anti-Bacterial Agents
PA = Ionophores
MH_TH = NLM (1975)
ST = T109
ST = T195
N1 = 4-Benzoxazolecarboxylic acid, 5-(methylamino)-2-((3,9,11-trimethyl-8-(1-methyl-2-oxo-2-(1H-pyrrol-2-yl)ethyl)-1,7-dioxaspiro(5.5)undec-2-yl)methyl)-, (6S-(6alpha(2S*,3S*),8beta(R*),9beta,11alpha))-
RN = 52665-69-7
PI = Antibiotics (1973-1974)
PI = Carboxylic Acids (1973-1974)
MS = An ionophorous, polyether antibiotic from Streptomyces chartreusensis. It binds and transports cations across membranes and uncouples oxidative phosphorylation while inhibiting ATPase of rat liver mitochondria. The substance is used mostly as a biochemical tool to study the role of divalent cations in various biological systems.
OL = use CALCIMYCIN to search A 23187 1975-90
PM = 91; was A 23187 1975-90 (see under ANTIBIOTICS 1975-83)
HN = 91(75); was A 23187 1975-90 (see under ANTIBIOTICS 1975-83)
MED = *62
MED = 847
M90 = *299
M90 = 2405
M85 = *454
M85 = 2878
M80 = *316
M80 = 1601
M75 = *300
M75 = 823
M66 = *1
M66 = 3
M94 = *153
M94 = 1606
MR = 20060705
DA = 19741119
DC = 1
DX = 19840101
UI = D000001

*NEWRECORD
RECTYPE = D
MH = Benzoxazoles
AQ = AD AE AG AI AN BL CF CH CL CS CT DU EC HI IM IP ME PD PK PO RE SD ST TO TU UR
MN = D03.438.221
MH_TH = NLM (1966)
ST = T109
RN = 0
AN = includes benzoxazolines, benzoxazolidines
PM = 66
HN = 66
MED = *36
MED = 53
M90 = *52
M90 = 64
M85 = *64
M85 = 70
M80 = *79
M80 = 94
M75 = *57
M75 = 65
M66 = *76
M66 = 115
M94 = *55
M94 = 87
MR = 19920508
DA = 19990101
DC = 1
DX = 19660101
UI = D001583

