#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 151;

BEGIN {use_ok('Finance::AMEX::Transaction')}

use lib '.';
use t::lib::CompareFile;

my $file = 't/data/AMEX/CBNOT sample test file.txt';

my $counts = {
  HEADER  => {want => 1, have => 0},
  TRAILER => {want => 1, have => 0},
  DETAIL  => {want => 1, have => 0},
};

my $data = do {local $/ = undef; <DATA>};

t::lib::CompareFile::compare('CBNOT', $file, $data, $counts);

done_testing();

__DATA__
{
  "HEADER": [{
    "REC_TYPE"                : "H",
    "AMEX_APPL_AREA"          : "010120130421      00",
    "APPLICATION_SYSTEM_CODE" : "01",
    "FILE_TYPE_CODE"          : "012",
    "FILE_CREATION_DATE"      : "20130421",
    "SAID"                    : "A00070",
    "DATATYPE"                : "CBNOT",
    "CCYYDDD"                 : "2013186",
    "HHMMSS"                  : "230516"
  }],
  "TRAILER": [{
    "REC_TYPE"                : "T",
    "AMEX_APPL_AREA"          : "010120130421      0000000000000005000000005",
    "APPLICATION_SYSTEM_CODE" : "01",
    "FILE_TYPE_CODE"          : "01",
    "FILE_CREATION_DATE"      : "20130421",
    "FILE_SEQUENCE_NUMBER"    : "000000",
    "JULIAN_DATE"             : "00",
    "AMEX_TOTAL_RECORDS"      : "00000",
    "CONFIRM_RECORD_COUNT"    : "000000005",
    "AMEX_JOB_NUMBER"         : "",
    "SAID"                    : "A00070",
    "DATATYPE"                : "CBNOT",
    "CCYYDDD"                 : "2013186",
    "HHMMSS"                  : "230516",
    "STARS_FILESEQ_NB"        : "001"
  }],
  "DETAIL": [{
    "REC_TYPE"                   : "D",
    "SE_NUMB"                    : "1116725407",
    "CM_ACCT_NUMB"               : "371511XXXXX2097",
    "CURRENT_CASE_NUMBER"        : "861AATK",

    "FINCAP_TRACKING_ID_A"       : "861AATK",

    "FINCAP_TRACKING_A_DATE"     : "861",
    "FINCAP_TRACKING_A_PCID"     : "AATK",
    "FINCAP_TRACKING_A_SEQUENCE" : "",

    "CSS_CASE_NUMBER"            : "861AATK",
    "SS_CASE_NUMBER"             : "861AATK",
    "CURRENT_ACTION_NUMBER"      : "10",
    "PREVIOUS_CASE_NUMBER"       : "",
    "CSS_P_CASE_NUMBER"          : "",
    "PREVIOUS_ACTION_NUMBER"     : "",
    "RESOLUTION"                 : "N",
    "FROM_SYSTEM"                : "X",
    "REJECTS_TO_SYSTEM"          : "P",
    "DISPUTES_TO_SYSTEM"         : "P",
    "DATE_OF_ADJUSTMENT"         : "20130704",
    "DATE_OF_CHARGE"             : "20130601",
    "AMEX_ID"                    : "RULES",
    "CASE_TYPE"                  : "SEDIS",
    "LOC_NUMB"                   : "000000000000000",
    "CB_REAS_CODE"               : "R13",
    "CB_AMOUNT"                  : "-0000000000012.35",
    "CB_ADJUSTMENT_NUMBER"       : "258226",
    "CB_RESOLUTION_ADJ_NUMBER"   : "",
    "CB_REFERENCE_CODE"          : "000025160",
    "BILLED_AMOUNT"              : " 0000000000012.35",
    "SOC_AMOUNT"                 : " 0000000000000.00",
    "SOC_INVOICE_NUMBER"         : "",
    "ROC_INVOICE_NUMBER"         : "",
    "FOREIGN_AMT"                : "",
    "CURRENCY"                   : "",
    "SUPP_TO_FOLLOW"             : "Y",
    "CM_NAME1"                   : "NA",
    "CM_NAME2"                   : "",
    "CM_ADDR1"                   : "",
    "CM_ADDR2"                   : "",
    "CM_CITY_STATE"              : "",
    "CM_ZIP"                     : "",
    "CM_FIRST_NAME_1"            : "",
    "CM_MIDDLE_NAME_1"           : "",
    "CM_LAST_NAME_1"             : "",
    "CM_ORIG_ACCT_NUM"           : "371511XXXXX2097",
    "CM_ORIG_NAME"               : "NA",
    "CM_ORIG_FIRST_NAME"         : "",
    "CM_ORIG_MIDDLE_NAME"        : "",
    "CM_ORIG_LAST_NAME"          : "",
    "NOTE1"                      : "",
    "NOTE2"                      : "",
    "NOTE3"                      : "",
    "NOTE4"                      : "",
    "NOTE5"                      : "",
    "NOTE6"                      : "",
    "NOTE7"                      : "",
    "TRIUMPH_SEQ_NO"             : "",
    "AIRLINE_TKT_NUM"            : "",
    "AL_SEQUENCE_NUMBER"         : "",
    "FOLIO_REF"                  : "000025160",
    "MERCH_ORDER_NUM"            : "",
    "MERCH_ORDER_DATE"           : "",
    "CANC_NUM"                   : "",
    "CANC_DATE"                  : "",
    "FINCAP_TRACKING_ID"         : "861AATK",

    "FINCAP_TRACKING_DATE"       : "861",
    "FINCAP_TRACKING_PCID"       : "AATK",
    "FINCAP_TRACKING_SEQUENCE"   : "",

    "FINCAP_FILE_SEQ_NUM"        : "",
    "FINCAP_BATCH_NUMBER"        : "",
    "FINCAP_BATCH_INVOICE_DT"    : "",
    "LABEL1"                     : "",
    "DATA1"                      : "",
    "LABEL2"                     : "",
    "DATA2"                      : "",
    "LABEL3"                     : "",
    "DATA3"                      : "",
    "LABEL4"                     : "",
    "DATA4"                      : "",
    "LABEL5"                     : "",
    "DATA5"                      : "",
    "LABEL6"                     : "",
    "DATA6"                      : "",
    "LABEL7"                     : "",
    "DATA7"                      : "",
    "LABEL8"                     : "",
    "DATA8"                      : "",
    "LABEL9"                     : "",
    "DATA9"                      : "",
    "LABEL10"                    : "",
    "DATA10"                     : "",
    "LABEL11"                    : "",
    "DATA11"                     : "",
    "CM_ACCNT_NUMB_EXD"          : "",
    "CASE_NUMBER_EXD"            : "",
    "IND_FORM_CODE"              : "NP",
    "IND_REF_NUMBER"             : "0000251600018206",
    "LOC_REF_NUMBER"             : "",
    "PASSENGER_NAME"             : "",
    "PASSENGER_FIRST_NAME"       : "",
    "PASSENGER_MIDDLE_NAME"      : "",
    "PASSENGER_LAST_NAME"        : "",
    "SE_PROCESS_DATE"            : "",
    "RETURN_DATE"                : "",
    "CREDIT_RECEIPT_NUMBER"      : "",
    "RETURN_TO_NAME"             : "",
    "RETURN_TO_STREET"           : "",
    "CARD_DEPOSIT"               : "",
    "ASSURED_RESERVATION"        : "",
    "RES_CANCELLED"              : "",
    "RES_CANCELLED_DATE"         : "",
    "CANCEL_ZONE"                : "",
    "RESERVATION_MADE_FOR"       : "",
    "RESERVATION_LOCATION"       : "",
    "RESERVATION_MADE_ON"        : "",
    "RENTAL_AGREEMENT_NUMBER"    : "",
    "MERCHANDISE_TYPE"           : "",
    "MERCHANDISE_RETURNED"       : "",
    "RETURNED_NAME"              : "",
    "RETURNED_DATE"              : "",
    "RETURNED_HOW"               : "",
    "RETURNED_REASON"            : "",
    "STORE_CREDIT_RECEIVED"      : ""
  }]
}
