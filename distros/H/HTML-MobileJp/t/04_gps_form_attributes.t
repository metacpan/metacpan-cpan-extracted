use strict;
use warnings;
use HTML::MobileJp;
use Test::Base;

plan tests => 1*blocks;

filters {
    input    => [qw/yaml gps_form_attributes_filter/],
    expected => [qw/yaml/],
};

run_is_deeply input => 'expected';

sub gps_form_attributes_filter {
    my $dat = shift;
    gps_form_attributes(%$dat);
}

__END__

===
--- input
carrier: I
is_gps: 0
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
action: http://w1m.docomo.ne.jp/cp/iarea
hidden:
  ecode: OPENAREACODE
  msn: OPENAREAKEY
  posinfo: 1
  nl: http://example.com/gps/jLKJFJDSL

===
--- input
carrier: I
is_gps: 1
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
lcs: lcs
action: http://example.com/gps/jLKJFJDSL

===
--- input
carrier: E
is_gps: 0
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
action: device:location?url=http%3A%2F%2Fexample.com%2Fgps%2FjLKJFJDSL

===
--- input
carrier: E
is_gps: 1
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
action: device:gpsone
hidden:
  url   : http://example.com/gps/jLKJFJDSL
  ver   : 1
  datum : 0
  unit  : 0
  acry  : 0
  number: 0

===
--- input
carrier: V
is_gps: 0
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
action: http://example.com/gps/jLKJFJDSL
z: z

===
--- input
carrier: V
is_gps: 1
callback_url: http://example.com/gps/jLKJFJDSL
--- expected
action: location:auto?url=http://example.com/gps/jLKJFJDSL

