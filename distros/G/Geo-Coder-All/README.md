##geo-coder-all
Geo::Coder::All - Geo::Coder::All
Version 0.06
   * Meta CPAN: https://metacpan.org/pod/Geo::Coder::All
   * CPAN: http://search.cpan.org/~raigad/geo-coder-all/

##DESCRIPTION
Geo::Coder::All is wrapper for other geocoder cpan modules such as Geo::Coder::Google,Geo::Coder::Bing,Geo::Coder::Ovi,Geo::Coder::OSM and Geo::Coder::TomTom. Geo::Coder::All provides common geocode output format for all geocoder.

##SYNOPSIS
```
use Geo::Coder::All;
#For google geocoder
my $google_geocoder = Geo::Coder::All->new();#geocoder defaults to Geo::Coder::Google::V3
#You can also use optional params for google api
my $google_geocoder = Geo::Coder::All->new(key=>'GMAP_KEY',client=>'GMAP_CLIENT');

#For Bing
my $bing_geocoder = Geo::Coder::All->new(geocoder=>'Bing',key=>'BING_API_KEY');

#For Ovi
my $ovi_geocoder = Geo::Coder::All->new(geocoder=>'Ovi');

#For OSM
my $osm_geocoder = Geo::Coder::All->new(geocoder=>'OSM');

#For TomTom
my $tomtom_geocoder = Geo::Coder::All->new(geocoder=>'TomTom');
```

##METHODS
Geo::Coder::All offers geocode and reverse_geocode methods
 * geocode -  
  For Google geocoder , we can directly set the different geocoding
  options when calling geocode and reverse_geocode methods. i.e If you
  use Geo::Coder::Google you will have to create new instance every
  single time you need to change geocoding options
```
$rh_location = $google_geocoder->geocode({location => 'London'});
#above will return London from United Kingdom
#With geocoding options
#Following will return London from Canada as we used country_code is  ca (country_code is ISO 3166-1 )
$rh_location = $google_geocoder->geocode({location => 'London',language=>'en',country_code=>'ca',encoding=>'utf8',sensor=>1});
#in spanish
$rh_location = $google_geocoder->geocode({location => 'London',language=>'es',country_code=>'ca',encoding=>'utf8',sensor=>1});
#default encodings is set to 'utf8' you can change to other such as 'latin1'
#You can also set DEGUB=>1 to dump raw response from the geocoder api
```
  You cal also set GMAP_KEY and GMAP_CLIENT directly from
  geocode/reverse_geocode method and it will just work

  * reverse_geocode - For Google reverse_geocoder
```
$rh_location = $google_geocoder->reverse_geocode({latlng=>'51.508515,-0.1254872',language=>'en',encoding=>'utf8',sensor=>1})
#in spanish
$rh_location = $google_geocoder->reverse_geocode({latlng=>'51.508515,-0.1254872',language=>'es',encoding=>'utf8',sensor=>1})
```
