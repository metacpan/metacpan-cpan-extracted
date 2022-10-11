use strict;
use warnings;
use EAV::XS;
use Test::More;
# This is a workaround in case if the locale is not utf-8 compatable.
use POSIX qw(locale_h);
use locale;
setlocale(LC_ALL, "en_US.UTF-8") or die "setlocale";


my $testnum = 0;

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


my @email_pass = (
    'иван@иванов.рф',
    'иван@localhost',
    'борис.борисович+tag@test.com',
    'user@ارامكو.ارامكو',
    'r2l@عربي.de',
    '微博@微博.微博',
    # valid domain
    'الجزائر@الجزائر.الجزائر',
    'ok@hello.vermögensberater',
    'ok@クラウド.クラウド',
    'ok@日本｡co｡jp',
    # RFC 20 checks disabled by default
    '{rfc20}@test',
    '#rfc20#@test',
    '^rfc20^@test',
    'country-code@भारतम्.भारतम्',
);

my @email_fail = (
    'иван@бездомена',
    'no-tld@xn--p1ai',
    '@ελ.ελ',
    '时尚@微博',
    # :) test domain
    'إختبار@إختبار.إختبار',
    'long-domain@ファッション.ファッション.ファッション.ファッション.ファッション.ファッション.ファッション.ファッション.ファッション.ファッション.ファッション.ファッション.ファッション.ファッション.ファッション.ファッション.ファッション',
    'test-tld@إختبار.إختبار',
    'test-tld@آزمایشی.آزمایشی',
    'not-assinged@موبايلي.موبايلي',
);

for my $email (@email_pass) {
    diag ("error when processing '", $email, "': ", $eav->get_error())
        if !$eav->is_email($email);
    ok ($eav->is_email($email), "pass: '" . $email . "'");
    $testnum++;
}

for my $email (@email_fail) {
    ok (! $eav->is_email($email), "fail: '" . $email . "'");
    $testnum++;
}

done_testing ($testnum + 1);
