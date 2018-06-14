
use strict;
use warnings;

use Test::More tests => 91;

BEGIN {use_ok('Finance::AMEX::Transaction')};

use lib '.';
use t::lib::CompareFile;

# source: https://github.com/lumoslabs/paxmex/blob/master/spec/parser_spec.rb
my $file = 't/data/dummy_eptrn_raw';

my $counts = {
  HEADER            => {want => 1, have => 0},
  TRAILER           => {want => 1, have => 0},
  SUMMARY           => {want => 1, have => 0},
  SOC_DETAIL        => {want => 1, have => 0},
  ROC_DETAIL        => {want => 1, have => 0},
  CHARGEBACK_DETAIL => {want => 0, have => 0},
  ADJUSTMENT_DETAIL => {want => 0, have => 0},
  OTHER_DETAIL      => {want => 0, have => 0},
};

my $data = do { local $/; <DATA> };

t::lib::CompareFile::compare('EPTRN', $file, $data, $counts);

done_testing();


__DATA__
{
  "HEADER": [{
    "DF_HDR_RECORD_TYPE" : "DFHDR",
    "DF_HDR_DATE"        : "03082013",
    "DF_HDR_TIME"        : "0452",
    "DF_HDR_FILE_ID"     : "000000",
    "DF_HDR_FILE_NAME"   : "LUMOS LABS INC"
  }],
  "TRAILER": [{
    "DF_TRL_RECORD_TYPE"   : "DFTRL",
    "DF_TRL_DATE"          : "03082013",
    "DF_TRL_TIME"          : "0452",
    "DF_TRL_FILE_ID"       : "000000",
    "DF_TRL_FILE_NAME"     : "LUMOS LABS INC",
    "DF_TRL_RECIPIENT_KEY" : "00000000003491124567          0000000000",
    "DF_TRL_RECORD_COUNT"  : "0000004"
  }],
  "SUMMARY": [{
    "AMEX_PAYEE_NUMBER"     : "3491124567",
    "AMEX_SORT_FIELD_1"     : "0000000000",
    "AMEX_SORT_FIELD_2"     : "0000000000",
    "PAYMENT_YEAR"          : "2013",
    "PAYMENT_NUMBER"        : "DUMT1234",
    "PAYMENT_NUMBER_DATE"   : "DUM",
    "PAYMENT_NUMBER_TYPE"   : "T",
    "PAYMENT_NUMBER_NUMBER" : "1234",
    "RECORD_TYPE"           : "1",
    "DETAIL_RECORD_TYPE"    : "00",
    "PAYMENT_DATE"          : "2013068",
    "PAYMENT_AMOUNT"        : "0000500355D",
    "DEBIT_BALANCE_AMOUNT"  : "00000000{",
    "ABA_BANK_NUMBER"       : "121140399",
    "SE_DDA_NUMBER"         : "0000004000"
  }],
  "SOC_DETAIL": [{
    "AMEX_PAYEE_NUMBER"     : "3491124567",
    "AMEX_SE_NUMBER"        : "3491124567",
    "SE_UNIT_NUMBER"        : "",
    "PAYMENT_YEAR"          : "2013",
    "PAYMENT_NUMBER"        : "DUMT1234",
    "PAYMENT_NUMBER_DATE"   : "DUM",
    "PAYMENT_NUMBER_TYPE"   : "T",
    "PAYMENT_NUMBER_NUMBER" : "1234",
    "RECORD_TYPE"           : "2",
    "DETAIL_RECORD_TYPE"    : "10",
    "SE_BUSINESS_DATE"      : "2013065",
    "AMEX_PROCESS_DATE"     : "2013065",
    "SOC_INVOICE_NUMBER"    : "000140",
    "SOC_AMOUNT"            : "0000500355D",
    "DISCOUNT_AMOUNT"       : "00008354H",
    "SERVICE_FEE_AMOUNT"    : "000073H",
    "NET_SOC_AMOUNT"        : "0000500355D",
    "DISCOUNT_RATE"         : "03500",
    "SERVICE_FEE_RATE"      : "00030",
    "AMEX_GROSS_AMOUNT"     : "0000500355D",
    "AMEX_ROC_COUNT"        : "0040E",
    "TRACKING_ID"           : "065013192",
    "TRACKING_ID_DATE"      : "065",
    "TRACKING_ID_PCID"      : "013192",
    "CPC_INDICATOR"         : "",
    "AMEX_ROC_COUNT_POA"    : "000040E",
    "BASE_DISCOUNT_AMOUNT"  : "-000000000078979"
  }],
  "ROC_DETAIL": [{
    "TLRR_AMEX_PAYEE_NUMBER"     : "3491124567",
    "TLRR_AMEX_SE_NUMBER"        : "3491124567",
    "TLRR_SE_UNIT_NUMBER"        : "",
    "TLRR_PAYMENT_YEAR"          : "2013",
    "TLRR_PAYMENT_NUMBER"        : "DUMT1235",
    "TLRR_PAYMENT_NUMBER_DATE"   : "DUM",
    "TLRR_PAYMENT_NUMBER_TYPE"   : "T",
    "TLRR_PAYMENT_NUMBER_NUMBER" : "1235",
    "TLRR_RECORD_TYPE"           : "3",
    "TLRR_DETAIL_RECORD_TYPE"    : "11",
    "TLRR_SE_BUSINESS_DATE"      : "2013065",
    "TLRR_AMEX_PROCESS_DATE"     : "2013065",
    "TLRR_SOC_INVOICE_NUMBER"    : "000141",
    "TLRR_SOC_AMOUNT"            : "000000003730E",
    "TLRR_ROC_AMOUNT"            : "000000003730E",
    "TLRR_CM_NUMBER"             : "000000050000512",
    "TLRR_CM_REF_NO"             : "12345LMNA11",
    "TLRR_SE_REF"                : "",
    "TLRR_ROC_NUMBER"            : "",
    "TLRR_TRAN_DATE"             : "2013065",
    "TLRR_SE_REF_POA"            : "0355D0040E0650131920000000000A",
    "NON_COMPLIANT_INDICATOR"    : "",
    "NON_COMPLIANT_ERROR_CODE_1" : "",
    "NON_COMPLIANT_ERROR_CODE_2" : "",
    "NON_COMPLIANT_ERROR_CODE_3" : "",
    "NON_COMPLIANT_ERROR_CODE_4" : "",
    "NON_SWIPED_INDICATOR"       : "",
    "TLRR_CM_NUMB_EXD"           : "000000000000000 000"
  }],
  "CHARGEBACK_DETAIL": [],
  "ADJUSTMENT_DETAIL": [],
  "OTHER_DETAIL": []

}
