#!/usr/bin/perl

use lib 'lib', '../lib';
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';

use Geo::Coder::GeocodeFarm;
use Data::Dumper;
use Encode;

my %args = map { /^(.*?)=(.*)$/ and ($1 => decode_utf8($2)) } @ARGV;

die "Usage: geocode.pl key=YOUR-API-KEY-HERE location='530 West Main St Anoka MN 55303'\n"
    unless defined $args{key} and (defined $args{location} or defined $args{addr});

my $geocoder = Geo::Coder::GeocodeFarm->new(%args);

my $result = eval { $geocoder->geocode(%args); };
die "Failed To Find Coordinates: $@" if $@;

print Dumper $result;
