use strict;
use warnings;
use EAV::XS;
use Test::More;
# This is a workaround in case if the locale is not utf-8 compatable.
use POSIX qw(setlocale LC_ALL);
setlocale(LC_ALL, "en_US.UTF-8");

my $testnum = 0;

my $eav = EAV::XS->new();
ok (defined $eav, "new EAV::XS");

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
    ok ($eav->is_email($email), "pass: '" . $email . "'");
    $testnum++;
}

for my $email (@email_fail) {
    ok (! $eav->is_email($email), "fail: '" . $email . "'");
    $testnum++;
}

done_testing ($testnum + 1);
