#!perl -w
use lib "./t";
use strict;
use ExtUtils::TBone;
my ($Coding,$Language,$CharsProcessed,$Algorithm,$CyrDetector);
my $T = typical ExtUtils::TBone;
$T->begin(3);
$T->msg(" DETECTION TEST\n");
# Test 1. Using the package
use Lingua::DetectCyrillic qw ( &toLowerCyr &toUpperCyr &TranslateCyr %RusCharset );
$T->msg("Using the package - OK");
my $TestString="This is test";
# Test 2. Construct the main class
$T->ok( $CyrDetector = Lingua::DetectCyrillic ->new( MaxTokens => 100, DetectAllLang => 1 ), "Constructing the class");
# Test 3. Detect codings
$T->ok( (($Coding,$Language,$CharsProcessed,$Algorithm)= $CyrDetector->Detect($TestString)),
      Language => $Language,
      Coding => $Coding,
      CharsProcessed => $CharsProcessed,
      Algorithm => $Algorithm
      );
# Test 4. Writing a report
$T->ok($CyrDetector -> LogWrite("./testout/report.txt"), "Writing a report\n");
$T->end;
