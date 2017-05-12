#!/usr/bin/perl
use Lingua::DetectCyrillic qw ( &toLowerCyr &toUpperCyr &TranslateCyr %RusCharset );
print "** DETECTS CYRILLIC LANGUAGE/CODING AND PRINTS REPORT **\n";
print "Input one line and press Enter: \n";
while (<>){  chomp; last; }
if ( !length() ) { print "You haven't entered a single character! Sorry...\n"; exit; }
$CyrDetector -> LogWrite();
