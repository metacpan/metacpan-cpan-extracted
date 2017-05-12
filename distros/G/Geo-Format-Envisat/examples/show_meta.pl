#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;
$Data::Dumper::Sortkeys =
   sub {[sort {lc($a) cmp lc($b) || $a cmp $b} keys %{$_[0]}] };
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;

use lib 'lib', '../lib';    # needed when the module is not yet installed
use Geo::Format::Envisat;

@ARGV==1
    or die "Usage: $0 <filename>\n";

my ($fn) = @ARGV;

my $meta = envisat_meta_from_file $fn, take_dsd_content => 1;

print "***** the full data meta-data\n";
print Dumper $meta;

foreach my $class ('MDS1', 'MDS2')
{
    my $mds = $meta->{dsd}{$class}
        or next;

    print "***** contains $class\n";
    {   print "begin in file : $mds->{ds_offset}\n";
        print "data size     : $mds->{ds_size} bytes\n";
        print "pixel size    : $meta->{sph}{pixel_octets} bytes\n";
        print "line width    : $meta->{sph}{line_length} pixels\n";
        print "line record   : $mds->{dsr_size} bytes\n";
    }
}
