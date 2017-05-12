#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib', '../lib';  # not needed when module is installed
use Geo::Format::Landsat::MTL;

use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys  = sub { +[ sort {lc($a) cmp lc($b)} keys %{$_[0]} ] };

@ARGV==1
    or die "Usage: $0 <filename>\n";

my ($fn) = @ARGV;

#### inspect file name only

print "FROM FILENAME:\n";

my $short = landsat_meta_from_filename $fn;
print Dumper $short;


#### inspect file content

print "FROM CONTENT:\n";

my ($type, $data) = landsat_mtl_from_file $fn;

print "TYPE=$type\n";
print Dumper $data;
