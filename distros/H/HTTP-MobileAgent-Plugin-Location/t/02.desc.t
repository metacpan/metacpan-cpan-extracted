use strict;
use Test::Base;
plan tests => 1 * blocks;

use HTTP::MobileAgent::Plugin::Location;
use CGI;
use YAML;
use XML::Simple;
use Encode;
local %ENV;

run {
    local %ENV;

    my $block = shift;
    my ($ua,$uri,$desc,$mode,$method) = split(/\n/,$block->input);
    my $out                           = $block->expected;

    $ENV{'HTTP_USER_AGENT'} = $ua;
    $ENV{'REQUEST_METHOD'}  = "GET";

    CGI::initialize_globals;
    my $ma = HTTP::MobileAgent->new;
    $ma->location;

    my $opt = {};
    $opt->{mode}   = $mode   if ($mode   && $mode   ne "");
    $opt->{method} = $method if ($method && $method ne "");

    if (my $res = $ma->location_description($uri,$desc,$opt)) {
        is ($res,$out);
    } else {
        is ($ma->err."\n",$out);        
    }

};

__END__
=== DoCoMo mova GPS POST
--- input
DoCoMo/1.0/F505iGPS/c20/TB/W24H12
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得


--- expected
<form action="http://www.example.com/example/example" method="post">
<input type="submit" name="navi_pos" value="位置取得">
<input type="hidden" name="param1" value="1234">
<input type="hidden" name="param2" value="テスト">
</form>

=== DoCoMo mova GPS A
--- input
DoCoMo/1.0/F505iGPS/c20/TB/W24H12
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得

a
--- expected
Not support A method location description

=== DoCoMo FOMA GPS POST
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得

post
--- expected
<form action="http://www.example.com/example/example" method="post" lcs="lcs">
<input type="submit" value="位置取得" />
<input type="hidden" name="param1" value="1234" />
<input type="hidden" name="param2" value="テスト" />
</form>

=== DoCoMo FOMA GPS A
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得


--- expected
<a href="http://www.example.com/example/example?param1=1234&amp;param2=%E3%83%86%E3%82%B9%E3%83%88" lcs="lcs">位置取得</a>

=== DoCoMo FOMA Sector POST
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得
sector

--- expected
<form action="http://w1m.docomo.ne.jp/cp/iarea" method="post">
<input type="submit" value="位置取得" />
<input type="hidden" name="ecode" value="OPENAREACODE" />
<input type="hidden" name="msn" value="OPENAREAKEY" />
<input type="hidden" name="nl" value="http://www.example.com/example/example" />
<input type="hidden" name="arg1" value="param1=1234" />
<input type="hidden" name="arg2" value="param2=テスト" />
<input type="hidden" name="posinfo" value="1" />
</form>

=== DoCoMo FOMA Sector A
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得
sector
a
--- expected
<a href="http://w1m.docomo.ne.jp/cp/iarea?ecode=OPENAREACODE&amp;msn=OPENAREAKEY&amp;nl=http%3A%2F%2Fwww.example.com%2Fexample%2Fexample&amp;arg1=param1%3D1234&amp;arg2=param2%3D%E3%83%86%E3%82%B9%E3%83%88&amp;posinfo=1">位置取得</a>

=== EZ GPS GET
--- input
KDDI-KC31 UP.Browser/6.2.0.5 (GUI) MMP/2.0
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得

get
--- expected
<form action="device:gpsone" method="get">
<input type="submit" value="位置取得" />
<input type="hidden" name="url" value="http://www.example.com/example/example" />
<input type="hidden" name="ver" value="1" />
<input type="hidden" name="datum" value="0" />
<input type="hidden" name="unit" value="0" />
<input type="hidden" name="acry" value="0" />
<input type="hidden" name="number" value="0" />
</form>

=== EZ GPS A
--- input
KDDI-KC31 UP.Browser/6.2.0.5 (GUI) MMP/2.0
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得


--- expected
<a href="device:gpsone?url=http%3A%2F%2Fwww.example.com%2Fexample%2Fexample&amp;ver=1&amp;datum=0&amp;unit=0&amp;acry=0&amp;number=0">位置取得</a>

=== EZ Sector GET
--- input
KDDI-KC31 UP.Browser/6.2.0.5 (GUI) MMP/2.0
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得
sector
get
--- expected
<form action="device:location" method="get">
<input type="submit" value="位置取得" />
<input type="hidden" name="url" value="http://www.example.com/example/example" />
</form>

=== EZ Sector A
--- input
KDDI-KC31 UP.Browser/6.2.0.5 (GUI) MMP/2.0
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得
sector

--- expected
<a href="device:location?url=http%3A%2F%2Fwww.example.com%2Fexample%2Fexample">位置取得</a>

=== SoftBank GPS POST
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得

post
--- expected
<form action="location:gps" method="post">
<input type="submit" value="位置取得" />
<input type="hidden" name="url" value="http://www.example.com/example/example" />
<input type="hidden" name="param1" value="1234" />
<input type="hidden" name="param2" value="テスト" />
</form>

=== SoftBank GPS A
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得


--- expected
<a href="location:gps?url=http://www.example.com/example/example&amp;param1=1234&amp;param2=%E3%83%86%E3%82%B9%E3%83%88">位置取得</a>

=== SoftBank 3G Sector POST
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得
sector
post
--- expected
<form action="location:cell" method="post">
<input type="submit" value="位置取得" />
<input type="hidden" name="url" value="http://www.example.com/example/example" />
<input type="hidden" name="param1" value="1234" />
<input type="hidden" name="param2" value="テスト" />
</form>

=== SoftBank 3G Sector A
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得
sector

--- expected
<a href="location:cell?url=http://www.example.com/example/example&amp;param1=1234&amp;param2=%E3%83%86%E3%82%B9%E3%83%88">位置取得</a>

=== SoftBank 2G Sector POST
--- input
J-PHONE/4.2/J-SH53 SH/0003aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.2.1
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得
sector
post
--- expected
<form action="http://www.example.com/example/example" method="post" z>
<input type="submit" value="位置取得">
<input type="hidden" name="param1" value="1234">
<input type="hidden" name="param2" value="テスト">
</form>

=== SoftBank 2G Sector A
--- input
J-PHONE/4.2/J-SH53 SH/0003aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.2.1
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得
sector

--- expected
<a href="http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88" z>位置取得</a>

=== WILLCOM A
--- input
Mozilla/3.0(WILLCOM;SANYO/WX310SA/2;1/1/C128) NetFront/3.3
http://www.example.com/example/example?param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88
位置取得


--- expected
<a href="http://location.request/dummy.cgi?my=http%3A%2F%2Fwww.example.com%2Fexample%2Fexample&pos=$location&param1=1234&param2=%E3%83%86%E3%82%B9%E3%83%88">位置取得</a>

