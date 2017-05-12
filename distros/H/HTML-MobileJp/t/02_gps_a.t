use strict;
use warnings;
use HTML::MobileJp;
use Test::Base;

plan tests => 1*blocks;

filters {
    input    => [qw/yaml gps_a_filter/],
    expected => [qw//],
};

run_is input => 'expected';

sub gps_a_filter {
    my $dat = shift;
    gps_a(%$dat);
}

__END__

===
--- input
carrier: I
is_gps: 0
callback_url: http://example.com/gps/jLKJFJDSL
--- expected: <a href="http://w1m.docomo.ne.jp/cp/iarea?ecode=OPENAREACODE&amp;msn=OPENAREAKEY&amp;posinfo=1&amp;nl=http%3A%2F%2Fexample.com%2Fgps%2FjLKJFJDSL">

===
--- input
carrier: I
is_gps: 1
callback_url: http://example.com/gps/jLKJFJDSL
--- expected: <a href="http://example.com/gps/jLKJFJDSL" lcs="lcs">

