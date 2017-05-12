# copied over from JSON::PC and modified to use JSON::XS
# and modified again to use JSON::SL
use Test::More;
use strict;
BEGIN { plan tests => 6 };
use JSON::SL qw(decode_json);
use utf8;

#########################
my ($js,$obj);

$js  = '{"foo":0}';
$obj = decode_json($js);
is($obj->{foo}, 0, "normal 0");

$js  = '{"foo":0.1}';
$obj = decode_json($js);
is($obj->{foo}, 0.1, "normal 0.1");


$js  = '{"foo":10}';
$obj = decode_json($js);
is($obj->{foo}, 10, "normal 10");

$js  = '{"foo":-10}';
$obj = decode_json($js);
is($obj->{foo}, -10, "normal -10");


$js  = '{"foo":0, "bar":0.1}';
$obj = decode_json($js);
is($obj->{foo},0,  "normal 0");
is($obj->{bar},0.1,"normal 0.1");

