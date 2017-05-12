#!perl -T
use strict;
use warnings;
use Test::More;
use Geo::Coder::All;
plan tests => 8;
{
my $geocoder = Geo::Coder::All->new(apiver =>3,
    ($ENV{GMAP_KEY} ?(key=> $ENV{GMAP_KEY}):()) ,
    ($ENV{GMAP_CLIENT} ?(client=> $ENV{GMAP_CLIENT}):()) ,
);
my $location =$geocoder->geocode({location=> 'Anfield,Liverpool'});
isa_ok($geocoder->geocoder_engine->GOOGLE,'Geo::Coder::Google::V3');
is($location->{geocoder},'Google','checking geocoder');
is($location->{country},'United Kingdom','checking country');
is($location->{country_code},'GB','checking country code ');
is($location->{country_code_alpha_3},'GBR','checking country code alpha3');
like($location->{address},qr/Anfield/i,'checking address');
like($location->{coordinates}{lat},qr/53.4/,'checking latitude');
like($location->{coordinates}{lon},qr/-2.9/,'checking longitude');
}



