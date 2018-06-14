use strict;
use warnings;

use Test::More tests => 151;

BEGIN {use_ok('Finance::AMEX::Transaction')};

use lib '.';
use t::lib::CompareFile;

# source: https://github.com/lumoslabs/paxmex/blob/master/spec/parser_spec.rb
my $file = 't/data/dummy_cbnot_raw';

my $counts = {
  HEADER  => {want => 1, have => 0},
  TRAILER => {want => 1, have => 0},
  DETAIL  => {want => 1, have => 0},
};

my $data = do { local $/; <DATA> };

t::lib::CompareFile::compare('CBNOT', $file, $data, $counts);

done_testing();


__DATA__
{
  "HEADER": [{
    "REC_TYPE"                : "H",
    "AMEX_APPL_AREA"          : "010120170316      00",
    "APPLICATION_SYSTEM_CODE" : "01",
    "FILE_TYPE_CODE"          : "012",
    "FILE_CREATION_DATE"      : "20170316",
    "SAID"                    : "A57133",
    "DATATYPE"                : "CBNOT",
    "CCYYDDD"                 : "2017075",
    "HHMMSS"                  : "231306"
  }],
  "TRAILER": [{
    "REC_TYPE"                : "T",
    "AMEX_APPL_AREA"          : "010120170316      0000000000000007000000007",
    "APPLICATION_SYSTEM_CODE" : "01",
    "FILE_TYPE_CODE"          : "01",
    "FILE_CREATION_DATE"      : "20170316",
    "FILE_SEQUENCE_NUMBER"    : "000000",
    "JULIAN_DATE"             : "00",
    "AMEX_TOTAL_RECORDS"      : "00000",
    "CONFIRM_RECORD_COUNT"    : "000000007",
    "AMEX_JOB_NUMBER"         : "",
    "SAID"                    : "A57133",
    "DATATYPE"                : "CBNOT",
    "CCYYDDD"                 : "2017075",
    "HHMMSS"                  : "231306",
    "STARS_FILESEQ_NB"        : "001"
  }],
  "DETAIL": [{
    "REC_TYPE"                   : "D",
    "SE_NUMB"                    : "2040170029",
    "CM_ACCT_NUMB"               : "123481XXXXX4567",
    "CURRENT_CASE_NUMBER"        : "MCL5250",
    "FINCAP_TRACKING_ID_A"       : "MCL5250",

    "FINCAP_TRACKING_A_DATE"     : "MCL",
    "FINCAP_TRACKING_A_PCID"     : "5250",
    "FINCAP_TRACKING_A_SEQUENCE" : "",

    "CSS_CASE_NUMBER"            : "MCL5250",
    "SS_CASE_NUMBER"             : "MCL5250",
    "CURRENT_ACTION_NUMBER"      : "14",
    "PREVIOUS_CASE_NUMBER"       : "",
    "CSS_P_CASE_NUMBER"          : "",
    "PREVIOUS_ACTION_NUMBER"     : "",
    "RESOLUTION"                 : "N",
    "FROM_SYSTEM"                : "T",
    "REJECTS_TO_SYSTEM"          : "T",
    "DISPUTES_TO_SYSTEM"         : "T",
    "DATE_OF_ADJUSTMENT"         : "20170304",
    "DATE_OF_CHARGE"             : "20170213",
    "AMEX_ID"                    : "II6828A",
    "CASE_TYPE"                  : "FRAUD",
    "LOC_NUMB"                   : "000000000000000",
    "CB_REAS_CODE"               : "M11",
    "CB_AMOUNT"                  : " 0000000000129.99",
    "CB_ADJUSTMENT_NUMBER"       : "555964",
    "CB_RESOLUTION_ADJ_NUMBER"   : "",
    "CB_REFERENCE_CODE"          : "17499888",
    "BILLED_AMOUNT"              : " 0000000000129.99",
    "SOC_AMOUNT"                 : "",
    "SOC_INVOICE_NUMBER"         : "",
    "ROC_INVOICE_NUMBER"         : "",
    "FOREIGN_AMT"                : "",
    "CURRENCY"                   : "",
    "SUPP_TO_FOLLOW"             : "",
    "CM_NAME1"                   : "SYLVESTER D STALLONE",
    "CM_NAME2"                   : "",
    "CM_ADDR1"                   : "",
    "CM_ADDR2"                   : "",
    "CM_CITY_STATE"              : "",
    "CM_ZIP"                     : "",
    "CM_FIRST_NAME_1"            : "SYLVESTER",
    "CM_MIDDLE_NAME_1"           : "D",
    "CM_LAST_NAME_1"             : "STALLONE",
    "CM_ORIG_ACCT_NUM"           : "123481XXXXX4567",
    "CM_ORIG_NAME"               : "",
    "CM_ORIG_FIRST_NAME"         : "",
    "CM_ORIG_MIDDLE_NAME"        : "",
    "CM_ORIG_LAST_NAME"          : "",
    "NOTE1"                      : "",
    "NOTE2"                      : "",
    "NOTE3"                      : "",
    "NOTE4"                      : "",
    "NOTE5"                      : "LUMOSITY.COM                              17499888    877-77",
    "NOTE6"                      : "7-0502",
    "NOTE7"                      : "",
    "TRIUMPH_SEQ_NO"             : "01",
    "AIRLINE_TKT_NUM"            : "",
    "AL_SEQUENCE_NUMBER"         : "",
    "FOLIO_REF"                  : "",
    "MERCH_ORDER_NUM"            : "",
    "MERCH_ORDER_DATE"           : "",
    "CANC_NUM"                   : "",
    "CANC_DATE"                  : "",
    "FINCAP_TRACKING_ID"         : "",

    "FINCAP_TRACKING_DATE"       : "",
    "FINCAP_TRACKING_PCID"       : "",
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
    "CM_ACCNT_NUMB_EXD"          : "123481XXXXX4567",
    "CASE_NUMBER_EXD"            : "MCL5250",
    "IND_FORM_CODE"              : "NP",
    "IND_REF_NUMBER"             : "17499571",
    "LOC_REF_NUMBER"             : "",
    "PASSENGER_NAME"             : "",
    "PASSENGER_FIRST_NAME"       : "",
    "PASSENGER_MIDDLE_NAME"      : "",
    "PASSENGER_LAST_NAME"        : "",
    "SE_PROCESS_DATE"            : "044",
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
