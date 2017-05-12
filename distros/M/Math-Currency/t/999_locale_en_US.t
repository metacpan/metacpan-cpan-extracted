#!/usr/bin/env perl

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
    CURRENCY_SYMBOL   => '$',
    FRAC_DIGITS       => '2',
    INT_CURR_SYMBOL   => 'USD ',
    INT_FRAC_DIGITS   => '2',
    MON_DECIMAL_POINT => '.',
    MON_GROUPING      => '3',
    MON_THOUSANDS_SEP => ',',
    NEGATIVE_SIGN     => '-',
    N_CS_PRECEDES     => '1',
    N_SEP_BY_SPACE    => '0',
    N_SIGN_POSN       => '1',
    POSITIVE_SIGN     => '',
    P_CS_PRECEDES     => '1',
    P_SEP_BY_SPACE    => '0',
    P_SIGN_POSN       => '1',
);

subtest 'en_US' => sub {
    plan_locale(en_US => 19);

    use_ok('Math::Currency::en_US');

    Math::Currency->localize(\$format);

    for my $param (sort keys %LocaleData) {
        is $format->{$param}, $LocaleData{$param};
    }

    my $obj = new_ok 'Math::Currency', ['12345.67', 'en_US'];

    ok index("$obj", $LocaleData{CURRENCY_SYMBOL}) != -1,
        'string contains currency symbol';
    ok index("$obj", $LocaleData{MON_THOUSANDS_SEP}) != -1,
        'string contains thousands separator';
};

subtest 'USD' => sub {
    plan_locale(en_US => 19);

    use_ok('Math::Currency::USD');

    Math::Currency->localize(\$format);

    for my $param (sort keys %LocaleData) {
        is $format->{$param}, $LocaleData{$param};
    }

    my $obj = new_ok 'Math::Currency', ['12345.67', 'USD'];

    ok index("$obj", $LocaleData{CURRENCY_SYMBOL}) != -1,
        'string contains currency symbol';
    ok index("$obj", $LocaleData{MON_THOUSANDS_SEP}) != -1,
        'string contains thousands separator';
};

