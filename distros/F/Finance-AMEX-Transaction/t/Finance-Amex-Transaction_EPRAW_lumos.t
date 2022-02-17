#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 66;

BEGIN {use_ok('Finance::AMEX::Transaction')}

use lib '.';
use t::lib::CompareFile;

# source: https://github.com/lumoslabs/paxmex/blob/master/spec/parser_spec.rb
my $file = 't/data/paxmex/dummy_epraw_raw';

my $counts = {
  HEADER            => {want => 1, have => 0},
  TRAILER           => {want => 1, have => 0},
  SUMMARY           => {want => 1, have => 0},
  SOC_DETAIL        => {want => 1, have => 0},
  CHARGEBACK_DETAIL => {want => 0, have => 0},
  ADJUSTMENT_DETAIL => {want => 0, have => 0},
  OTHER_DETAIL      => {want => 0, have => 0},
};

my $data = do {local $/ = undef; <DATA>};

t::lib::CompareFile::compare('EPRAW', $file, $data, $counts);

done_testing();

__DATA__
{
  "HEADER": [{
    "DF_HDR_RECORD_TYPE" : "DFHDR",
    "DF_HDR_DATE"        : "03082013",
    "DF_HDR_TIME"        : "0435",
    "DF_HDR_FILE_ID"     : "000000",
    "DF_HDR_FILE_NAME"   : "LUMOS LABS INC"
  }],
  "TRAILER": [{
    "DF_TRL_RECORD_TYPE"   : "DFTRL",
    "DF_TRL_DATE"          : "03082013",
    "DF_TRL_TIME"          : "0435",
    "DF_TRL_FILE_ID"       : "000000",
    "DF_TRL_FILE_NAME"     : "LUMOS LABS INC",
    "DF_TRL_RECIPIENT_KEY" : "00000000002754170029          0000000000",
    "DF_TRL_RECORD_COUNT"  : "0000004"
  }],
  "SUMMARY": [{
    "AMEX_PAYEE_NUMBER"     : "1234567890",
    "AMEX_SORT_FIELD_1"     : "0000000000",
    "AMEX_SORT_FIELD_2"     : "0000000000",
    "PAYMENT_YEAR"          : "2013",
    "PAYMENT_NUMBER"        : "066M1416",
    "PAYMENT_NUMBER_DATE"   : "066",
    "PAYMENT_NUMBER_TYPE"   : "M",
    "PAYMENT_NUMBER_NUMBER" : "1416",
    "RECORD_TYPE"           : "1",
    "DETAIL_RECORD_TYPE"    : "00",
    "PAYMENT_DATE"          : "2013068",
    "PAYMENT_AMOUNT"        : "0000226124C",
    "DEBIT_BALANCE_AMOUNT"  : "00000000{",
    "ABA_BANK_NUMBER"       : "123140399",
    "SE_DDA_NUMBER"         : "0000123000"
  }],
  "SOC_DETAIL": [{
    "AMEX_PAYEE_NUMBER"         : "2041230025",
    "AMEX_SE_NUMBER"            : "6740170029",
    "SE_UNIT_NUMBER"            : "",
    "PAYMENT_YEAR"              : "2013",
    "PAYMENT_NUMBER"            : "066M6956",
    "PAYMENT_NUMBER_DATE"       : "066",
    "PAYMENT_NUMBER_TYPE"       : "M",
    "PAYMENT_NUMBER_NUMBER"     : "6956",
    "RECORD_TYPE"               : "2",
    "DETAIL_RECORD_TYPE"        : "10",
    "SE_BUSINESS_DATE"          : "2013045",
    "AMEX_PROCESS_DATE"         : "2013065",
    "SOC_INVOICE_NUMBER"        : "000167",
    "SOC_AMOUNT"                : "0000226124C",
    "DISCOUNT_AMOUNT"           : "00002254H",
    "SERVICE_FEE_AMOUNT"        : "000073H",
    "NET_SOC_AMOUNT"            : "0000126124C",
    "DISCOUNT_RATE"             : "03500",
    "SERVICE_FEE_RATE"          : "00030",
    "AMEX_GROSS_AMOUNT"         : "0000244124C",
    "AMEX_ROC_COUNT"            : "0040E",
    "TRACKING_ID"               : "065028576",
    "TRACKING_ID_DATE"          : "065",
    "TRACKING_ID_PCID"          : "028576",
    "CPC_INDICATOR"             : "",
    "AMEX_ROC_COUNT_POA"        : "000040E",
    "SERVICE_AGENT_MERCHANT_ID" : "",
    "OPTIMA_DIVIDEND_AMOUNT"    : "000000{",
    "OPTIMA_DIVIDEND_RATE"      : "00000",
    "OPTIMA_GROSS_AMOUNT"       : "0000000000{",
    "OPTIMA_ROC_COUNT"          : "0000{"
    }
  ]
}
