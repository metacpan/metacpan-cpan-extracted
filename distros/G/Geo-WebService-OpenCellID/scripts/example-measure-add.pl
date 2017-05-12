#!/usr/bin/perl

=head1 NAME

example-measure-add.pl - Simple example showing usage of cell->get method

=cut

use strict;
use warnings;
use Data::Dumper;
use blib;
use lib qw{. ..};
use Geo::WebService::OpenCellID;
my $key=shift||"myapikey";
my $gwo=Geo::WebService::OpenCellID->new(key=>$key);
my $response=$gwo->measure->add(
                         mnc=>784,
                         mcc=>608,
                         lac=>46156,
                         cellid=>40072,
                         lat=>38.865953,
                         lon=>-77.108595,
                         measured_at=>"2009-02-28T07:43:00Z",
                        );
if ($response) {
  print "+" x 80, "\n";
  print Dumper([$response]);
  print "-" x 80, "\n";
  printf "Status: %s\n", $response->stat;
  printf "ID: %s\n", $response->id;
  printf "CellID: %s\n", $response->cellid;
  printf "Response: %s\n", $response->res;
} else {
  print "Something went wrong."
}
