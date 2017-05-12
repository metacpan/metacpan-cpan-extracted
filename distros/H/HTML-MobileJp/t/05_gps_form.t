use strict;
use warnings;
use HTML::MobileJp;
use Test::Base;

plan tests => 1*blocks;

filters {
    input    => [qw/yaml gps_form_filter/],
    expected => [qw/chomp/],
};

run_is input => 'expected';

sub gps_form_filter {
    my $dat = shift;
    gps_form(%$dat);
}

__END__

===
--- input
carrier: I
is_gps: 0
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
<form action="http://w1m.docomo.ne.jp/cp/iarea">
<input type="hidden" name="ecode" value="OPENAREACODE" />
<input type="hidden" name="msn" value="OPENAREAKEY" />
<input type="hidden" name="nl" value="http://example.com/gps/jLKJFJDSL" />
<input type="hidden" name="posinfo" value="1" />

===
--- input
carrier: I
is_gps: 1
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
<form action="http://example.com/gps/jLKJFJDSL" lcs="lcs">

===
--- input
carrier: E
is_gps: 0
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
<form action="device:location?url=http%3A%2F%2Fexample.com%2Fgps%2FjLKJFJDSL">

===
--- input
carrier: E
is_gps: 1
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
<form action="device:gpsone">
<input type="hidden" name="acry" value="0" />
<input type="hidden" name="datum" value="0" />
<input type="hidden" name="number" value="0" />
<input type="hidden" name="unit" value="0" />
<input type="hidden" name="url" value="http://example.com/gps/jLKJFJDSL" />
<input type="hidden" name="ver" value="1" />

===
--- input
carrier: V
is_gps: 0
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
<form action="http://example.com/gps/jLKJFJDSL" z="z">

===
--- input
carrier: V
is_gps: 1
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
<form action="location:auto?url=http://example.com/gps/jLKJFJDSL">

