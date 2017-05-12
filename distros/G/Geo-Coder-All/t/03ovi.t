#!perl -T
use strict;
use warnings;
use Test::More;
use Geo::Coder::All;
use Data::Dumper;
use Module::Runtime qw(require_module);
eval { require_module('Geo::Coder::Ovi') };

if($@){
    plan skip_all => "Ovi geocoder tests as I can not find Geo::Coder::Ovi.";
    exit;
}
{
my $geocoder = Geo::Coder::All->new(geocoder =>'Ovi');
my $rh_location =$geocoder->geocode({location=> 'Anfield,Liverpool'});
if(!$rh_location){
    plan skip_all => "Response from Geo Coder Ovi is undef";
    exit;
}else{
    plan tests => 8;
}
isa_ok($geocoder->geocoder_engine->Ovi,'Geo::Coder::Ovi');
is($rh_location->{geocoder},'Ovi','checking geocoder');
is($rh_location->{country},'United Kingdom','checking country');
is($rh_location->{country_code},'GB','checking country code ');
is($rh_location->{country_code_alpha_3},'GBR','checking country code alpha3');
like($rh_location->{address},qr/Anfield/i,'checking address');
like($rh_location->{coordinates}{lat},qr/53.4/,'checking latitude');
like($rh_location->{coordinates}{lon},qr/-2.9/,'checking longitude');
}



