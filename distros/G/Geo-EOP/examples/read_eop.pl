#!/usr/bin/perl
# Read an EOP file.

use warnings;
use strict;

#use Log::Report mode => 3;  #debugging
use Geo::EOP            ();
use XML::Compile::Util  qw/unpack_type/;
use Geo::EOP::Util      qw/NS_SAR_ESA/;

use Data::Dumper 'Dumper';
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys  = 1;

my $version = '1.2.1';   # which EOP version to be created

@ARGV==1
   or die "ERROR: one filename required\n";

my ($filename) = @ARGV;

my ($type, $eop) = Geo::EOP->from($filename, sloppy_floats => 1);

print "EOP type   = $type\n";
my ($thema, $obs) = unpack_type $type;

if($thema eq NS_SAR_ESA)
{   print "   (This is a SAR product)\n";
}

print "EOP version = $eop->{version}\n";
print Dumper $eop;
