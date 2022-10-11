use strict;
use warnings;
use EAV::XS;
use Test::More;
# This is a workaround in case if the locale is not utf-8 compatable.
use POSIX qw(locale_h);
use locale;
setlocale(LC_ALL, "en_US.UTF-8") or die "setlocale";


my $testnum = 1;

my $eav = EAV::XS->new();

ok (defined $eav, "new EAV::XS");


# This is a workaround for libidn. It depends on CHARSET environment
# variable ... no comments!!!
if (!$eav->is_email('иван@иванов.рф') &&
    $eav->get_error() eq 'Character encoding conversion error' &&
    !(exists($ENV{'CHARSET'}) && $ENV{'CHARSET'})) {
    diag('probably I have found libidn/CHARSET issue, trying to fix...');
    $ENV{'CHARSET'} = 'utf-8';
    $ENV{'CHARSET'} = 'UTF-8' if !$eav->is_email('иван@иванов.рф');
    delete $ENV{'CHARSET'} if !$eav->is_email('иван@иванов.рф');
}


my %domains = (
    'test@example.net'	=> 1,
    'тест@тест.рф'      => 1,
    'ipv4@[127.0.0.1]'  => 0,
);

foreach my $email (keys %domains) {
    diag ("error when processing '", $email, "': ", $eav->get_error())
        if !$eav->is_email($email);
    ok($eav->is_email($email), "pass: ${email}");

    my $expect = $domains{$email};
    cmp_ok ($eav->get_is_domain(), '==', $expect, "domain: ${email}");
    $testnum += 2;
}


my %ipv4s = (
    'ipv4@[1.2.3.4]'    => 1,
    'test@example.net'	=> 0,
    'тест@тест.рф'      => 0,
);

foreach my $email (keys %ipv4s) {
    diag ("error when processing '", $email, "': ", $eav->get_error())
        if !$eav->is_email($email);
    ok($eav->is_email($email), "pass: ${email}");

    my $expect = $ipv4s{$email};
    cmp_ok ($eav->get_is_ipv4(), '==', $expect, "ipv4: ${email}");
    $testnum += 2;
}


my %ipv6s = (
    'ipv6@[IPv6:2001:DB8::1]'        => 1,
    'ipv6@[ipv6:::ffff:192.0.2.128]' => 1,
    'test@example.net'	=> 0,
    'тест@тест.рф'      => 0,
);

foreach my $email (keys %ipv6s) {
    diag ("error when processing '", $email, "': ", $eav->get_error())
        if !$eav->is_email($email);
    ok($eav->is_email($email), "pass: ${email}");

    my $expect = $ipv6s{$email};
    cmp_ok ($eav->get_is_ipv6(), '==', $expect, "ipv6: ${email}");
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
    ok (!$eav->get_is_ipv4(), "not ipv4: ${email}");
    ok (!$eav->get_is_ipv6(), "not ipv6: ${email}");
    ok (!$eav->get_is_domain(), "not domain: ${email}");
    $testnum += 4;
}

done_testing ($testnum);
