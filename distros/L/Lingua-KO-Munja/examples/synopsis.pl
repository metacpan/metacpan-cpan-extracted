#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
binmode STDOUT, ":utf8";
use Lingua::KO::Munja qw/roman2hangul hangul2roman/;
my $roman = hangul2roman ('유사쿠');
my $hangul = roman2hangul ('yusaku');
print "$roman $hangul\n";
