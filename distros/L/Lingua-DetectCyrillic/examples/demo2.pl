#!/usr/bin/perl
use Lingua::DetectCyrillic qw ( &toLowerCyr &toUpperCyr &TranslateCyr %RusCharset );

print "** CONVERTS ONE LINE OF CYRILLIC CHARACTERS TO ALL POSSIBLE CODINGS **\n";
print "Input one line and press Enter: \n";
while (<>){  chomp; last; }
if ( !length() ) { print "You haven't entered a single character! Sorry...\n"; exit; }

$CyrDetector = Lingua::DetectCyrillic ->new( MaxTokens => 100, DetectAllLang => 1 );
my ($Coding,$Language,$CharsProcessed,$Algorithm)= $CyrDetector -> Detect( $_ );
print "
I processed *$CharsProcessed* characters and detected: \n
coding - *$Coding* and language - *$Language*
--------------------------------------------------
Now printing your text in all available codings: \n";
print "windows-1251:   " .TranslateCyr($Coding,"windows-1251",$_) ."\n";
print "koi8-r:         " .TranslateCyr($Coding,"koi8-r",$_) ."\n";
print "koi8-u:         " .TranslateCyr($Coding,"koi8-u",$_) ."\n";
print "utf-8:          " .TranslateCyr($Coding,"utf-8",$_) ."\n";
print "cp866:          " .TranslateCyr($Coding,"cp866",$_) ."\n";
print "iso-8859-5:     " .TranslateCyr($Coding,"iso-8859-5",$_) ."\n";
print "x-mac-cyrillic: " .TranslateCyr($Coding,"x-mac-cyrillic",$_) ."\n";
print "--------------------------------------------------\n";
print "Your line lowercase: " .toLowerCyr($_, $Coding) ."\n";
print "Your line uppercase: " .toUpperCyr($_, $Coding) ."\n";
print "--------------------------------------------------\n";

