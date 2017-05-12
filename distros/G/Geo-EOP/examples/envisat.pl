#!/usr/bin/perl
use warnings;
use strict;

#use Log::Report mode => 3;  #debugging
use Geo::EOP::Envisat;

my $version = '1.2.1';   # which EOP version to be created

@ARGV==1
   or die "ERROR: one filename required\n";

my ($filename) = @ARGV;

my $eop = Geo::EOP::Envisat->new(eop_version => $version);
my $xml = $eop->convert($filename);

print $xml->toString(1);
