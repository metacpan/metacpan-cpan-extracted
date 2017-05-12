#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
binmode STDOUT, ":utf8";
use Lingua::JA::FindDates 'nengo_to_seireki';
print nengo_to_seireki ('昭和64年1月1日');
