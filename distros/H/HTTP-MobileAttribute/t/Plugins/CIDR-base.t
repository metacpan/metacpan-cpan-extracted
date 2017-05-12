use strict;
use warnings;
use Test::Base;

BEGIN {
    eval {
        require Net::CIDR::MobileJP;
        Net::CIDR::MobileJP->import( -profile => 't/perlcriticrc' );
    };
    plan skip_all => "Net::CIDR::MobileJP is not installed." if $@;
};

use HTTP::MobileAttribute plugins => [
    'Core',
    {
        module => 'CIDR',
        config => +{
            cidr => +{
                I => [ '10.100.0.0/24' ],
                V => [ '10.100.1.0/24' ],
                E => [ '10.100.2.0/24' ],
                H => [ '10.100.3.0/24' ],
            },
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

    my $hma = HTTP::MobileAttribute->new($env->{HTTP_USER_AGENT});
    +{
        result => $hma->isa_cidr($env->{HTTP_REMOTE_ADDR}) ? 1 : 0,
    };
}

__END__

===
--- input
HTTP_USER_AGENT: DoCoMo/1.0/D501i
HTTP_REMOTE_ADDR: 10.100.0.1
--- expected
result: 1

===
--- input
HTTP_USER_AGENT: DoCoMo/1.0/D501i
HTTP_REMOTE_ADDR: 10.100.4.1
--- expected
result: 0

===
--- input
HTTP_USER_AGENT: J-PHONE/2.0/J-DN02
HTTP_REMOTE_ADDR: 10.100.1.1
--- expected
result: 1

===
--- input
HTTP_USER_AGENT: J-PHONE/2.0/J-DN02
HTTP_REMOTE_ADDR: 10.100.4.1
--- expected
result: 0

===
--- input
HTTP_USER_AGENT: KDDI-TS21 UP.Browser/6.0.2.276 (GUI) MMP/1.1
HTTP_REMOTE_ADDR: 10.100.2.1
--- expected
result: 1

===
--- input
HTTP_USER_AGENT: KDDI-TS21 UP.Browser/6.0.2.276 (GUI) MMP/1.1
HTTP_REMOTE_ADDR: 10.100.4.1
--- expected
result: 0

===
--- input
HTTP_USER_AGENT: Mozilla/3.0(WILLCOM;KYOCERA/WX300K/1;1.0.2.8.000000/0.1/C100) Opera/7.0
HTTP_REMOTE_ADDR: 10.100.3.1
--- expected
result: 1

===
--- input
HTTP_USER_AGENT: Mozilla/3.0(WILLCOM;KYOCERA/WX300K/1;1.0.2.8.000000/0.1/C100) Opera/7.0
HTTP_REMOTE_ADDR: 10.100.4.1
--- expected
result: 0

===
--- input
HTTP_USER_AGENT: Mozilla/3.0
HTTP_REMOTE_ADDR: 10.100.0.1
--- expected
result: 0

===
--- input
HTTP_USER_AGENT: Mozilla/3.0
HTTP_REMOTE_ADDR: 10.100.1.1
--- expected
result: 0

===
--- input
HTTP_USER_AGENT: Mozilla/3.0
HTTP_REMOTE_ADDR: 10.100.2.1
--- expected
result: 0

===
--- input
HTTP_USER_AGENT: Mozilla/3.0
HTTP_REMOTE_ADDR: 10.100.3.1
--- expected
result: 0

===
--- input
HTTP_USER_AGENT: Mozilla/3.0
HTTP_REMOTE_ADDR: 10.100.4.1
--- expected
result: 1
