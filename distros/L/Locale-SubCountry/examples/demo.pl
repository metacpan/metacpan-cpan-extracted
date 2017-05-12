#!/usr/bin/perl

# demo script for Locale::SubCountry

use strict;
use lib './lib';
use Locale::SubCountry;

# For every country
#    list the country name and its 2 letter code
#    list each code and full name on a new line

my $world = new Locale::SubCountry::World;
my @all_countries  = $world->all_full_names;

my %all_letters;
foreach my $country ( sort @all_countries )
{
    print "\n\n$country : "; 
    my $current_country = new Locale::SubCountry($country);
    print $current_country->country_code,"\n";
    
    # Are there any sub countries?
    if ( $current_country->has_sub_countries )
    {
        # Get a hash, key is sub country code, value is full name, such as 
        # SA => 'South Australia', VIC => 'Victoria' ...
        my %sub_countries_keyed_by_code  = $current_country->code_full_name_hash;
        foreach my $code ( sort keys %sub_countries_keyed_by_code )
        {
            printf("%-3s : %s\n",$code,$sub_countries_keyed_by_code{$code});
        }               
    }
}