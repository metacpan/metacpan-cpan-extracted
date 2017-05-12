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
    CURRENCY_SYMBOL   => '€',
    FRAC_DIGITS       => '2',
    INT_CURR_SYMBOL   => 'EUR ',
    INT_FRAC_DIGITS   => '2',
    MON_DECIMAL_POINT => ',',
    MON_GROUPING      => '3',
    MON_THOUSANDS_SEP => '.',
    NEGATIVE_SIGN     => '-',
    N_SIGN_POSN       => '1',
    POSITIVE_SIGN     => '',
);

# NOTE: The following values are inconstent depending on system locale
# definitions.  Therefore they are not tested:
#    N_SEP_BY_SPACE
#    N_CS_PRECEDES
#    P_CS_PRECEDES
#    P_SEP_BY_SPACE
#    P_SIGN_POSN


# there are several currency symbols here that the system locale
# might use.  Any of these are acceptable.
# - The string "Eu"
# - The string "EUR"
# - U+20AC  EURO SIGN
# - U+20A0  EURO CURRENCY SIGN
my @CurrencySymbols = ('Eu', 'EUR', '€', "\x{20a0}");

subtest 'de_DE' => sub {
    plan_locale(de_DE => 14);

    use_ok('Math::Currency::de_DE');

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

    my $obj = new_ok 'Math::Currency', ['12345.67', 'de_DE'];

    # stringification always uses the module LocaleData{CURRENCY_SYMBOL}
    ok index("$obj", $LocaleData{CURRENCY_SYMBOL}) != -1,
        'string contains currency symbol';
    ok index("$obj", $LocaleData{MON_THOUSANDS_SEP}) != -1,
        'string contains thousands separator';
};

subtest 'EUR' => sub {
    plan_locale(de_DE => 14);

    use_ok('Math::Currency::EUR');

    Math::Currency->localize(\$format);

    for my $param (sort keys %LocaleData) {
        if ($param eq 'CURRENCY_SYMBOL') {
            ok( grep { $format->{CURRENCY_SYMBOL} eq $_ } @CurrencySymbols );
        }
        else {
            is $format->{$param}, $LocaleData{$param};
        }
    }

    my $obj = new_ok 'Math::Currency', ['12345.67', 'EUR'];

    # stringification always uses the module LocaleData{CURRENCY_SYMBOL}
    ok index("$obj", $LocaleData{CURRENCY_SYMBOL}) != -1,
        'string contains currency symbol';
    ok index("$obj", $LocaleData{MON_THOUSANDS_SEP}) != -1,
        'string contains thousands separator';
};

