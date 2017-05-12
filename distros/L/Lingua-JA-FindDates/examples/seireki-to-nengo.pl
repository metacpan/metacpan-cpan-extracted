#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
binmode STDOUT, ":utf8";
use Lingua::JA::FindDates 'seireki_to_nengo';
print seireki_to_nengo ('1989年1月1日');
