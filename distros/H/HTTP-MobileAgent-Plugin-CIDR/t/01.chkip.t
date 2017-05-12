use strict;
use Test::Base;
plan tests => 5 * blocks;

use HTTP::MobileAgent::Plugin::CIDR;

my $ma = HTTP::MobileAgent->new("Dummy");

run {
    my $block = shift;
    my ($class,$ip)         = split(/\n/,$block->input);

    foreach my $eachclass (qw(DoCoMo EZweb Vodafone AirHPhone NonMobile)) {
        bless $ma, "HTTP::MobileAgent::$eachclass";

        is $ma->check_network($ip), $eachclass eq "NonMobile" ? 1 :
                                    $eachclass eq $class      ? 1 :
                                                                0;
    }
};

__END__
===
--- input
DoCoMo
210.153.84.0
--- expected

===
--- input
DoCoMo
210.136.161.0
--- expected

===
--- input
DoCoMo
210.153.86.0
--- expected

===
--- input
DoCoMo
210.153.87.0
--- expected

===
--- input
DoCoMo
203.138.180.0
--- expected

===
--- input
DoCoMo
203.138.181.0
--- expected

===
--- input
DoCoMo
203.138.203.0
--- expected

===
--- input
EZweb
210.169.40.0
--- expected

===
--- input
EZweb
210.196.3.192
--- expected

===
--- input
EZweb
210.196.5.192
--- expected

===
--- input
EZweb
210.230.128.0
--- expected

===
--- input
EZweb
210.230.141.192
--- expected

===
--- input
EZweb
210.234.105.32
--- expected

===
--- input
EZweb
210.234.108.64
--- expected

===
--- input
EZweb
210.251.1.192
--- expected

===
--- input
EZweb
210.251.2.0
--- expected

===
--- input
EZweb
211.5.1.0
--- expected

===
--- input
EZweb
211.5.2.128
--- expected

===
--- input
EZweb
211.5.7.0
--- expected

===
--- input
EZweb
218.222.1.0
--- expected

===
--- input
EZweb
61.117.0.0
--- expected

===
--- input
EZweb
61.117.1.0
--- expected

===
--- input
EZweb
61.117.2.0
--- expected

===
--- input
EZweb
61.202.3.0
--- expected

===
--- input
EZweb
219.108.158.0
--- expected

===
--- input
EZweb
219.125.148.0
--- expected

===
--- input
EZweb
222.5.63.0
--- expected

===
--- input
EZweb
222.7.56.0
--- expected

===
--- input
EZweb
222.5.62.128
--- expected

===
--- input
EZweb
222.7.57.0
--- expected

===
--- input
EZweb
59.135.38.128
--- expected

===
--- input
EZweb
219.108.157.0
--- expected

===
--- input
EZweb
219.125.151.128
--- expected

===
--- input
EZweb
219.125.145.0
--- expected

===
--- input
EZweb
121.111.231.0
--- expected

===
--- input
EZweb
121.111.231.160
--- expected

===
--- input
EZweb
121.111.227.0
--- expected

===
--- input
Vodafone
123.108.236.0
--- expected

===
--- input
Vodafone
123.108.237.0
--- expected

===
--- input
Vodafone
202.179.204.0
--- expected

===
--- input
Vodafone
202.253.96.224
--- expected

===
--- input
Vodafone
210.146.7.192
--- expected

===
--- input
Vodafone
210.146.60.192
--- expected

===
--- input
Vodafone
210.151.9.128
--- expected

===
--- input
Vodafone
210.169.130.112
--- expected

===
--- input
Vodafone
210.175.1.128
--- expected

===
--- input
Vodafone
210.228.189.0
--- expected

===
--- input
Vodafone
211.8.159.128
--- expected

===
--- input
AirHPhone
61.198.142.0
--- expected

===
--- input
AirHPhone
219.108.14.0
--- expected

===
--- input
AirHPhone
61.198.161.0
--- expected

===
--- input
AirHPhone
219.108.0.0
--- expected

===
--- input
AirHPhone
61.198.249.0
--- expected

===
--- input
AirHPhone
219.108.1.0
--- expected

===
--- input
AirHPhone
61.198.250.0
--- expected

===
--- input
AirHPhone
219.108.2.0
--- expected

===
--- input
AirHPhone
61.198.253.0
--- expected

===
--- input
AirHPhone
219.108.3.0
--- expected

===
--- input
AirHPhone
61.198.254.0
--- expected

===
--- input
AirHPhone
219.108.4.0
--- expected

