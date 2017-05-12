#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 14;

BEGIN { use_ok( 'JavaScript::XRay' ); }
require_ok( 'JavaScript::XRay' );

# get test page from __DATA__
my $test_page = do { local $/; <DATA> };

# creat a new instace 
my $jsxray = JavaScript::XRay->new();
isa_ok( $jsxray, 'JavaScript::XRay' );

# basic test
my $xrayed_page = $jsxray->filter($test_page);
like( $xrayed_page, qr/jsxray/s, 'Page Successfully Filtered' );

# complex test
$jsxray = JavaScript::XRay->new(
    switches => {
        skip          => 'start_stop_clock',
        uncomment     => 'Test,Test2',
        anon          => 1,
        no_exec_count => 1,
    },
    alias        => 'testit',
    css_inline   => 'INLINE',
    css_external => 'EXTERNAL',
);
$xrayed_page = $jsxray->filter($test_page);

# test to find gel
like( $xrayed_page, qr/testit\('gel/s, 'Test filter function gel' );

# test to skip start_stop_clock
unlike( $xrayed_page, qr/testit\(\'start/s,
    'Test filter function skip start_stop_clock' );

# test to skip start_stop_clock
like( $xrayed_page, qr/ANON/s, 'Test filter function ANON' );

# test croak to avoid recursive loop
eval {
    $jsxray = JavaScript::XRay->new(
        alias => 'jsdebug',
        switches => {
            jsdebug_only          => 'NONE1,NONE2',
            jsdebug_uncomment     => 'Test,Test2',
        },
        iframe_height => 1,
    );
    $xrayed_page = $jsxray->filter($test_page);
};
like($@, qr/may not match alias/, 'Test croak to avoid recursive loop');

# testing uncomment of DEBUG1 and and leave comment DEBUG2
$jsxray = JavaScript::XRay->new(
    alias => 'jstest',
    switches => {
        jstest_only      => 'NONE1,NONE2',
        jstest_anon      => 1,
        jstest_uncomment => 'DEBUG1',
    },
    iframe_height => 1,
);
$xrayed_page = $jsxray->filter($test_page);
unlike( $xrayed_page, qr/DEBUG1 test/s, 'Test uncomment of DEBUG1' );
like(   $xrayed_page, qr/\/\/DEBUG2 test/s, 'Test comment DEBUG2 still there' );

# test function pattern matching
$jsxray = JavaScript::XRay->new( switches => { jsxray_match => 'start' } );
$xrayed_page = $jsxray->filter($test_page);
unlike( $xrayed_page, qr/jsxray\('gel/s, 'Test not match function gel' );
like( $xrayed_page, qr/jsxray\('start_stop_clock/s, 'Test not match function start_stop_clock' );

# test undef switch and anon + switch only
$jsxray = JavaScript::XRay->new(
    switches => {
        jsxray_anon => 1,
        jsxray_skip => undef,
        jsxray_only => 'start_stop_clock',
    },
);
$xrayed_page = $jsxray->filter($test_page);
like( $xrayed_page, qr/jsxray/s, 'test undef switch and anon + switch only' );

# test anon only
$jsxray = JavaScript::XRay->new( switches => { jsxray_anon => 1 } );
$xrayed_page = $jsxray->filter($test_page);
like( $xrayed_page, qr/jsxray/s, 'test anon only' );

__DATA__
<html>
<head>
<script>
<!--

function gel( id ) {
    return document.getElementById ? document.getElementById(id) : null;
}

var timing = 0;
function start_stop_clock() {
    var button = gel('button');
    if (timing) {
        button.value = "Start Clock";
        window.clearInterval(timing);
        timing = 0;
    }
    else {
        button.value = "Stop Clock";
        timing = window.setInterval( "prettyDateTime()", 1000 );
    }
}

function prettyDateTime() {
    var time = gel('time');
    var date  = new Date;
    var day   = date.getDate();
    var month = date.getMonth() + 1;
    var hours = date.getHours();
    var min   = date.getMinutes();
    var sec   = date.getSeconds();
    var ampm  = "AM";

    if ( hours > 11 ) ampm = "PM";
    if ( hours > 12 ) hours -= 12;
    if ( hours == 0 ) hours = 12;
    if ( min < 10 )   min = "0" + min;
    if ( sec < 10 )   sec = "0" + sec;

    time.innerHTML = month + '/' + day + ' ' + hours  
        + ':' + min + ':' + sec    + ' ' + ampm;
}

//DEBUG1 test
//DEBUG2 test
var func_ref = function () { return 1 };

function jsdebug () { return 1; }

-->
</script>
<title>Testing</title>
</head>
<body>
<table>
<tr>
    <td>
    <input id="button" type="button" value="Start Clock" onClick="start_stop_clock()">
    </td>
    <td id="time">&nbsp;</td>
</tr>
</table>
</body>
</html>
