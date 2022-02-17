#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 34;

BEGIN {use_ok('Finance::AMEX::Transaction::GRRCN::TxnPricing')}
BEGIN {use_ok('Finance::AMEX::Transaction::GRRCN::FeeRevenue')}

use lib '.';
use t::lib::CompareFile;

# this file tests the differences between 2.01 and 3.01 version of TXNPRICING and FEEREVENUE lines

# these test files can only have one line in them
my $txn_pricing_v2 = 't/data/local/grrcn.TXNPRICING.v2';
my $txn_pricing_v3 = 't/data/local/grrcn.TXNPRICING.v3';

my $fee_revenue_v2 = 't/data/local/grrcn.FEEREVENUE.v2';
my $fee_revenue_v3 = 't/data/local/grrcn.FEEREVENUE.v3';

my $format = 'CSV';

{    # test v2 TxnPricing
  my $file_version = '2.01';

  my $parsed = Finance::AMEX::Transaction::GRRCN::TxnPricing->new(
    line         => t::lib::CompareFile::slurp($txn_pricing_v2),
    file_format  => $format,
    file_version => $file_version,
  );

  ok(exists $parsed->fields->{RECORD_TYPE},                      'We have a RECORD_TYPE for v2');
  ok(! exists $parsed->fields->{ROUNDED_FEE_AMOUNT},             'We do not have a ROUNDED_FEE_AMOUNT for v2');
  ok(! exists $parsed->fields->{ROUNDED_DISCOUNT_AMOUNT},        'We do not have a ROUNDED_DISCOUNT_AMOUNT for v2');
  ok(! exists $parsed->fields->{FEE_AMOUNT_SETTLEMENT_CURRENCY}, 'We do not have a FEE_AMOUNT_SETTLEMENT_CURRENCY for v2');
  ok(
    ! exists $parsed->fields->{DISCOUNT_AMOUNT_SETTLEMENT_CURRENCY},
    'We do not have a DISCOUNT_AMOUNT_SETTLEMENT_CURRENCY for v2'
  );
  ok(
    ! exists $parsed->fields->{TRANSACTION_AMOUNT_SETTLEMENT_CURRENCY},
    'We do not have a TRANSACTION_AMOUNT_SETTLEMENT_CURRENCY for v2'
  );

  is($parsed->RECORD_TYPE,                    'TXNPRICING', 'RECORD_TYPE value is correct for v2');
  is($parsed->ROUNDED_FEE_AMOUNT,             undef,        'ROUNDED_FEE_AMOUNT value is correct for v2 (undef)');
  is($parsed->ROUNDED_DISCOUNT_AMOUNT,        undef,        'ROUNDED_DISCOUNT_AMOUNT value is correct for v2 (undef)');
  is($parsed->FEE_AMOUNT_SETTLEMENT_CURRENCY, undef, 'FEE_AMOUNT_SETTLEMENT_CURRENCY value is correct for v2 (undef)');
  is($parsed->DISCOUNT_AMOUNT_SETTLEMENT_CURRENCY,
    undef, 'DISCOUNT_AMOUNT_SETTLEMENT_CURRENCY value is correct for v2 (undef)');
  is($parsed->TRANSACTION_AMOUNT_SETTLEMENT_CURRENCY,
    undef, 'TRANSACTION_AMOUNT_SETTLEMENT_CURRENCY value is correct for v2 (undef)');
}

{    # test v3 TxnPricing
  my $file_version = '3.01';

  my $parsed = Finance::AMEX::Transaction::GRRCN::TxnPricing->new(
    line         => t::lib::CompareFile::slurp($txn_pricing_v3),
    file_format  => $format,
    file_version => $file_version,
  );

  ok(exists $parsed->fields->{RECORD_TYPE},                         'We have a RECORD_TYPE for v3');
  ok(exists $parsed->fields->{ROUNDED_FEE_AMOUNT},                  'We have a ROUNDED_FEE_AMOUNT for v3');
  ok(exists $parsed->fields->{ROUNDED_DISCOUNT_AMOUNT},             'We have a ROUNDED_DISCOUNT_AMOUNT for v3');
  ok(exists $parsed->fields->{FEE_AMOUNT_SETTLEMENT_CURRENCY},      'We have a FEE_AMOUNT_SETTLEMENT_CURRENCY for v3');
  ok(exists $parsed->fields->{DISCOUNT_AMOUNT_SETTLEMENT_CURRENCY}, 'We have a DISCOUNT_AMOUNT_SETTLEMENT_CURRENCY for v3');
  ok(
    exists $parsed->fields->{TRANSACTION_AMOUNT_SETTLEMENT_CURRENCY},
    'We have a TRANSACTION_AMOUNT_SETTLEMENT_CURRENCY for v3'
  );

  is($parsed->RECORD_TYPE,             'TXNPRICING',   'RECORD_TYPE value is correct for v3');
  is($parsed->ROUNDED_FEE_AMOUNT,      'rnd_fee',      'ROUNDED_FEE_AMOUNT value is correct for v3');
  is($parsed->ROUNDED_DISCOUNT_AMOUNT, 'rnd_discount', 'ROUNDED_DISCOUNT_AMOUNT value is correct for v3');
  is($parsed->FEE_AMOUNT_SETTLEMENT_CURRENCY,
    'fee_amount_settlement', 'FEE_AMOUNT_SETTLEMENT_CURRENCY value is correct for v3');
  is($parsed->DISCOUNT_AMOUNT_SETTLEMENT_CURRENCY,
    'discount_amount_settlement', 'DISCOUNT_AMOUNT_SETTLEMENT_CURRENCY value is correct for v3');
  is(
    $parsed->TRANSACTION_AMOUNT_SETTLEMENT_CURRENCY,
    'transaction_amount_settlement',
    'TRANSACTION_AMOUNT_SETTLEMENT_CURRENCY value is correct for v3'
  );
}

{    # test v2 FeeRevenue
  my $file_version = '2.01';

  my $parsed = Finance::AMEX::Transaction::GRRCN::FeeRevenue->new(
    line         => t::lib::CompareFile::slurp($fee_revenue_v2),
    file_format  => $format,
    file_version => $file_version,
  );

  ok(exists $parsed->fields->{RECORD_TYPE}, 'We have a RECORD_TYPE for v2');
  ok(! exists $parsed->fields->{SELLER_ID}, 'We do not have a SELLER_ID for v2');

  is($parsed->RECORD_TYPE, 'FEEREVENUE', 'RECORD_TYPE value is correct for v2');
  is($parsed->SELLER_ID,   undef,        'SELLER_ID value is correct for v2 (undef)');
}

{    # test v3 FeeRevenue
  my $file_version = '3.01';

  my $parsed = Finance::AMEX::Transaction::GRRCN::FeeRevenue->new(
    line         => t::lib::CompareFile::slurp($fee_revenue_v3),
    file_format  => $format,
    file_version => $file_version,
  );

  ok(exists $parsed->fields->{RECORD_TYPE}, 'We have a RECORD_TYPE for v3');
  ok(exists $parsed->fields->{SELLER_ID},   'We have a SELLER_ID for v3');

  is($parsed->RECORD_TYPE, 'FEEREVENUE', 'RECORD_TYPE value is correct for v3');
  is($parsed->SELLER_ID,   'seller_id',  'SELLER_ID value is correct for v3');
}
done_testing();
