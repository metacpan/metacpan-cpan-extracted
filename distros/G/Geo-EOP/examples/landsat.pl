#!/usr/bin/perl
use warnings;
use strict;

#use Log::Report mode => 3;  #debugging
use Geo::EOP::Landsat;

my $version = '1.2.1';   # which EOP version to be created

@ARGV==1
   or die "ERROR: one directory required\n";

my ($directory) = @ARGV;

my $eop = Geo::EOP::Landsat->new(eop_version => $version);
my $xml = $eop->convert($directory);

print $xml->toString(1);
