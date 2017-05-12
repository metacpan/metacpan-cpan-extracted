#!/usr/bin/perl
##
## Ham::Resources::Utils test module
## Test 
##
## (c) Carlos Juan Diaz <ea3hmb at gmail.com> on Nov. 2016
##
#
use strict;
use warnings;
use Data::Dumper;
use lib '../lib';
use Ham::Resources::Utils;

my $foo = Ham::Resources::Utils->new();
my %data;
my $separator = "\t";
my $date = "28-6-2012";
my $locator_dep = "JN11cj";
my $locator_arr = "IE38sc";
my %coordinates = ( lat_1 => "41N23", 
                    long_1 => "2E12", 
                    lat_2 => "41S54", 
                    long_2 => "12W30");
 


print "DATA BY COORDINATES\n";
%data = $foo->data_by_coordinates($date, %coordinates);
show_results(%data);

print"\nDATA BY LOCATOR\n";
%data = $foo->data_by_locator($date,$locator_dep,$locator_arr);
show_results(%data);


sub show_results {
  foreach my $key (sort keys %data) {
  	if (length($key) <= 7) { $separator = "\t\t\t"; }
  	elsif (length($key) > 7 && length($key) < 15) { $separator = "\t\t"; }
  	else { $separator = "\t"; }
  	print $key.$separator.": ".$data{$key},"\n" if ($data{$key});
  }
}


