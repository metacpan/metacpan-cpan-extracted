#!perl -T
use strict;
use warnings;
use Test::More;
use Geo::Coder::All;
use Module::Runtime qw(require_module);
eval { require_module('Geo::Coder::Bing') };

if($@){
    plan skip_all => "Bing geocoder tests as I can not find Geo::Coder::Bing.";
    exit;
}

unless($ENV{BING_API_KEY}){
    plan skip_all => "No Bing Api key provided skipping tests for Bing Geocoder,SET ENV variable BING_API_KEY=key";
    exit;
}

{
my $geocoder = Geo::Coder::All->new(geocoder=>'Bing',key=>$ENV{BING_API_KEY});
my $rh_location =$geocoder->geocode({location=> 'Anfield,Liverpool'});
if(!$rh_location){
    plan skip_all => "Response from Geo Coder Bing is undef";
    exit;
}else{
    plan tests => 8;
}
isa_ok($geocoder->geocoder_engine->Bing,'Geo::Coder::Bing');
is($rh_location->{geocoder},'Bing','checking geocoder');
is($rh_location->{country},'United Kingdom','checking country');
is($rh_location->{country_code},'GB','checking country code');
is($rh_location->{country_code_alpha_3},'GBR','checking country code alpha3');
like($rh_location->{address},qr/Anfield/i,'checking address');
like($rh_location->{coordinates}{lat},qr/53.4/,'checking latitude');
like($rh_location->{coordinates}{lon},qr/-2.9/,'checking longitude');
}



