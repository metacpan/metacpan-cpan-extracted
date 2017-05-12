use strict;
use Test::Base;
plan tests => 1 * blocks;

use HTTP::MobileAgent::Plugin::Location qw(use_area);
use CGI;

SKIP:{
    eval "use Location::GeoTool;";
    skip "Location::GeoTool is not installed", 1 * blocks if($@);

    eval "use Location::Area::DoCoMo::iArea;";
    skip "Location::Area::DoCoMo::iArea is not installed", 1 * blocks if($@);

    run {
        local %ENV;

        my $block = shift;
        my ($ua,$qs)                               = split(/\n/,$block->input);
        my ($areacode)                             = split(/\n/,$block->expected);
 
        $ENV{'HTTP_USER_AGENT'} = $ua;
        $ENV{'REQUEST_METHOD'}  = "GET";
        if ($qs =~ s/^xjg://) {
            $ENV{'HTTP_X_JPHONE_GEOCODE'} = $qs;
        } else {
            $ENV{'QUERY_STRING'}          = $qs;
        }
    
        CGI::initialize_globals;
        my $ma = HTTP::MobileAgent->new;
        $ma->parse_location;

        is ($ma->area->id,$areacode);
    };
};

__END__
=== DoCoMo FOMA GPS
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
lat=%2B35.00.35.600&lon=%2B135.41.35.600&geo=wgs84&x-acc=3
--- expected
14904

=== DoCoMo FOMA iArea
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
AREACODE=06000&ACTN=OK&lat=%2B35.40.23.975&lon=%2B139.44.24.926&geo=wgs84&x-acc=1
--- expected
06000

=== DoCoMo mova GPS
--- input
DoCoMo/1.0/F505iGPS/c20/TB/W24H12
pos=N35.41.35.60E139.01.35.61&geo=wgs84&X-acc=2
--- expected
07600

=== EZweb GPS
--- input
KDDI-KC31 UP.Browser/6.2.0.5 (GUI) MMP/2.0
ver=1&datum=0&unit=0&lat=%2b34.44.36.02&lon=%2b135.26.44.35&alt=33&time=20061021144922&smaj=104&smin=53&vert=41&majaa=96&fm=2
--- expected
17600

=== SoftBank 3G GPS
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
pos=N35.41.35.60E139.01.35.61&geo=wgs84&x-acr=3
--- expected
07600

=== SoftBank 3G Sector
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
pos=N35.41.35.60E139.01.35.61&geo=wgs84&x-acr=1
--- expected
07600

=== SoftBank 2G Sector
--- input
J-PHONE/4.2/J-SH53 SH/0003aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.2.1
xjg:354135%1A1390135%1A%88%CA%92%75%8F%EE%95%F1%82%C8%82%B5
--- expected
07600

=== WILLCOM Sector
--- input
Mozilla/3.0(WILLCOM;KYOCERA/WX310K/2;1.2.3.16.000000/0.1/C100) Opera 7.0
pos=N35.41.35.600E139.01.35.610
--- expected
07600
