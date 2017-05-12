use strict;
use warnings;
use vars qw($ipw);

{
    no strict 'refs';
    *{scalar(caller(0)).'::tests'} = \&tests;
}

1;

sub tests {
    my $ipw = shift;

    is ($ipw->getcc(undef), '**', "getcc(undef) should return **");
    is ($ipw->getcc(''), '**', "getcc('') should return **");
    
    # somewhere in the world there is a test system 
    #  that compiles unquoted numeric constants to packed 32 bits
    #  for its sake we quote the following 5 numeric constants
    
    is ($ipw->getcc('0'), '**', "getcc(0) should return **");
    is ($ipw->getcc('999'), '**', "getcc(999) should return **");
    # string 1000 is equivalent to '49.0.0.0' which is not assigned
    is ($ipw->getcc('1000'), '??', "getcc(1000) should return ??");
    # string 9999 is equivalent to '57.57.57.57'
    is ($ipw->getcc('9999'), 'EU', "getcc(9999) should return EU");
    is ($ipw->getcc('10000'), '**', "getcc(10000) should return **");

    my %testdata = data();
    while (my($ip, $expected) = each %testdata) {
        $ip =~/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;
        my $packed_ip = pack 'C4', $1, $2, $3, $4;
        # test the string form
        is ($ipw->getcc($ip), $expected, "string IP $ip should -> $expected");
        # test the packed form
        is ($ipw->getcc($packed_ip), $expected, "packed IP $ip should -> $expected");
    }
}

sub data { qw(
    0.0.0.0 ??
    1.50.15.255 AP
    2.47.255.255 IT
    2.127.255.255 GB
    2.128.0.0 ??
    2.255.255.255 ??
    3.0.0.0 AP
    3.51.91.255 AP
    3.51.92.0 US
    46.1.23.255 ??
    46.1.24.0 EU
    58.97.127.255 TH
    58.97.128.0 ??
    62.12.40.87 NG
    62.12.40.88 ??
    63.251.11.47 US
    63.251.112.48 GB
    64.4.63.255 US
    64.4.64.0 CA
    126.255.255.255 JP
    127.255.255.255 ??
    128.0.0.0 US
    128.7.33.44 DE
    150.206.123.22 NZ
    199.254.238.255 US
    199.255.137.255 BE
    199.255.138.0 US
    200.0.19.255 ??
    200.0.16.0 CU
    217.74.154.199 TJ
    217.78.50.0 PS
    217.113.76.97 SL
    217.115.217.217 RO
    217.140.119.14 SE
    221.132.120.0 ??
    222.232.0.0 KR
    222.251.128.0 KR
    222.251.255.255 KR
    222.252.0.0 VN
    222.255.255.255 VN
    223.255.255.255 AP
    224.0.0.0 ??
    255.255.255.255 ??
); }
