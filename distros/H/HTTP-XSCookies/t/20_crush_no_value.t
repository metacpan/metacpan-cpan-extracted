use strict;
use warnings;

use Data::Dumper;
use Test::More;
use HTTP::XSCookies qw[crush_cookie];

my $str = 'cookie.a=foo=bar; cookie.b=1234abcd; HttpOnly; no.value.cookie; Secure';
my %expected = (
    0 => {
        'cookie.b'        => '1234abcd',
        'cookie.a'        => 'foo=bar',
    },
    1 => {
        'cookie.b'        => '1234abcd',
        'cookie.a'        => 'foo=bar',
        'Secure'          => undef,
        'HttpOnly'        => undef,
        'no.value.cookie' => undef,
    },
);
foreach my $allow (qw/-1 0 1/) {
    my $got;
    my $label = $allow;
    if ($allow < 0) {
        $label = 'NONE';
        $got = crush_cookie($str);
    } else {
        $got = crush_cookie($str, $allow);
    }

    # print Dumper $got;
    my $expected = $expected{$allow < 0 ? 0 : $allow};
    is_deeply($got, $expected, "crushed cookie with no-value fields, allow is $label");
}

done_testing();
