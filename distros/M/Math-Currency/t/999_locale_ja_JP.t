#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::More::UTF8;
use My::Test::Util;
use Math::Currency qw($LC_MONETARY);
use POSIX;

plan tests => 2;

my $format = {};

my %LocaleData = (
    CURRENCY_SYMBOL   => '¥',
    FRAC_DIGITS       => '0',
    INT_CURR_SYMBOL   => 'JPY ',
    INT_FRAC_DIGITS   => '0',
    MON_DECIMAL_POINT => '.',
    MON_GROUPING      => '3',
    MON_THOUSANDS_SEP => ',',
    NEGATIVE_SIGN     => '-',
    N_CS_PRECEDES     => '1',
    N_SEP_BY_SPACE    => '0',
    N_SIGN_POSN       => '4',
    POSITIVE_SIGN     => '',
    P_CS_PRECEDES     => '1',
    P_SEP_BY_SPACE    => '0',
);

# NOTE: The following values are inconstent depending on system locale
# definitions.  Therefore they are not tested:
#   P_SIGN_POSN

# there are several YEN symbols which the system locale might use.  Any of
# these are acceptable.
# - U+00A5  YEN SIGN
# - U+FFE5  FULLWIDTH YEN SIGN
my @CurrencySymbols = ("\x{a5}", "\x{ffe5}");

subtest 'ja_JP' => sub {
    plan_locale(ja_JP => 18);

    use_ok('Math::Currency::ja_JP');

    Math::Currency->localize(\$format);

    for my $param (sort keys %LocaleData) {
        if ($param eq 'CURRENCY_SYMBOL') {
            ok( grep { $format->{CURRENCY_SYMBOL} eq $_ } @CurrencySymbols );
        }
        else {
            is $format->{$param}, $LocaleData{$param},
                "format parameter $param = $LocaleData{$param}";
        }
    }

    my $obj = new_ok 'Math::Currency', ['12345.67', 'ja_JP'];

    ok index("$obj", $LocaleData{CURRENCY_SYMBOL}) != -1,
        'string contains currency symbol';
    ok index("$obj", $LocaleData{MON_THOUSANDS_SEP}) != -1,
        'string contains thousands separator';
};

subtest 'JPY' => sub {
    plan_locale(ja_JP => 18);

    use_ok('Math::Currency::JPY');

    Math::Currency->localize(\$format);

    for my $param (sort keys %LocaleData) {
        if ($param eq 'CURRENCY_SYMBOL') {
            ok( grep { $format->{CURRENCY_SYMBOL} eq $_ } @CurrencySymbols );
        }
        else {
            is $format->{$param}, $LocaleData{$param};
        }
    }

    my $obj = new_ok 'Math::Currency', ['12345.67', 'JPY'];

    ok index("$obj", $LocaleData{CURRENCY_SYMBOL}) != -1,
        'string contains currency symbol';
    ok index("$obj", $LocaleData{MON_THOUSANDS_SEP}) != -1,
        'string contains thousands separator';
};

