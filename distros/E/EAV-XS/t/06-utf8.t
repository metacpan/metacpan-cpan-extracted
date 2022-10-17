use strict;
use warnings;
use EAV::XS;
use Test::More;
# This is a workaround in case if the locale is not utf-8 compatable.
use POSIX qw(locale_h);
use locale;
# FIXME:
# I had tested this on my gear: Windows 10, build 19044.2130 + Strawberry Perl 5.32.1.1 x64.
# And I assume that POSIX::setlocale on Win32 is broken, because here's my results:
# * setlocale(LC_ALL, "English")   PASS
# * setlocale(LC_ALL, "en-US")     FAIL
# * setlocale(LC_ALL, ".1251")     PASS
# * setlocale(LC_ALL, "English_United States.1252")    PASS
# * setlocale(LC_ALL, ".65001")    FAIL
# * setlocale(LC_ALL, ".utf8")     FAIL
# * setlocale(LC_ALL, ".utf-8")    FAIL
# * setlocale(LC_ALL, ".UTF-8")    FAIL
# * setlocale(LC_ALL, ".UTF8")     FAIL
#
# According to docs (see the link below), all tests I've mentioned above MUST pass ...
#
# Reference:
#   https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/setlocale-wsetlocale?view=msvc-170
#
# My conclusions at the moment:
# 1) I just skip return value check on Win32.
#    If anyone knows how to fix it properly, then let me know. Thanks!
#
# 2) On *nix, setlocale() is accepting almost any arguments and returns
#    success most of the time.
#    What's the point to check the return value then? ^_^
#
setlocale(LC_ALL, "en_US.UTF-8") ;#or do {
#    if ($^O ne 'MSWin32') {
#        diag("failed to set locale, continue ...");
#    }
#};

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
