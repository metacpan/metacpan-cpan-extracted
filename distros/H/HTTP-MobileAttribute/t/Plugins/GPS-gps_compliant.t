use strict;
use warnings;
use Test::Base;
use HTTP::MobileAttribute plugins => [
    qw/Core GPS/
];

plan tests => 1*blocks;

filters {
    input => ['yaml', 'gps_compliant'],
};

run_is input => 'expected';

sub gps_compliant {
    local %ENV = %{$_[0]};
    HTTP::MobileAttribute->new()->gps_compliant ? 'supported' : 'not supported'
}

__END__

=== i
--- input
HTTP_USER_AGENT: DoCoMo/2.0 SH905i(c100;TB;W24H12)
--- expected: supported

=== i
--- input
HTTP_USER_AGENT: DoCoMo/1.0/F661i/c10/TB
--- expected: not supported

=== v
--- input
HTTP_USER_AGENT: Vodafone/1.0/V802SE/SEJ001/SNXXXXXXXXX Browser/SEMC-Browser/4.1 Profile/MIDP-2.0 Configuration/CLDC-1.10
--- expected: supported

=== v
--- input
HTTP_USER_AGENT: J-PHONE/5.0/V801SA
--- expected: not supported

=== au
--- input
HTTP_X_UP_DEVCAP_MULTIMEDIA : x2
HTTP_USER_AGENT: KDDI-HI3B UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0
--- expected: supported

=== au
--- input
HTTP_X_UP_DEVCAP_MULTIMEDIA: x
HTTP_USER_AGENT: KDDI-HI3B UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0
--- expected: not supported

=== h
--- input
HTTP_USER_AGENT: Mozilla/3.0(WILLCOM;SANYO/WX310SA/2;1/1/C128) NetFront/3.3
--- expected: not supported

