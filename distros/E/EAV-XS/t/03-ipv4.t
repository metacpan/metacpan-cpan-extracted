use strict;
use warnings;
use EAV::XS;
use Test::More;


my $testnum = 0;

my $eav = EAV::XS->new();
ok (defined $eav);

my @email_pass = (
    'ipv4@[1.2.3.4]',
    # at moment libeav does not checks network classes :(
    'ipv4@[192.168.0.1]', 
    'ipv4@[10.0.10.15]',
    'ipv4@[172.16.0.3]',
    'ipv4@[255.255.255.255]',
);

my @email_fail = (
    'ipv4@[]',
    'ipv4@[0.0.0.0]',
    'ipv4@[0.1.2.3]',
    'ipv4@[100.200.300.400]',
    'ipv4@[255.255.255.256]',
    'ipv4@[10]',
    'ipv4@[10.]',
    'ipv4@[10.1]',
    'ipv4@[10.1.]',
    'ipv4@[10.1.2]',
    'ipv4@[10.1.2.]',
    '@[10.20.30.40]',
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
