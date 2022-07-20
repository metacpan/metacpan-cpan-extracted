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

my %email_pass = (
    'test@example.net'	=> 'example.net',
    'тест@тест.рф'      => 'тест.рф',
    'ipv4@[1.2.3.4]'    => '1.2.3.4',
    'ipv6@[IPv6:2001:DB8::1]' => 'IPv6:2001:DB8::1',
);

foreach my $email (keys %email_pass) {
    diag ("error when processing '", $email, "': ", $eav->get_error())
        if !$eav->is_email($email);
    ok($eav->is_email($email), "pass: ${email}");

    my $domain = $email_pass{$email};
    cmp_ok ($eav->get_domain(), 'eq', $domain,
            "domain: ${domain} in ${email}");
    $testnum += 2;
}


my @email_fail = (
    'invalid',
    'invalid@',
    'invalid@ [1.2.3.4]',
    'invalid@[0.1.2.3]',
    'invalid@@',
    'invalid@@example.org',
    'invalid@broken domain',
);

foreach my $email (@email_fail) {
    ok (!$eav->is_email($email), "fail: ${email}");
    cmp_ok ($eav->get_domain(), 'eq', '', "empty domain: ${email}");
    $testnum += 2;
}

done_testing ($testnum);
