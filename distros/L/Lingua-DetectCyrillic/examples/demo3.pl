#!/usr/bin/perl -w
use Lingua::DetectCyrillic;

$CyrDetector = Lingua::DetectCyrillic ->new( MaxTokens => 100, DetectAllLang => 1 );
print "\n DETECTS CODING/LANGUAGE IN TEXT/HTML FILES IN CURRENT DIRECTORY \n";

print "-" x 70;
printf("\n%12s %-15s %5s\n", "File Name", "   Coding", "Language" );
print "-" x 70;
for ( <*.txt *.html> ) {
$FileName = $_;
my @Data;
open IN,"<$FileName " or die "Cannot open the file $FileName !";
  while ( <IN> ) { push @Data, $_ ;}
close IN;

my ($Coding,$Language,$CharsProcessed,$Algorithm)= $CyrDetector -> Detect( @Data );
printf("\n%12s %-15s %5s", $FileName, $Coding, $Language );
}
print "\n";    print "-" x 70;
print "\nREMARK. Test files of the package contain one Russian word - 'privet' ('hello')\n";
