use strict;
use warnings;
use EAV::XS;
use Test::More;


my $testnum = 0;

my $eav = EAV::XS->new();
ok (defined $eav);

my @email_pass = (
    'ipv6@[IPv6:2001:DB8::1]',
    # at moment libeav does not checks network classes :(
    'ipv6@[IPv6:::1]',
    'ipv6@[2001:DB8::1]',
    'ipv6@[ipv6:::ffff:192.0.2.128]',
    # yep, postfix allows it
    'ipv6@[:::ffff:192.0.2.128]',
);

my @email_fail = (
    'ipv6@[:]',
    'ipv6@[:::]',
    'ipv6@[IPv6:]',
    'ipv6@[::ffff;10.0.0.1]',
    'ipv6@[2001:Dg8::1]'
);

for my $email (@email_pass) {
    ok ($eav->is_email($email), "pass: '" . $email . "'");
    $testnum++;
}

for my $email (@email_fail) {
    ok (! $eav->is_email($email), "fail: '" . $email . "'");
    $testnum++;
}

done_testing ($testnum + 1);
