#!/usr/bin/perl
use strict;
use warnings;
use Geo::Forward;

my $gf=Geo::Forward->new;

while (<>) {
  chomp;
  my ($lat1, $lon1, $faz, $dist) = split(/\s+/, $_);
  my ($lat2, $lon2, $baz)        = $gf->forward($lat1,$lon1,$faz,$dist);

  print "Input Lat: $lat1  Lon: $lon1\n";
  print "Input Forward Azimuth: $faz\n";
  print "Input Distance: $dist\n";
  print "Output Lat: $lat2 Lon: $lon2\n";
  print "Output Back Azimuth: $baz\n";
  
}

__END__

=head1 NAME

perl-Geo-Forward-example.pl - Geo::Forward Example

=head1 Description

Reads lines from standard input and processes them

=head2 Example

echo "38.871022 -77.055874 62.888507083 4565.6854" | perl perl-Geo-Forward-example.pl

=cut
