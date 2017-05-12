use lib "../lib/";
use FAIR::Profile::Parser;

die "\n\nusage:  testparser.pl  ProfileFileName.rdf\n\n" unless $ARGV[0];

my $parser = FAIR::Profile::Parser->new(filename => $ARGV[0]);
my $DatasetSchema = $parser->parse;


my $schema =  $DatasetSchema->serialize;
open(OUT, ">$ARGV[0]"."duplicate.rdf") or die "Can't open the output file to write the profile schema$!\n";
print OUT $schema;
close OUT;

