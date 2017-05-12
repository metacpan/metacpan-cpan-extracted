use strict;
use warnings;
use HTML::MobileJp;
use Test::Base;

plan tests => 1*blocks;

filters {
    input    => [qw/yaml gps_a_attributes_filter/],
    expected => [qw/yaml/],
};

run_is_deeply input => 'expected';

sub gps_a_attributes_filter {
    my $dat = shift;
    gps_a_attributes(%$dat);
}

__END__

===
--- input
carrier: I
is_gps: 0
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
href: http://w1m.docomo.ne.jp/cp/iarea?ecode=OPENAREACODE&msn=OPENAREAKEY&posinfo=1&nl=http%3A%2F%2Fexample.com%2Fgps%2FjLKJFJDSL

===
--- input
carrier: I
is_gps: 1
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
lcs: lcs
href: http://example.com/gps/jLKJFJDSL

===
--- input
carrier: E
is_gps: 0
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
href: device:location?url=http%3A%2F%2Fexample.com%2Fgps%2FjLKJFJDSL

===
--- input
carrier: E
is_gps: 1
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
href: device:gpsone?url=http%3A%2F%2Fexample.com%2Fgps%2FjLKJFJDSL&ver=1&datum=0&unit=0&acry=0&number=0

===
--- input
carrier: V
is_gps: 0
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
href: http://example.com/gps/jLKJFJDSL
z: z

===
--- input
carrier: V
is_gps: 1
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
href: location:auto?url=http://example.com/gps/jLKJFJDSL

===
--- input
carrier: H
is_gps: 0
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
href: http://location.request/dummy.cgi?my=http://example.com/gps/jLKJFJDSL&pos=$location

