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
ok (defined $eav);


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
    'ok@test.aaa',
    'ok@дети.дети',
    'ok@ею.ею',
    'ok@қаз.қаз',
    'ok@קום.קום',
    'ok@localhost',
    'ok@test',
    'ok@example',
    'ok@example.com',
    'ok@example.net',
    'ok@example.org',
    'ok@secure.onion',
    'ok@onion',
    'cc@test.ss',
    'cc@ಭಾರತ.ಭಾರತ',
    'cc@ଭାରତ.ଭାରତ',
    'cc@ভাৰত.ভাৰত',
    'cc@भारोत.भारोत',
    'cc@भारतम्.भारतम्',
    'cc@بارت.بارت',
    'cc@ڀارت.ڀارت',
    'cc@ഭാരതം.ഭാരതം',
);

my @email_fail = (
    # unknown tld
    'unknown@example.x',
    # test
    'test@测试.测试',
    'test@परीक्षा.परीक्षा',
    'test@испытание.испытание',
    'test@테스트.테스트',
    'test@טעסט.טעסט',
    'test@測試.測試',
    'test@آزمایشی.آزمایشی',
    'test@பரிட்சை.பரிட்சை',
    'test@δοκιμή.δοκιμή',
    'test@إختبار.إختبار',
    'test@テスト.テスト',
    # not assigned
    'na@test.bl',
    'na@test.bq',
    'na@test.eh',
    'na@test.mf',
    'na@test.um',
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