===
--- input
AirHPhone
61.198.255.0
--- expected

===
--- input
AirHPhone
219.108.5.0
--- expected

===
--- input
AirHPhone
61.204.3.0
--- expected

===
--- input
AirHPhone
219.108.6.0
--- expected

===
--- input
AirHPhone
61.204.4.0
--- expected

===
--- input
AirHPhone
221.119.0.0
--- expected

===
--- input
AirHPhone
61.204.6.0
--- expected

===
--- input
AirHPhone
221.119.1.0
--- expected

===
--- input
AirHPhone
125.28.4.0
--- expected

===
--- input
AirHPhone
221.119.2.0
--- expected

===
--- input
AirHPhone
125.28.5.0
--- expected

===
--- input
AirHPhone
221.119.3.0
--- expected

===
--- input
AirHPhone
125.28.6.0
--- expected

===
--- input
AirHPhone
221.119.4.0
--- expected

===
--- input
AirHPhone
125.28.7.0
--- expected

===
--- input
AirHPhone
221.119.5.0
--- expected

===
--- input
AirHPhone
125.28.8.0
--- expected

===
--- input
AirHPhone
221.119.6.0
--- expected

===
--- input
AirHPhone
211.18.235.0
--- expected

===
--- input
AirHPhone
221.119.7.0
--- expected

===
--- input
AirHPhone
211.18.238.0
--- expected

===
--- input
AirHPhone
221.119.8.0
--- expected

===
--- input
AirHPhone
211.18.239.0
--- expected

===
--- input
AirHPhone
221.119.9.0
--- expected

===
--- input
AirHPhone
125.28.11.0
--- expected

===
--- input
AirHPhone
125.28.13.0
--- expected

===
--- input
AirHPhone
125.28.12.0
--- expected

===
--- input
AirHPhone
125.28.14.0
--- expected

===
--- input
AirHPhone
125.28.2.0
--- expected

===
--- input
AirHPhone
125.28.3.0
--- expected

===
--- input
AirHPhone
211.18.232.0
--- expected

===
--- input
AirHPhone
211.18.233.0
--- expected

===
--- input
AirHPhone
211.18.236.0
--- expected

===
--- input
AirHPhone
211.18.237.0
--- expected

===
--- input
AirHPhone
125.28.0.0
--- expected

===
--- input
AirHPhone
125.28.1.0
--- expected

===
--- input
AirHPhone
61.204.0.0
--- expected

===
--- input
AirHPhone
210.168.246.0
--- expected

===
--- input
AirHPhone
210.168.247.0
--- expected

===
--- input
AirHPhone
219.108.7.0
--- expected

===
--- input
AirHPhone
61.204.2.0
--- expected

===
--- input
AirHPhone
61.204.5.0
--- expected

===
--- input
AirHPhone
61.198.129.0
--- expected

===
--- input
AirHPhone
61.198.140.0
--- expected

===
--- input
AirHPhone
61.198.141.0
--- expected

===
--- input
AirHPhone
125.28.15.0
--- expected

===
--- input
AirHPhone
61.198.165.0
--- expected

===
--- input
AirHPhone
61.198.166.0
--- expected

===
--- input
AirHPhone
61.198.168.0
--- expected

===
--- input
AirHPhone
61.198.169.0
--- expected

===
--- input
AirHPhone
61.198.170.0
--- expected

===
--- input
AirHPhone
61.198.248.0
--- expected

===
--- input
AirHPhone
125.28.16.0
--- expected

===
--- input
AirHPhone
125.28.17.0
--- expected

===
--- input
AirHPhone
211.18.234.0
--- expected

===
--- input
AirHPhone
219.108.8.0
--- expected

===
--- input
AirHPhone
219.108.9.0
--- expected

===
--- input
AirHPhone
219.108.10.0
--- expected

===
--- input
AirHPhone
61.198.138.100
--- expected

===
--- input
AirHPhone
61.198.138.101
--- expected

===
--- input
AirHPhone
61.198.138.102
--- expected

===
--- input
AirHPhone
61.198.139.160
--- expected

===
--- input
AirHPhone
61.198.139.128
--- expected

===
--- input
AirHPhone
61.198.138.103
--- expected

===
--- input
AirHPhone
61.198.139.0
--- expected

===
--- input
AirHPhone
219.108.15.0
--- expected

===
--- input
AirHPhone
61.198.130.0
--- expected

===
--- input
AirHPhone
61.198.163.0
--- expected

