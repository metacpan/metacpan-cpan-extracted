#------------------------------------------------------------------------------
# Test script for CPAN module Locale::SubCountry
#
# Author: Kim Ryan
#------------------------------------------------------------------------------

use strict;
use warnings;
use Test::More tests => 15;
use utf8;
use Locale::SubCountry;

my $australia = Locale::SubCountry->new('Australia');

ok($australia->code('New South Wales') eq 'NSW', "Convert sub country full name to code");
ok($australia->full_name('S.A.') eq 'South Australia', "Convert sub country code to full name, accounted for full stops");

my $upper_case = 1;
ok($australia->full_name('Qld',$upper_case) eq 'QUEENSLAND', "Covert sub country code lower case to full name");
ok($australia->country_code eq 'AU', "Correct country code for country object");
ok($australia->level('NSW') eq 'State', "Correct level for a sub country code");
my %states =  $australia->full_name_code_hash;
ok($states{'Tasmania'} eq 'TAS', "Contents of full_name_code_hash");
%states =  $australia->code_full_name_hash;
ok($states{'SA'} eq 'South Australia' , "Contents of code_full_name_hash");
my @states = $australia->all_codes;
ok(@states == 8, "Total number of sub countries in a country");
my @all_names = $australia->all_full_names;
ok($all_names[1] eq 'New South Wales' , "Order of  all_full_names array");
ok($australia->code('Old South Wales ') eq 'unknown', "Unknown sub country full name");
ok($australia->full_name('XYZ') eq 'unknown', "Unknown sub country code");

# Tests for World object
my $world = Locale::SubCountry::World->new();

my %countries =  $world->full_name_code_hash;
ok($countries{'New Zealand'} eq 'NZ', "Contents of full_name_code_hash for world object");

%countries =  $world->code_full_name_hash;
ok($countries{'GB'} eq 'United Kingdom', "Contents of code_full_name_hash for world object");

my @all_country_codes = $world->all_codes;
ok(@all_country_codes, "all_codes method returns data for world object");

my @all_country_names = $world->all_full_names;
ok(@all_country_names, "all_full_names method returns data for world object");




