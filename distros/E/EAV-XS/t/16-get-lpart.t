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


my %email_pass = (
    'test@example.net'	=> 'test',
    'тест@тест.рф'      => 'тест',
    'ipv4@[1.2.3.4]'    => 'ipv4',
    'ipv6@[IPv6:2001:DB8::1]' => 'ipv6',
);

foreach my $email (keys %email_pass) {
    diag ("error when processing '", $email, "': ", $eav->get_error())
        if !$eav->is_email($email);
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
