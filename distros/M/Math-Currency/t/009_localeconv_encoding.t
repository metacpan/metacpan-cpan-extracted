#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use lib 't/lib';
use My::Test::Util;
use Test::More tests => 12;
use Test::More::UTF8;
use POSIX qw(setlocale);

binmode STDOUT, ':utf8';

use_ok('Math::Currency') or exit 1;

my $format = {};

my %locales = (
    'en_GB'           => '£',
    'en_GB.UTF-8'     => '£',
    'en_GB.ISO8859-1' => '£',
    'ru_RU'           => qr/(руб|₽)/,  # on some systems, this is 'руб', on others is 'руб.'
    'ru_RU.UTF-8'     => qr/(руб|₽)/,
    'ru_RU.KOI8-R'    => qr/(руб|₽)/,
    'zh_CN.GB2312'    => qr/(?:#\$|￥)/,
    'zh_CN'           => '￥',
    'zh_CN.GBK'       => '￥',
    'zh_CN.UTF-8'     => '￥',
    'zh_CN.eucCN'     => '￥'
);

while (my ($locale, $symbol) = each %locales) {
    subtest $locale => sub {
        plan_locale($locale, 1);
        Math::Currency->localize(\$format);

        if ((ref $symbol || '') eq 'Regexp') {
            like $$format{CURRENCY_SYMBOL}, $symbol, 'Currency symbol decoded correctly';
        }
        else {
            is $$format{CURRENCY_SYMBOL}, $symbol, "Currency symbol $symbol decoded correctly";
        }
    };
}
