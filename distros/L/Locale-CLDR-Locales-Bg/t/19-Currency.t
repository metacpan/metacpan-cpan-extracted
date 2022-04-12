#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 25;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('bg_BG');

is($locale->format_number(12345678, '¤###,###'), 'лв.12 345 678,00', 'Format number for currency with default currency');
is($locale->format_number(12345678.9, '¤###,###', 'USD'), 'US$12 345 678,90', 'Format number for currency with explicit currency');

is($locale->currency_format('standard'), '0.00 ¤', 'Standard currency format');
is($locale->currency_format('accounting'), '0.00 ¤;(0.00 ¤)', 'Accountcy currency format');

$locale = Locale::CLDR->new('bg_BG_u_cf_standard');
is($locale->currency_format(), '0.00 ¤', 'Currency format with standard default');
is($locale->format_currency(123456.78), '123456,78 лв.', 'Format currency with standard format, positive number and financial rounding');
is($locale->format_currency(123456.78, 'cash'), '123456,78 лв.', 'Format currency with standard format, positive number and cash rounding');
is($locale->format_currency(-123456.78), '-123456,78 лв.', 'Format currency with standard format, negitive number and financial rounding');
is($locale->format_currency(-123456.78, 'cash'), '-123456,78 лв.', 'Format currency with standard format, negitive number and cash rounding');

$locale = Locale::CLDR->new('bg_BG_u_cf_standard_cu_eur');
is($locale->currency_format(), '0.00 ¤', 'Currency format with standard default and euro currency');
is($locale->format_currency(123456.78), '123456,78 €', 'Format currency with standard format, positive number and financial rounding and euro currency');
is($locale->format_currency(123456.78, 'cash'), '123456,78 €', 'Format currency with standard format, positive number and cash rounding and euro currency');
is($locale->format_currency(-123456.78), '-123456,78 €', 'Format currency with standard format, negitive number and financial rounding and euro currency');
is($locale->format_currency(-123456.78, 'cash'), '-123456,78 €', 'Format currency with standard format, negitive number and cash rounding and euro currency');

$locale = Locale::CLDR->new('bg_BG_u_cf_account');
is($locale->currency_format(), '0.00 ¤;(0.00 ¤)', 'Currency format with account default');
is($locale->format_currency(123456.78), '123456,78 лв.', 'Format currency with accountancy format, positive number and financial rounding');
is($locale->format_currency(123456.78, 'cash'), '123456,78 лв.', 'Format currency with accountancy format, positive number and cash rounding');
is($locale->format_currency(-123456.78), '(123456,78 лв.)', 'Format currency with accountancy format, negitive number and financial rounding');
is($locale->format_currency(-123456.78, 'cash'), '(123456,78 лв.)', 'Format currency with accountancy format, negitive number and cash rounding');

$locale = Locale::CLDR->new('bg_BG_u_cf_account_cu_eur');
is($locale->currency_format(), '0.00 ¤;(0.00 ¤)', 'Currency format with account default');
is($locale->format_currency(123456.78), '123456,78 €', 'Format currency with accountancy format, positive number and financial rounding and euro currency');
is($locale->format_currency(123456.78, 'cash'), '123456,78 €', 'Format currency with accountancy format, positive number and cash rounding and euro currency');
is($locale->format_currency(-123456.78), '(123456,78 €)', 'Format currency with accountancy format, negitive number and financial rounding and euro currency');
is($locale->format_currency(-123456.78, 'cash'), '(123456,78 €)', 'Format currency with accountancy format, negitive number and cash rounding and euro currency')