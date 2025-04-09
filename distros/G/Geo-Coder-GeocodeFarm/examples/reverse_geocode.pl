#!/usr/bin/perl

use lib 'lib', '../lib';
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';

use Geo::Coder::GeocodeFarm;
use Data::Dumper;

my %args = map { /^(.*?)=(.*)$/ and ($1 => $2) } @ARGV;

die "Usage: reverse_geocoder.pl key=YOUR-API-KEY lat=45.2040305 lon=-93.3995728\n"
    unless defined $args{key}
    and defined $args{lat}
    and defined $args{lon};

my $geocoder = Geo::Coder::GeocodeFarm->new(%args);

my $result = eval { $geocoder->reverse_geocode(%args) };
die "Failed To Find Coordinates: $@" if $@;

print Dumper $result;
