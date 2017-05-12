#!/home/ben/software/install/bin/perl
use warnings;
use strict;
no utf8;
my $kani = '87f9';
print "hex is character string\n" if utf8::is_utf8 ($kani);
# prints nothing
$kani = chr (hex ($kani));
print "chr makes it a character string\n" if utf8::is_utf8 ($kani);
# prints "chr makes it a character string"
