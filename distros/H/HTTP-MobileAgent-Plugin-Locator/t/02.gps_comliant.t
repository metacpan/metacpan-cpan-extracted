use Test::More 'no_plan';

use HTTP::MobileAgent;
use HTTP::MobileAgent::Plugin::Locator;

{
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/2.0 P906i(c100;TB;W24H15)';
    my $agent = HTTP::MobileAgent->new;
    ok $agent->gps_compliant, "docomo gps";
}

{
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/2.0 SH904i(c100;TB;W24H16)';
    my $agent = HTTP::MobileAgent->new;
    ok $agent->gps_compliant, "docomo gps";
}

{
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/2.0 P903i(c100;TB;W24H16)';
    my $agent = HTTP::MobileAgent->new;
    ok $agent->gps_compliant, "docomo gps";
}

{
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/2.0 P903iTV(c100;TB;W24H16)';
    my $agent = HTTP::MobileAgent->new;
    ok !$agent->gps_compliant, "not compliant docomo gps";
}

{
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/2.0 P903iX(c100;TB;W24H16)';
    my $agent = HTTP::MobileAgent->new;
    ok !$agent->gps_compliant, "not compliant docomo gps";
}

{
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/1.0/P503i/c10';
    my $agent = HTTP::MobileAgent->new;
    ok !$agent->gps_compliant, "docomo basic";
}

{
    local $ENV{HTTP_USER_AGENT} = 'KDDI-CA31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0';
    local $ENV{HTTP_X_UP_DEVCAP_MULTIMEDIA} = '0200000000000000';
    my $agent = HTTP::MobileAgent->new;
    ok $agent->gps_compliant, "ezweb gps";
}

{
    local $ENV{HTTP_USER_AGENT} = 'KDDI-CA31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0';
    my $agent = HTTP::MobileAgent->new;
    ok !$agent->gps_compliant, "ezweb basic";
}

{
    local $ENV{HTTP_USER_AGENT} = 'SoftBank/1.0/911T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1';
    my $agent = HTTP::MobileAgent->new;
    ok $agent->gps_compliant, "softbank gps";
}

{
    local $ENV{HTTP_USER_AGENT} = 'J-PHONE/2.0/J-DN02';
    local $ENV{ HTTP_X_JPHONE_GEOCODE } = '352051%1a1383456%1afoo';
    my $agent = HTTP::MobileAgent->new;
    ok !$agent->gps_compliant, "softbank basic";
}

{
    local $ENV{HTTP_USER_AGENT} = 'Mozilla/3.0(DDIPOCKET;JRC/AH-J3001V,AH-J3002V/1.0/0100/c50)CNF/2.0';
    my $agent = HTTP::MobileAgent->new;
    ok !$agent->gps_compliant, "willcom basic";
}


