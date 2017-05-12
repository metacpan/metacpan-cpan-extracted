use strict;
use warnings;
use Test::Base;
use YAML;
use File::Spec::Functions;
use HTTP::MobileAttribute plugins => [
    'Core',
    {
        module => 'Display',
        config => +{
            DoCoMoMap => YAML::LoadFile(
                catfile(qw/t Plugins assets DoCoMoDisplayMap.yaml/)
            )
        }
    }
];

plan tests => 1*blocks;

filters {
    input    => [qw/yaml get_display/],
    expected => [qw/yaml/],
};

run_is_deeply input => 'expected';

sub get_display {
    my $env = shift;
    local *ENV = $env;
    my $display = HTTP::MobileAttribute->new()->display;
    return {%$display};
}

__END__

===
--- input
HTTP_USER_AGENT: J-PHONE/2.0/J-DN02
HTTP_X_JPHONE_COLOR: C256
HTTP_X_JPHONE_DISPLAY: 120*117
--- expected
color: 1
depth: 256
height: 117
width: 120

===
--- input
HTTP_USER_AGENT: KDDI-TS21 UP.Browser/6.0.2.276 (GUI) MMP/1.1
HTTP_X_UP_DEVCAP_ISCOLOR: 1
HTTP_X_UP_DEVCAP_SCREENDEPTH: '16,RGB565'
HTTP_X_UP_DEVCAP_SCREENPIXELS: '90,70'
--- expected
color: 1
depth: 65536
height: 70
width: 90

===
--- input
HTTP_USER_AGENT: KDDI-TS21 UP.Browser/6.0.2.276 (GUI) MMP/1.1
HTTP_X_UP_DEVCAP_ISCOLOR: 0
HTTP_X_UP_DEVCAP_SCREENDEPTH: 1
HTTP_X_UP_DEVCAP_SCREENPIXELS: '90,70'
--- expected
color: ''
depth: 2
height: 70
width: 90

===
--- input
HTTP_USER_AGENT: DoCoMo/1.0/D501i
--- expected
color: ''
depth: 2
height: 72
width: 96

===
--- input
HTTP_USER_AGENT: DoCoMo/1.0/D502i
--- expected
color: 1
depth: 256
height: 90
width: 96

===
--- input
HTTP_USER_AGENT: DoCoMo/1.0/N502i
--- expected
color: ''
depth: 4
height: 128
width: 118

===
--- input
HTTP_USER_AGENT: DoCoMo/2.0 N703imyu
--- expected
color: 1
depth: 262144
height: 270
width: 240

===
--- input
HTTP_USER_AGENT: DoCoMo/2.0 N04A(c100;TB;W24H16)
--- expected
color: 1
depth: 262144
height: 320
width: 240

