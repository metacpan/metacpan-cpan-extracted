use strict;
use Test::Base;
plan tests => 6 * blocks;

use HTTP::MobileAgent::Plugin::Location qw(use_geocoordinate);
use CGI;

eval "use Geo::Coordinates::Converter;";

SKIP:{
    skip "Geo::Coordinates::Converter is not installed", 6 * blocks if($@);

    run {
        local %ENV;

        my $block = shift;
        my ($ua,$qs)                               = split(/\n/,$block->input);
        my ($lat,$lng,$accuracy,$mode,$datum,$mesh7) = split(/\n/,$block->expected);

        $ENV{'HTTP_USER_AGENT'} = $ua;
        $ENV{'REQUEST_METHOD'}  = "GET";
        if ($qs =~ s/^xjg://) {
            $ENV{'HTTP_X_JPHONE_GEOCODE'} = $qs;
        } else {
            $ENV{'QUERY_STRING'}          = $qs;
        }

        CGI::initialize_globals;
        my $ma = HTTP::MobileAgent->new;
        my $loc = $ma->parse_location;

        foreach my $accessor (qw/lat lng accuracy mode datum mesh7/) {
            is ($loc->$accessor,eval "\$$accessor");
        }
    };
};

__END__
=== DoCoMo FOMA GPS
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
lat=%2B35.00.35.600&lon=%2B135.41.35.600&geo=wgs84&x-acc=3
--- expected
35.00.35.600
135.41.35.600
gps
gps
wgs84
52354510030

=== DoCoMo FOMA iArea
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
AREACODE=06000&ACTN=OK&LAT=%2B35.40.23.975&LON=%2B139.44.24.926&GEO=wgs84&XACC=1
--- expected
35.40.23.975
139.44.24.926
sector
sector
wgs84
53394511112

=== DoCoMo mova GPS
--- input
DoCoMo/1.0/F505iGPS/c20/TB/W24H12
pos=N35.41.35.60E139.01.35.61&geo=wgs84&X-acc=2
--- expected
35.41.35.600
139.01.35.610
hybrid
gps
wgs84
53394002111

=== EZweb GPS
--- input
KDDI-KC31 UP.Browser/6.2.0.5 (GUI) MMP/2.0
ver=1&datum=0&unit=0&lat=%2b34.44.36.02&lon=%2b135.26.44.35&alt=33&time=20061021144922&smaj=104&smin=53&vert=41&majaa=96&fm=2
--- expected
34.44.36.020
135.26.44.350
sector
gps
wgs84
52350332210

=== EZweb Sector
--- input
KDDI-KC31 UP.Browser/6.2.0.5 (GUI) MMP/2.0
datum=tokyo&unit=dms&lat=35.43.25.38&lon=135.43.25.38
--- expected
35.43.25.380
135.43.25.380
sector
sector
wgs84
53354531210

=== SoftBank 3G GPS
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
pos=N35.41.35.60E139.01.35.61&geo=wgs84&x-acr=3
--- expected
35.41.35.600
139.01.35.610
gps
gps
wgs84
53394002111

=== SoftBank 3G Sector
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
pos=N35.41.35.60E139.01.35.61&geo=wgs84&x-acr=1
--- expected
35.41.35.600
139.01.35.610
sector
sector
wgs84
53394002111

=== SoftBank 2G Sector
--- input
J-PHONE/4.2/J-SH53 SH/0003aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.2.1
xjg:354135%1A1390135%1A%88%CA%92%75%8F%EE%95%F1%82%C8%82%B5
--- expected
35.41.35.000
139.01.35.000
sector
sector
tokyo
53394002130

=== WILLCOM Sector
--- input
Mozilla/3.0(WILLCOM;KYOCERA/WX310K/2;1.2.3.16.000000/0.1/C100) Opera 7.0
pos=N35.44.33.150E135.22.33.121
--- expected
35.44.33.150
135.22.33.121
sector
sector
tokyo
53354322202
