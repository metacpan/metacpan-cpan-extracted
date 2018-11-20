#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
# Convert Western to Japanese dates
use Lingua::JA::FindDates 'seireki_to_nengo';
binmode STDOUT, ":encoding(utf8)";
print seireki_to_nengo ('1989年1月1日'), "\n";
