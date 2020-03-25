use strict;
use warnings;
use EAV::XS;
use Test::More;
# This is a workaround in case if the locale is not utf-8 compatable.
use POSIX qw(setlocale LC_ALL);
setlocale(LC_ALL, "en_US.UTF-8");


my $testnum = 1;

my $eav = EAV::XS->new();

ok (defined $eav, "new EAV::XS");

my %email_pass = (
    'test@example.net'	=> 'test',
    'тест@тест.рф'      => 'тест',
    'ipv4@[1.2.3.4]'    => 'ipv4',
    'ipv6@[IPv6:2001:DB8::1]' => 'ipv6',
);

foreach my $email (keys %email_pass) {
    ok($eav->is_email($email), "pass: ${email}");

    my $lpart = $email_pass{$email};
    cmp_ok ($eav->get_lpart(), 'eq', $lpart,
            "lpart: ${lpart} in ${email}");
    $testnum += 2;
}


my @email_fail = (
    'invalid',
    'invalid@',
    'invalid@ [1.2.3.4]',
    'invalid@[0.1.2.3]',
    'invalid@@',
    'invalid@@example.org',
    '@no-local-part.com',
);

foreach my $email (@email_fail) {
    ok (!$eav->is_email($email), "fail: ${email}");
    cmp_ok ($eav->get_lpart(), 'eq', '', "empty lpart: ${email}");
    $testnum += 2;
}

done_testing ($testnum);
