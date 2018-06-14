package Finance::AMEX::Transaction::CBNOT::Detail;
$Finance::AMEX::Transaction::CBNOT::Detail::VERSION = '0.002';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Chargeback Notification Files (CBNOT) Detail Rows

use base 'Finance::AMEX::Transaction::CBNOT::Base';

sub field_map {
  return {
    REC_TYPE                   => [1, 1],
    SE_NUMB                    => [7, 10],
    CM_ACCT_NUMB               => [27, 19],
    CURRENT_CASE_NUMBER        => [47, 11],
    FINCAP_TRACKING_ID_A       => [47, 11],

    FINCAP_TRACKING_A_DATE     => [47, 3],
    FINCAP_TRACKING_A_PCID     => [50, 6],
    FINCAP_TRACKING_A_SEQUENCE => [56, 2],

    CSS_CASE_NUMBER            => [47, 7],
    SS_CASE_NUMBER             => [47, 9],
    CURRENT_ACTION_NUMBER      => [58, 2],
    PREVIOUS_CASE_NUMBER       => [60, 11],
    CSS_P_CASE_NUMBER          => [60, 11],
    PREVIOUS_ACTION_NUMBER     => [71, 2],
    RESOLUTION                 => [73, 1],
    FROM_SYSTEM                => [74, 1],
    REJECTS_TO_SYSTEM          => [75, 1],
    DISPUTES_TO_SYSTEM         => [76, 1],
    DATE_OF_ADJUSTMENT         => [77, 8],
    DATE_OF_CHARGE             => [85, 8],
    AMEX_ID                    => [93, 7],
    CASE_TYPE                  => [105, 6],
    LOC_NUMB                   => [111, 15],
    CB_REAS_CODE               => [126, 3],
    CB_AMOUNT                  => [129, 17],
    CB_ADJUSTMENT_NUMBER       => [146, 6],
    CB_RESOLUTION_ADJ_NUMBER   => [152, 6],
    CB_REFERENCE_CODE          => [158, 12],
    BILLED_AMOUNT              => [183, 17],
    SOC_AMOUNT                 => [200, 17],
    SOC_INVOICE_NUMBER         => [217, 6],
    ROC_INVOICE_NUMBER         => [223, 6],
    FOREIGN_AMT                => [229, 15],
    CURRENCY                   => [244, 3],
    SUPP_TO_FOLLOW             => [247, 1],
    CM_NAME1                   => [248, 30],
    CM_NAME2                   => [278, 30],
    CM_ADDR1                   => [308, 30],
    CM_ADDR2                   => [338, 30],
    CM_CITY_STATE              => [368, 30],
    CM_ZIP                     => [398, 9],
    CM_FIRST_NAME_1            => [407, 12],
    CM_MIDDLE_NAME_1           => [419, 12],
    CM_LAST_NAME_1             => [431, 20],
    CM_ORIG_ACCT_NUM           => [451, 15],
    CM_ORIG_NAME               => [466, 30],
    CM_ORIG_FIRST_NAME         => [496, 12],
    CM_ORIG_MIDDLE_NAME        => [508, 12],
    CM_ORIG_LAST_NAME          => [520, 20],
    NOTE1                      => [540, 66],
    NOTE2                      => [606, 78],
    NOTE3                      => [684, 60],
    NOTE4                      => [744, 60],
    NOTE5                      => [804, 60],
    NOTE6                      => [864, 60],
    NOTE7                      => [924, 60],
    TRIUMPH_SEQ_NO             => [984, 2],
    AIRLINE_TKT_NUM            => [1031, 14],
    AL_SEQUENCE_NUMBER         => [1045, 2],
    FOLIO_REF                  => [1047, 18],
    MERCH_ORDER_NUM            => [1065, 10],
    MERCH_ORDER_DATE           => [1075, 8],
    CANC_NUM                   => [1083, 20],
    CANC_DATE                  => [1103, 8],
    FINCAP_TRACKING_ID         => [1111, 11],

    FINCAP_TRACKING_DATE       => [1111, 3],
    FINCAP_TRACKING_PCID       => [1114, 6],
    FINCAP_TRACKING_SEQUENCE   => [1120, 2],

    FINCAP_FILE_SEQ_NUM        => [1122, 6],
    FINCAP_BATCH_NUMBER        => [1128, 4],
    FINCAP_BATCH_INVOICE_DT    => [1132, 8],
    LABEL1                     => [1140, 25],
    DATA1                      => [1165, 25],
    LABEL2                     => [1190, 25],
    DATA2                      => [1215, 25],
    LABEL3                     => [1240, 25],
    DATA3                      => [1265, 25],
    LABEL4                     => [1290, 25],
    DATA4                      => [1315, 25],
    LABEL5                     => [1340, 25],
    DATA5                      => [1365, 25],
    LABEL6                     => [1390, 25],
    DATA6                      => [1415, 25],
    LABEL7                     => [1440, 25],
    DATA7                      => [1465, 25],
    LABEL8                     => [1490, 25],
    DATA8                      => [1515, 25],
    LABEL9                     => [1540, 25],
    DATA9                      => [1565, 25],
    LABEL10                    => [1590, 25],
    DATA10                     => [1615, 25],
    LABEL11                    => [1640, 25],
    DATA11                     => [1665, 25],
    CM_ACCNT_NUMB_EXD          => [1690, 19],
    CASE_NUMBER_EXD            => [1715, 16],
    IND_FORM_CODE              => [1766, 2],
    IND_REF_NUMBER             => [1768, 30],
    LOC_REF_NUMBER             => [1801, 15],
    PASSENGER_NAME             => [1816, 20],
    PASSENGER_FIRST_NAME       => [1836, 12],
    PASSENGER_MIDDLE_NAME      => [1848, 12],
    PASSENGER_LAST_NAME        => [1860, 20],
    SE_PROCESS_DATE            => [1880, 3],
    RETURN_DATE                => [1883, 6],
    CREDIT_RECEIPT_NUMBER      => [1889, 15],
    RETURN_TO_NAME             => [1904, 24],
    RETURN_TO_STREET           => [1928, 17],
    CARD_DEPOSIT               => [1945, 1],
    ASSURED_RESERVATION        => [1946, 1],
    RES_CANCELLED              => [1947, 1],
    RES_CANCELLED_DATE         => [1948, 6],
    CANCEL_ZONE                => [1954, 2],
    RESERVATION_MADE_FOR       => [1955, 6],
    RESERVATION_LOCATION       => [1961, 20],
    RESERVATION_MADE_ON        => [1981, 6],
    RENTAL_AGREEMENT_NUMBER    => [1987, 20],
    MERCHANDISE_TYPE           => [2005, 6],
    MERCHANDISE_RETURNED       => [2025, 1],
    RETURNED_NAME              => [2026, 24],
    RETURNED_DATE              => [2050, 6],
    RETURNED_HOW               => [2056, 18],
    RETURNED_REASON            => [2064, 50],
    STORE_CREDIT_RECEIVED      => [2114, 1],
  };
}


sub type {return 'DETAIL'}

sub REC_TYPE                   {return $_[0]->_get_column('REC_TYPE')}
sub SE_NUMB                    {return $_[0]->_get_column('SE_NUMB')}
sub CM_ACCT_NUMB               {return $_[0]->_get_column('CM_ACCT_NUMB')}
sub CURRENT_CASE_NUMBER        {return $_[0]->_get_column('CURRENT_CASE_NUMBER')}

sub FINCAP_TRACKING_ID_A       {return $_[0]->_get_column('FINCAP_TRACKING_ID_A')}

sub FINCAP_TRACKING_A_DATE     {return $_[0]->_get_column('FINCAP_TRACKING_A_DATE')}
sub FINCAP_TRACKING_A_PCID     {return $_[0]->_get_column('FINCAP_TRACKING_A_PCID')}
sub FINCAP_TRACKING_A_SEQUENCE {return $_[0]->_get_column('FINCAP_TRACKING_A_SEQUENCE')}

sub CSS_CASE_NUMBER            {return $_[0]->_get_column('CSS_CASE_NUMBER')}
sub SS_CASE_NUMBER             {return $_[0]->_get_column('SS_CASE_NUMBER')}
sub CURRENT_ACTION_NUMBER      {return $_[0]->_get_column('CURRENT_ACTION_NUMBER')}
sub PREVIOUS_CASE_NUMBER       {return $_[0]->_get_column('PREVIOUS_CASE_NUMBER')}
sub CSS_P_CASE_NUMBER          {return $_[0]->_get_column('CSS_P_CASE_NUMBER')}
sub PREVIOUS_ACTION_NUMBER     {return $_[0]->_get_column('PREVIOUS_ACTION_NUMBER')}
sub RESOLUTION                 {return $_[0]->_get_column('RESOLUTION')}
sub FROM_SYSTEM                {return $_[0]->_get_column('FROM_SYSTEM')}
sub REJECTS_TO_SYSTEM          {return $_[0]->_get_column('REJECTS_TO_SYSTEM')}
sub DISPUTES_TO_SYSTEM         {return $_[0]->_get_column('DISPUTES_TO_SYSTEM')}
sub DATE_OF_ADJUSTMENT         {return $_[0]->_get_column('DATE_OF_ADJUSTMENT')}
sub DATE_OF_CHARGE             {return $_[0]->_get_column('DATE_OF_CHARGE')}
sub AMEX_ID                    {return $_[0]->_get_column('AMEX_ID')}
sub CASE_TYPE                  {return $_[0]->_get_column('CASE_TYPE')}
sub LOC_NUMB                   {return $_[0]->_get_column('LOC_NUMB')}
sub CB_REAS_CODE               {return $_[0]->_get_column('CB_REAS_CODE')}
sub CB_AMOUNT                  {return $_[0]->_get_column('CB_AMOUNT')}
sub CB_ADJUSTMENT_NUMBER       {return $_[0]->_get_column('CB_ADJUSTMENT_NUMBER')}
sub CB_RESOLUTION_ADJ_NUMBER   {return $_[0]->_get_column('CB_RESOLUTION_ADJ_NUMBER')}
sub CB_REFERENCE_CODE          {return $_[0]->_get_column('CB_REFERENCE_CODE')}
sub BILLED_AMOUNT              {return $_[0]->_get_column('BILLED_AMOUNT')}
sub SOC_AMOUNT                 {return $_[0]->_get_column('SOC_AMOUNT')}
sub SOC_INVOICE_NUMBER         {return $_[0]->_get_column('SOC_INVOICE_NUMBER')}
sub ROC_INVOICE_NUMBER         {return $_[0]->_get_column('ROC_INVOICE_NUMBER')}
sub FOREIGN_AMT                {return $_[0]->_get_column('FOREIGN_AMT')}
sub CURRENCY                   {return $_[0]->_get_column('CURRENCY')}
sub SUPP_TO_FOLLOW             {return $_[0]->_get_column('SUPP_TO_FOLLOW')}
sub CM_NAME1                   {return $_[0]->_get_column('CM_NAME1')}
sub CM_NAME2                   {return $_[0]->_get_column('CM_NAME2')}
sub CM_ADDR1                   {return $_[0]->_get_column('CM_ADDR1')}
sub CM_ADDR2                   {return $_[0]->_get_column('CM_ADDR2')}
sub CM_CITY_STATE              {return $_[0]->_get_column('CM_CITY_STATE')}
sub CM_ZIP                     {return $_[0]->_get_column('CM_ZIP')}
sub CM_FIRST_NAME_1            {return $_[0]->_get_column('CM_FIRST_NAME_1')}
sub CM_MIDDLE_NAME_1           {return $_[0]->_get_column('CM_MIDDLE_NAME_1')}
sub CM_LAST_NAME_1             {return $_[0]->_get_column('CM_LAST_NAME_1')}
sub CM_ORIG_ACCT_NUM           {return $_[0]->_get_column('CM_ORIG_ACCT_NUM')}
sub CM_ORIG_NAME               {return $_[0]->_get_column('CM_ORIG_NAME')}
sub CM_ORIG_FIRST_NAME         {return $_[0]->_get_column('CM_ORIG_FIRST_NAME')}
sub CM_ORIG_MIDDLE_NAME        {return $_[0]->_get_column('CM_ORIG_MIDDLE_NAME')}
sub CM_ORIG_LAST_NAME          {return $_[0]->_get_column('CM_ORIG_LAST_NAME')}
sub NOTE1                      {return $_[0]->_get_column('NOTE1')}
sub NOTE2                      {return $_[0]->_get_column('NOTE2')}
sub NOTE3                      {return $_[0]->_get_column('NOTE3')}
sub NOTE4                      {return $_[0]->_get_column('NOTE4')}
sub NOTE5                      {return $_[0]->_get_column('NOTE5')}
sub NOTE6                      {return $_[0]->_get_column('NOTE6')}
sub NOTE7                      {return $_[0]->_get_column('NOTE7')}
sub TRIUMPH_SEQ_NO             {return $_[0]->_get_column('TRIUMPH_SEQ_NO')}
sub AIRLINE_TKT_NUM            {return $_[0]->_get_column('AIRLINE_TKT_NUM')}
sub AL_SEQUENCE_NUMBER         {return $_[0]->_get_column('AL_SEQUENCE_NUMBER')}
sub FOLIO_REF                  {return $_[0]->_get_column('FOLIO_REF')}
sub MERCH_ORDER_NUM            {return $_[0]->_get_column('MERCH_ORDER_NUM')}
sub MERCH_ORDER_DATE           {return $_[0]->_get_column('MERCH_ORDER_DATE')}
sub CANC_NUM                   {return $_[0]->_get_column('CANC_NUM')}
sub CANC_DATE                  {return $_[0]->_get_column('CANC_DATE')}
sub FINCAP_TRACKING_ID         {return $_[0]->_get_column('FINCAP_TRACKING_ID')}

sub FINCAP_TRACKING_DATE       {return $_[0]->_get_column('FINCAP_TRACKING_DATE')}
sub FINCAP_TRACKING_PCID       {return $_[0]->_get_column('FINCAP_TRACKING_PCID')}
sub FINCAP_TRACKING_SEQUENCE   {return $_[0]->_get_column('FINCAP_TRACKING_SEQUENCE')}

sub FINCAP_FILE_SEQ_NUM        {return $_[0]->_get_column('FINCAP_FILE_SEQ_NUM')}
sub FINCAP_BATCH_NUMBER        {return $_[0]->_get_column('FINCAP_BATCH_NUMBER')}
sub FINCAP_BATCH_INVOICE_DT    {return $_[0]->_get_column('FINCAP_BATCH_INVOICE_DT')}
sub LABEL1                     {return $_[0]->_get_column('LABEL1')}
sub DATA1                      {return $_[0]->_get_column('DATA1')}
sub LABEL2                     {return $_[0]->_get_column('LABEL2')}
sub DATA2                      {return $_[0]->_get_column('DATA2')}
sub LABEL3                     {return $_[0]->_get_column('LABEL3')}
sub DATA3                      {return $_[0]->_get_column('DATA3')}
sub LABEL4                     {return $_[0]->_get_column('LABEL4')}
sub DATA4                      {return $_[0]->_get_column('DATA4')}
sub LABEL5                     {return $_[0]->_get_column('LABEL5')}
sub DATA5                      {return $_[0]->_get_column('DATA5')}
sub LABEL6                     {return $_[0]->_get_column('LABEL6')}
sub DATA6                      {return $_[0]->_get_column('DATA6')}
sub LABEL7                     {return $_[0]->_get_column('LABEL7')}
sub DATA7                      {return $_[0]->_get_column('DATA7')}
sub LABEL8                     {return $_[0]->_get_column('LABEL8')}
sub DATA8                      {return $_[0]->_get_column('DATA8')}
sub LABEL9                     {return $_[0]->_get_column('LABEL9')}
sub DATA9                      {return $_[0]->_get_column('DATA9')}
sub LABEL10                    {return $_[0]->_get_column('LABEL10')}
sub DATA10                     {return $_[0]->_get_column('DATA10')}
sub LABEL11                    {return $_[0]->_get_column('LABEL11')}
sub DATA11                     {return $_[0]->_get_column('DATA11')}
sub CM_ACCNT_NUMB_EXD          {return $_[0]->_get_column('CM_ACCNT_NUMB_EXD')}
sub CASE_NUMBER_EXD            {return $_[0]->_get_column('CASE_NUMBER_EXD')}
sub IND_FORM_CODE              {return $_[0]->_get_column('IND_FORM_CODE')}
sub IND_REF_NUMBER             {return $_[0]->_get_column('IND_REF_NUMBER')}
sub LOC_REF_NUMBER             {return $_[0]->_get_column('LOC_REF_NUMBER')}
sub PASSENGER_NAME             {return $_[0]->_get_column('PASSENGER_NAME')}
sub PASSENGER_FIRST_NAME       {return $_[0]->_get_column('PASSENGER_FIRST_NAME')}
sub PASSENGER_MIDDLE_NAME      {return $_[0]->_get_column('PASSENGER_MIDDLE_NAME')}
sub PASSENGER_LAST_NAME        {return $_[0]->_get_column('PASSENGER_LAST_NAME')}
sub SE_PROCESS_DATE            {return $_[0]->_get_column('SE_PROCESS_DATE')}
sub RETURN_DATE                {return $_[0]->_get_column('RETURN_DATE')}
sub CREDIT_RECEIPT_NUMBER      {return $_[0]->_get_column('CREDIT_RECEIPT_NUMBER')}
sub RETURN_TO_NAME             {return $_[0]->_get_column('RETURN_TO_NAME')}
sub RETURN_TO_STREET           {return $_[0]->_get_column('RETURN_TO_STREET')}
sub CARD_DEPOSIT               {return $_[0]->_get_column('CARD_DEPOSIT')}
sub ASSURED_RESERVATION        {return $_[0]->_get_column('ASSURED_RESERVATION')}
sub RES_CANCELLED              {return $_[0]->_get_column('RES_CANCELLED')}
sub RES_CANCELLED_DATE         {return $_[0]->_get_column('RES_CANCELLED_DATE')}
sub CANCEL_ZONE                {return $_[0]->_get_column('CANCEL_ZONE')}
sub RESERVATION_MADE_FOR       {return $_[0]->_get_column('RESERVATION_MADE_FOR')}
sub RESERVATION_LOCATION       {return $_[0]->_get_column('RESERVATION_LOCATION')}
sub RESERVATION_MADE_ON        {return $_[0]->_get_column('RESERVATION_MADE_ON')}
sub RENTAL_AGREEMENT_NUMBER    {return $_[0]->_get_column('RENTAL_AGREEMENT_NUMBER')}
sub MERCHANDISE_TYPE           {return $_[0]->_get_column('MERCHANDISE_TYPE')}
sub MERCHANDISE_RETURNED       {return $_[0]->_get_column('MERCHANDISE_RETURNED')}
sub RETURNED_NAME              {return $_[0]->_get_column('RETURNED_NAME')}
sub RETURNED_DATE              {return $_[0]->_get_column('RETURNED_DATE')}
sub RETURNED_HOW               {return $_[0]->_get_column('RETURNED_HOW')}
sub RETURNED_REASON            {return $_[0]->_get_column('RETURNED_REASON')}
sub STORE_CREDIT_RECEIVED      {return $_[0]->_get_column('STORE_CREDIT_RECEIVED')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::CBNOT::Detail - Parse AMEX Chargeback Notification Files (CBNOT) Detail Rows

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Finance::AMEX::Transaction;

  my $cbnot = Finance::AMEX::Transaction->new(file_type => 'CBNOT');
  open my $fh, '<', '/path to CBNOT file' or die "cannot open CBNOT file: $!";

  while (my $record = $cbnot->getline($fh)) {

    if ($record->type eq 'DETAIL') {
      print $record->REC_TYPE . "\n";
    }
  }

  # to parse a single line

  my $record = $cbnot->parse_line('line from a CBNOT file');
  if ($record->type eq 'DETAIL') {
    ...
  }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new F<Finance::AMEX::Transaction::CBNOT::Detail> object.

 my $record = Finance::AMEX::Transaction::CBNOT::Detail->new(line => $line);

=head2 type

This will always return the string DETAIL.

 print $record->type; # DETAIL

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 REC_TYPE

This field contains the constant literal "D", a record type code that indicates that this is a Chargeback Notifications (CBNOT) File Detail Record.

 print $record->REC_TYPE; # D

=head2 SE_NUMB

This field contains the Service Establishment (SE) Number that STARS searches for and routes data to, based on the setup for the corresponding CBNOT data type (for outbound data).

=head2 CM_ACCT_NUMB

This field contains the Cardmember Account Number that corresponds to this chargeback.

=head2 CURRENT_CASE_NUMBER

This field contains the unique, American Express-assigned, current case (identification) number for this transaction, if this is a chargeback notifica- tion or final resolution.

For Customer Service Systems, you can use the CSS_CASE_NUMBER.

For SIREN/SOFA (SE Information Retrieval Entry Network/SE Online Financial Adjustment), you can use the SS_CASE_NUMBER.

=head2 FINCAP_TRACKING_ID

For FINCAP transactions (indicated when FINCAP_TRACKING_ID is not blank), this field contains the FINCAP Tracking ID.

=head2 CSS_CASE_NUMBER

See CURRENT_CASE_NUMBER

=head2 SS_CASE_NUMBER

See CURRENT_CASE_NUMBER

=head2 CURRENT_ACTION_NUMBER

Internal use only.

=head2 PREVIOUS_CASE_NUMBER

This field contains a case number from various sources, or is blank (character space filled), depending on the specific details of this record. (See also CSS_P_CASE_NUMBER)

=head2 CSS_P_CASE_NUMBER

This field contains a case number from various sources, or is blank (character space filled), depending on the specific details of this record. (See also PREVIOUS_CASE_NUMBER)

=head2 PREVIOUS_ACTION_NUMBER

Internal use only.

=head2 RESOLUTION

This field contains a code that indicates if this record is a Resolution Letter:

=over 4

=item Y = Yes

=item N = No

=back

Note: If this value is "Y", then CB_RESOLUTION_ADJ_NUMBER should be populated.

=head2 FROM_SYSTEM

This field contains a code that indicates the originating system that transmitted the file:

=over 4

=item F = FINCAP

=item R = Statement Review

=item S = SIREN/SOFA (SE Information Retrieval Entry Network/SE Online Financial Adjustment)

=item T = Triumph

=item X = Customer Service Systems

=item P = Enhanced Case Management Platform

=item G = Globestar

=item _ = Other (underline represents a character space)

=item D = Global Disputes Management

=back

Note: Internal use only

=head2 REJECTS_TO_SYSTEM

This field contains a code that indicates the system to which STARS (Split, Transmit And Receive System) should forward rejects:

=over 4

=item R = Statement Review

=item S = SIREN/SOFA (SE Information Retrieval Entry Network/SE Online Financial Adjustment)

=item T = Triumph

=item X = Customer Service Systems

=item P = Enhanced Case Management Platform

=item G = Globestar

=item _ = No rejects (underline represents a character space)

=item D = Global Disputes Management

=back

=head2 DISPUTES_TO_SYSTEM

This field contains a code that indicates the system to which STARS (Split, Transmit And Receive System) should forward disputes from the SE:

=over 4

=item R = Statement Review

=item S = SIREN/SOFA (SE Information Retrieval Entry Network/SE Online Financial Adjustment)

=item T = Triumph

=item X = Customer Service Systems

=item P = Enhanced Case Management Platform

=item G = Globestar

=item _ = No disputes (underline represents a

=item D = Global Disputes Management

=back

=head2 DATE_OF_ADJUSTMENT

This field contains the date of the adjustment. The format is: CCYYMMDD

=over 4

=item CC = Century

=item YY = Year

=item MM = Month

=item DD = Day

=back

For example, the date October 21st, 2010 would appear as: 20101021

=head2 DATE_OF_CHARGE

This field contains the date of the charge. The format is: CCYYMMDD

=over 4

=item CC = Century

=item YY = Year

=item MM = Month

=item DD = Day

=back

For example, the date October 21st, 2010 would appear as: 20101021

=head2 AMEX_ID

This field contains the American Express ID number of the representative that did the adjustment.

Note: Internal use only.

=head2 CASE_TYPE

This field contains a code that indicates the case type assigned to this chargeback by American Express. The entry in this field determines the type of response code that appears in the response file.

=over 4

=item AIRDS = Airline Credit Requested

=item AIRLT = Airline Lost/Stolen Ticket

=item AIRRT = Airline Returned Ticket

=item AIRTB = Airline Support of Charge

=item AREXS = Reservation/Cancellation

=item CARRD = Car Rental

=item GSDIS = Goods/Services

=item NAXMG = Merchandise Not Received

=item NAXMR = Merchandise Returned

=item SEDIS = General Dispute

=item FRAUD = Fraud Dispute

=item CRCDW = Collision Damage Waiver Liability

=back

=head2 LOC_NUMB

This field may contain the store or location number where the charge occurred. Also, refer to LOC_REF_NUMBER.

=head2 CB_REAS_CODE

This field contains a three-character, chargeback reason code.

=over 4

=item Authorization

=over 4

=item A01 - The amount of the Authorization Approval was less than the amount of the Charge you submitted.

=item A02 - The Charge you submitted did not receive a valid Authorization Approval; it was declined or the Card was expired.

=item A08 - The Charge was submitted after the Authorization Approval expired.

=back

=item Cardmember Dispute

=over 4

=item C02 - We have not received the Credit (or partial Credit) you were to apply to the Card.

=item C04 - The goods or services were returned or refused but the Cardmember did not receive Credit.

=item C05 - The Cardmember claims that the goods/services ordered were cancelled.

=item C08 - The Cardmember claims to have not received (or only partially received) the goods/services.

=item C14 - The Cardmember has provided us with proof of payment by another method.

=item C18 - The Cardmember claims to have cancelled a lodging reservation or a Credit for a CARDeposit Charge was not received by the Cardmember.

=item C28 - Cardmember claims to have cancelled or attempted to cancel Recurring Billing Charges for goods or services. Please discontinue all future billing for this Recurring Billing Charge.

=item C31 - The Cardmember claims to have received goods/services that are different than the written description provided at the time of the Charge.

=item C32 - The Cardmember claims to have received damaged or defective goods/services.

=back

=item Fraud

=over 4

=item F10 - The Cardmember claims they did not participate in this Charge and you have not provided a copy of an imprint of the Card.

=item F14 - The Cardmember claims they did not participate in this Charge and you have not provided a copy of the Cardmember's signature to support the Charge.

=item F22 - The Cardmember denies participation in the Charge you submitted and the Card was expired or was not yet valid when you processed the Charge.

=item F24 - The Cardmember denies participation in the Charge you submitted and you have failed to provide proof that the Cardmember participated in the Charge.

=item F29 - The Cardmember denies participation in a mail order, telephone order, or internet Charge.

=item F30 - A counterfeit Chip Card was used at a terminal that was not capable of processing a Chip Card Transaction.

=item F31 - A lost/stolen/non-received Chip Card was used at a terminal that was not capable of processing a Chip Card Transaction with PIN validation.

=back

=item Full Recourse

=over 4

=item FR2 - The Cardmember denies authorizing the Charge and your Establishment has been placed in the Fraud Full Recourse Program.

=item FR4 - The Cardmember has disputed the Charge and you have been placed in the Immediate Chargeback Program.

=item FR5 - Your account is on the Immediate Chargeback program. Under these circumstances, disputed charges are debited from your account with no further recourse. These chargebacks cannot be reversed unless you issue a credit to the account, or the Cardholder advises the charge(s) are valid.

=item FR6 - The Cardmember has disputed the Charge and you have been placed in the Partial Immediate Chargeback Program.

=back

=item Processing Error

=over 4

=item P01 - You have submitted a Charge using an invalid or otherwise incorrect Card Number.

=item P03 - The Cardmember claims the Charge you submitted should have been submitted as a Credit.

=item P04 - The Cardmember claims the Credit you submitted should have been submitted as a Charge.

=item P05 - The Charge amount you submitted differs from the amount the Cardmember agreed to pay.

=item P07 - The Charge was not submitted within the required timeframe.

=item P08 - The individual Charge was submitted more than once.

=item P22 - The Card Number in the Submission does not match the Card Number in the original Charge.

=item P23 - The Charge was incurred in an invalid currency.

=item P09 - We have processed duplicate payments to your account for the same transaction.

=back

=item Miscellaneous Adjustments and Resolutions

=over 4

=item M49 - The Cardmember claims to have been incorrectly Charged for theft, loss of use, or other fees related to theft or loss of use of a rental vehicle.

=item M01 - We have received your authorization to process Chargeback for the Charge.

=item M10 - The Cardmember claims to have been incorrectly billed for Capital Damages.

=back

=item Chargeback Reversal Adjustments

=over 4

=item M11 - We recently debited your account for the adjustment amount indicated. We have now received your credit for this charge and we are reversing the debit and crediting your account.

=item M38 - We recently debited your account for the adjustment amount indicated. We are now reversing the debit and crediting your account

=back

=item Non-dispute Adjustments

=over 4

=item M19 - According to our records, your credit was inadvertently deducted from another merchant's account. This has now been corrected, and a debit for this amount will be issued. We apologize for any inconvenience this may have caused.

=item M21 - Our records indicate that your charge or summary was inadvertently paid to another merchant. This has been corrected and a credit has been issued.

=item M22 - Our records indicate that your service establishment was inadvertently paid for a submission sent to us by another service establishment. To correct this erroneous payment, an adjustment debiting your account has been processed.

=item M23 - A review of our records indicates that your service establishment inadvertently cashed a check that belonged to another service establishment. To correct this erroneous payment, an adjustment debiting your account for the amount of this check has been processed. Please submit your charges to cover this amount, or send us a check as soon as possible.

=item M24 - We have processed an adjustment transferring a debit balance from your previous account to the account listed. This balance owed us was aging on an account that is no longer active.

=item M25 - Our records indicate that your affiliated account has an outstanding debit balance. This debit has not cleared because charges are no longer being submitted by this account. Consequently, we have processed an adjustment to transfer this debit to your account.

=item M27 - Your cheque was returned to us by your bank. Since your account was previously credited for this cheque, we are debiting your account for the amount involved. Please send us a replacement cheque immediately.

=item M28 - According to our records, an incorrect discount rate was applied to your summaries. Since the rate should have been lower, credit has been issued.

=item M29 - The invoice and report provided includes details regarding discount fees for American Express charges processed for the month indicated. This invoice amount will be debited to your bank account.

=item M32 - We have processed an adjustment to your account. This adjustment represents your share of the media costs incurred in your participation in our cooperative advertisement program.

=item M33 - In accordance with your request, an adjustment to your account has been processed.

=item M39 - We have issued an adjustment to your account to correct a transaction that was previously processed in error.

=item M43 - We have processed an adjustment to your account. This adjustment represents your participation in American Express Marketing Programs. Our records indicate a recent change in payment options for your participation. Therefore, future adjustments will be invoiced on a monthly frequency.

=item M44 - We have processed an adjustment to your account. This adjustment represents your participation in American Express Marketing Programs. Our records indicate a recent change in payment options for your participation. Therefore, future adjustments will be deducted on a monthly frequency from payments for charges submitted.

=item M45 - A review of our records indicates that a cheque was applied to your account in error. Therefore an adjustment has been processed to debit your account.

=item M46 - We have determined that your establishment was inadvertently debited for item(s) which were submitted to us by another establishment. To correct this erroneous debit, an adjustment crediting your account has been processed, and will be included in a future statement.

=back

=item Informational Chargeback Reason Codes

=over 4

=item M02 - The Cardmember no longer disputes the charge(s). Please discontinue further investigation.

=item M04 - We previously received your authorization to debit your account. Please deal directly with the Cardholder for resolution on this matter.

=item M36 - Please see the additional notes related to this dispute.

=item M42 - Due to the length of time between the chargeback to your account and receiving your dispute, we are unable to review this for reversal.

=back

=item Retrieval/Support

=over 4

=item R03 Complete support and/or documentation were not provided as requested.

=item R13 We did not receive your response to our Inquiry within the specified timeframe.

=back

=item Status Updates

=over 4

=item S01 - Your request for a chargeback reversal has been reviewed. The chargeback will remain, and your account will not be credited.

=item S03 - Support received.

=item S04 - We have received your request for a chargeback reversal. Please allow 2 to 3 weeks for research.

=back

=back

=head2 CB_AMOUNT

Numeric, signed, with decimal point and two decimal places, right justified, zero filled

This field contains the adjustment or chargeback amount, which can be a debit or credit. The format for this field is a one-digit "sign,"” followed by a 13-digit "dollar amount" (right justified and zero filled), one-digit "decimal point," and two-digit "cents." For negative amounts, the first-digit "sign" is a negative sign. For a "negative $100.00", this would appear as:

 0         1
 12345678901234567
 -----------------
 -0000000000100.00

For a positive amount, the first-digit "sign" is a blank (character space), which would appear as:

 0         1
 12345678901234567
 -----------------
 _0000000000100.00

Note: The underline character ( _ ) represents a character space.

=head2 CB_ADJUSTMENT_NUMBER

This field contains the Chargeback Adjustment Number.

Note: This is the Adjustment Number that appears in the associated financial file and corresponds to the financial reporting specification.

=head2 CB_RESOLUTION_ADJ_NUMBER

This field contains the Chargeback Resolution Adjustment Number, if applicable. Normally blank (character space filled), this field is only populated when this record is a combination resolution and adjustment (such as in the reversal of a prior chargeback).

Note: This is the Adjustment Number that appears in the associated financial file and corresponds to the financial reporting specification.

=head2 CB_REFERENCE_CODE

This field contains the merchant’s reference number that was assigned to the transaction by the merchant when the charge was originated, to help identify this specific charge. For Reference Numbers greater than 12 digits, refer to IND_REF_NUMBER.

=head2 BILLED_AMOUNT

This field contains the statement bill amount or ROC amount, which can be a debit or credit. The format for this field is a one-digit "sign," followed by a 13-digit "dollar amount" (right justified and zero filled), one-digit "decimal point," and two- digit "cents."

For negative amounts, the first-digit "sign" is a negative sign, which would appear as:

 0         1
 12345678901234567
 -----------------
 -2345678901234.67

For a positive amount, the first-digit "sign" is a blank (character space), which would appear as:

 0         1
 12345678901234567
 -----------------
 _2345678901234.67

Where the underline character represents a character space.

Note: The entries in CB_AMOUNT and BILLED_AMOUNT fields may differ.

=head2 SOC_AMOUNT

This field contains the Summary of Charge (SOC) or Summary Amount, which can be a debit or credit. The format for this field is a one-digit "sign," followed by a 13-digit "dollar amount" (right justified and zero filled), one-digit "decimal point," and two-digit "cents."

For negative amounts, the first-digit "sign" is a negative sign, which would appear as:

 0         1
 12345678901234567
 -----------------
 -2345678901234.67

For a positive amount, the first-digit "sign" is a blank (character space), which would appear as:

 0         1
 12345678901234567
 -----------------
 _2345678901234.67

Where the underline character represents a character space.

=head2 SOC_INVOICE_NUMBER

This field contains the Summary of Charge (SOC) Invoice Number that corresponds to the batch in which the merchant submitted the charge for payment.

=head2 ROC_INVOICE_NUMBER

This field contains the Record of Charge (ROC) Invoice Number that corresponds to the charge that the merchant submitted for payment.

=head2 FOREIGN_AMT

This field contains the Foreign Amount (the disputed amount, if the charge was made in a currency other than US Dollars).

If unused, this field is character space filled.

=head2 CURRENCY

This field contains the currency code that corresponds to the value in the FOREIGN_AMT field.

=over 4

=item 124 CAD Canada

=item 840 USD United States

=back

If unused, this field is character space filled.

=head2 SUPP_TO_FOLLOW

This field contains a code that indicates whether additional support is being forwarded. The codes are:

=over 4

=item Y = Support is coming via mail or fax.

=item I = A scanned image provides support.

=item R = Both forms of support to follow: Mail or fax, and scanned image.

=item N = No support.

=back

=head2 CM_NAME1

This field contains the Cardmember’s name, concatenated from the following fields:

=over 4

=item CM_FIRST_NAME_1

=item CM_MIDDLE_NAME_1

=item CM_LAST_NAME_1

=back

=head2 CM_NAME2

This field contains a secondary Card member name. Usually, this is the name of a supplemental cardholder to the primary Card member’s account.

=head2 CM_ADDR1

This field contains the first line of the Card member’s street address.

=head2 CM_ADDR2

This field contains the second line of the Card member’s street address.

=head2 CM_CITY_STATE

This field contains the city and state portion of the Card member's address.

=head2 CM_ZIP

This field contains the ZIP code portion of the Cardmember's address.

For U.S. addresses, this is may be a 9-digit "5+4" ZIP code, or a 5-digit ZIP code, left justified and zero filled to 9 digits.

Alphanumeric Canadian postal codes are left justified and padded with zeros or character spaces.

If ZIP code is unavailable, this field is zero filled.

=head2 CM_FIRST_NAME_1

This field contains the first name of the Cardmember who made the charge.

Note: The value in this field is a component of the entry in the CM_NAME1 field.

=head2 CM_MIDDLE_NAME_1

This field contains the middle name of the Card member who made the charge.

Note: The value in this field is a component of the entry in the CM_NAME1 field.

=head2 CM_LAST_NAME_1

This field contains the last name of the Card member who made the charge.

Note: The value in this field is a component of the entry in the CM_NAME1 field.

=head2 CM_ORIG_ACCT_NUM

This field contains the Cardmember Account Number that corresponds to this chargeback.

Developer note: the documentation for this field sometimes refers to it as CM_ACCT_NUM, which conflicts with an earlier field.

=head2 CM_ORIG_NAME

If the Card member has a different name, this field contains the Card member’s original name at the time the charge was made.

If this field is populated, it contains the Cardmember’s original name, concatenated from the following fields:

=over 4

=item CM_ORIG_FIRST_NAME

=item CM_ORIG_MIDDLE_NAME

=item CM_ORIG_LAST_NAME

=back

=head2 CM_ORIG_FIRST_NAME

If the Card member has a different name, this field contains the Card member’s original first name at the time the charge was made.

Note: The value in this field is a component of the entry in the CM_ORIG_NAME field.

=head2 CM_ORIG_MIDDLE_NAME

If the Card member has a different name, this field contains the Card member’s original middle name at the time the charge was made.

Note: The value in this field is a component of the entry in the CM_ORIG_NAME field.

=head2 CM_ORIG_LAST_NAME

If the Card member has a different name, this field contains the Card member’s original last name at the time the charge was made.

Note: The value in this field is a component of the entry in the CM_ORIG_NAME field.

=head2 NOTE1

Case notes may appear in the fields labeled Note1 through Note7.

=head2 NOTE2

Case notes may appear in the fields labeled Note1 through Note7.

=head2 NOTE3

Case notes may appear in the fields labeled Note1 through Note7.

=head2 NOTE4

Case notes may appear in the fields labeled Note1 through Note7.

=head2 NOTE5

Case notes may appear in the fields labeled Note1 through Note7.

=head2 NOTE6

Case notes may appear in the fields labeled Note1 through Note7.

=head2 NOTE7

Case notes may appear in the fields labeled Note1 through Note7.

=head2 TRIUMPH_SEQ_NO

This field contains the Triumph Sequence Number and is an internal field used by American Express.

=head2 AIRLINE_TKT_NUM

This record only pertains to airline case types; e.g., CASE_TYPE = AIRDS, AIRLT, AIRRT or AIRTB). For these case types this field may contain the airline passenger ticket number.

=head2 AL_SEQUENCE_NUMBER

This record only pertains to airline case types. If this record involves multiple airline tickets, this field contains the sequence number.

=head2 FOLIO_REF

If this record pertains to a hotel chargeback, this field contains the hotel reference number (if applicable).

For all other transactions — this field is unused and is character space filled.

=head2 MERCH_ORDER_NUM

This field contains the merchandise order number (if applicable).

=head2 MERCH_ORDER_DATE

This field contains the merchandise order date (if applicable).

The format is: CCYYMMDD

=over 4

=item CC = Century

=item YY = Year

=item MM = Month

=item DD = Day

=back

For example, the date October 21st, 2010 would appear as: 20101021

=head2 CANC_NUM

This field contains the cancellation number (if applicable).

=head2 CANC_DATE

This field contains the cancellation date (if applicable).

The format is: CCYYMMDD

=over 4

=item CC = Century

=item YY = Year

=item MM = Month

=item DD = Day

=back

For example, the date October 21st, 2010 would appear as: 20101021

=head2 FINCAP_TRACKING_ID

For FINCAP transactions — This field contains the FINCAP load number that is composed of the Julian date, the PCID and the sequence number.

The format is: JJJPPPPPPSS

=over 4

=item JJJ = Julian date

=item PPPPPP = PCID

=item SS = Sequence number

=back

For all other transactions — This field is unused and is character space filled.

Note: This field is part of the “FINCAP Area.”

=head2 FINCAP_FILE_SEQ_NUM

For FINCAP transactions — This field contains the FINCAP file sequence number.

For all other transactions — This field is unused and is character space filled.

Note: This field is part of the “FINCAP Area.”

=head2 FINCAP_BATCH_NUMBER

For FINCAP transactions — this field contains the FINCAP batch number.

For all other transactions — this field is unused and is character space filled.

Note: This field is part of the “FINCAP Area.”

=head2 FINCAP_BATCH_INVOICE_DT

For FINCAP transactions — This field contains the batch invoice date.

The format is: CCYYMMDD

=over 4

=item CC = Century

=item YY = Year

=item MM = Month

=item DD = Day

=back

For example, the date October 21st, 2010 would appear as: 20101021

For all other transactions — This field is unused and is character space filled.

Note: This field is part of the “FINCAP Area.”

=head2 LABEL1

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 DATA1

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 LABEL2

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 DATA2

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 LABEL3

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 DATA3

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 LABEL4

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 DATA4

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 LABEL5

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 DATA5

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 LABEL6

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 DATA6

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 LABEL7

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 DATA7

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 LABEL8

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 DATA8

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 LABEL9

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 DATA9

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 LABEL10

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 DATA10

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 LABEL11

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 DATA11

This field is reserved for use by upstream host systems that may download undefined “free form” data. This field may contain additional information pertaining to the case. If unused, it is character space filled.

Note: This field is part of the “Label Data Area.”

=head2 CM_ACCNT_NUMB_EXD

This field contains the original Card Member account number that corresponds to this response. If not applicable the current Card Member Account number will appear.

=head2 CASE_NUMBER_EXD

This field contains a Case Number from various sources, or is blank (character space filled), depending on the specific details of this record.

=head2 IND_FORM_CODE

This field contains the two-character, Industry Format Code. If unused, this field is character space filled.

=over 4

=item CAPN-Certified Merchants

=item GP = Gas & Oil Industry

=item NP = Non-Gas & Oil Industries

=item Non-CAPN Merchants

=item GO = Gas & Oil Industry

=item ~~ = Non-Gas & Oil Industries

=back

Note: Tildes (~) represent character spaces.

=head2 IND_REF_NUMBER

This field contains the SE Reference Number assigned to a transaction by the merchant, at the time the sale is executed.

This SE Reference Number may refer to the location, ROC, order number, invoice number, or any other merchant-assigned combination of letters and numerals that will assist the merchant in retrieving supporting documentation in case of inquiry or other post-transaction correspondence.

This field corresponds to the Invoice Reference Number, Field 26 (Positions 220-249), of the CAPN Submission File TAB record.

=head2 LOC_REF_NUMBER

This field contains the Location Reference Number (a merchant-assigned name or internal store identifier code) that identifies the individual store or location where the disputed charge occurred; (i.e., Location Number).

This field corresponds to the Merchant Location ID, Field 19 (positions 127-141), of the CAPN Submission File TAB Record.

=head2 PASSENGER_NAME

This field is used for airline transactions only. It contains the full (concatenated) Passenger Name associated with the charge. Note: This field is applicable to the following case types: AIRDS, AIRLT, AIRRT and AIRTB.

=head2 PASSENGER_FIRST_NAME

This field is used for airline transactions only. It contains the first name of the passenger associated with the charge.

Note: This field is applicable to the following case types: AIRDS, AIRLT, AIRRT and AIRTB.

=head2 PASSENGER_MIDDLE_NAME

This field is used for airline transactions only. It contains the middle name of the passenger associated with the charge.

Note: This field is applicable to the following case types: AIRDS, AIRLT, AIRRT and AIRTB.

=head2 PASSENGER_LAST_NAME

This field is used for airline transactions only. It contains the last name of the passenger associated with the charge.

Note: This field is applicable to the following case types: AIRDS, AIRLT, AIRRT and AIRTB.

=head2 SE_PROCESS_DATE

This field is used for airline transactions only. It contains the airline processing date, in Julian date format.

Note: This field is applicable to the following case types: AIRDS, AIRLT, AIRRT and AIRTB.

=head2 RETURN_DATE

This field is used for airline transactions only. It contains the airline ticket Return Date.

The format is: YYMMDD

=over 4

=item YY = Year

=item MM = Month

=item DD = Day

=back

For example, the date October 21, 2012 would appear as: 121021

Note: This field is applicable to the AIRRT case type only.

=head2 CREDIT_RECEIPT_NUMBER

This field is used for airline transactions only. It contains the returned-ticket, Credit Receipt Number.

Note: This field is applicable to the AIRRT case type only.

=head2 RETURN_TO_NAME

This field is used for airline transactions only. It contains the name of the person to whom the ticket was returned.

Note: This field is applicable to the AIRRT case type only.

=head2 RETURN_TO_STREET

This field is used for airline transactions only. It contains the street address where the ticket was returned.

Note: This field is applicable to the AIRRT case type only.

=head2 CARD_DEPOSIT

This field contains a code that indicates if a Card deposit was given for the reservation.

=over 4

=item Y = Yes

=item N = No

=item U = Unknown

=back

Note: This field is applicable to the AREXS case type only.

=head2 ASSURED_RESERVATION

This field contains a code that indicates if the reservation was assured.

=over 4

=item Y = Yes

=item N = No

=back

Note: This field is applicable to the AREXS case type only.

=head2 RES_CANCELLED

This field contains a code that indicates if the reservation was cancelled.

=over 4

=item Y = Yes

=item N = No

=back

Note: This field is applicable to the AREXS case type only.

=head2 RES_CANCELLED_DATE

This field contains the date when the reservation was cancelled.

The format is: YYMMDD

=over 4

=item YY = Year

=item MM = Month

=item DD = Day

=back

For example, the date October 21, 2012 would appear as: 121021

Note: This field is applicable to the AREXS case type only.

=head2 CANCEL_ZONE

This field contains the time zone that corresponds to the time when the reservation was cancelled.

=over 4

=item C = Central

=item P = Pacific

=item E = Eastern

=item O = Other

=item M = Mountain

=back

Note: This field is applicable to the AREXS case type only.

=head2 RESERVATION_MADE_FOR

This field contains the date for which the reservation was made.

The format is: YYMMDD

=over 4

=item YY = Year

=item MM = Month

=item DD = Day

=back

For example, the date October 21, 2012 would appear as: 121021

Note: This field is applicable to the AREXS case type only.

=head2 RESERVATION_LOCATION

This field contains the location applicable to the reservation.

Note: This field is applicable to the AREXS case type only.

=head2 RESERVATION_MADE_ON

This field contains the date on which the reservation was made.

The format is: YYMMDD

=over 4

=item YY = Year

=item MM = Month

=item DD = Day

=back

For example, the date October 21, 2012 would appear as: 121021

Note: This field is applicable to the AREXS case type only.

=head2 RENTAL_AGREEMENT_NUMBER

This field contains the car rental agreement number.

Note: This field is applicable to the CARRD case type only.

=head2 MERCHANDISE_TYPE

This field contains a description of the type of merchandise that was purchased, but not received.

Note: This field is applicable to the NAXMG and NAXMR case types only.

=head2 MERCHANDISE_RETURNED

This field contains a code that indicates if the merchandise was returned.

=over 4

=item Y = Yes

=item N = No

=back

Note: This field is applicable to the NAXMR case type only.

=head2 RETURNED_NAME

This field contains the name of the location to which the merchandise was returned.

Note: This field is applicable to the NAXMR case type only.

=head2 RETURNED_DATE

This field contains the date that the merchandise was returned.

The format is: YYMMDD

=over 4

=item YY = Year

=item MM = Month

=item DD = Day

=back

For example, the date October 21, 2012 would appear as: 121021

Note: This field is applicable to the NAXMR case type only.

=head2 RETURNED_HOW

This field contains the method used to ship the returned merchandise.

Note: This field is applicable to the NAXMR case type only.

=head2 RETURNED_REASON

This field contains free-form text that explains the reason why the merchandise was returned.

Note: This field is applicable to the NAXMR case type only.

=head2 STORE_CREDIT_RECEIVED

This field contains a code that indicates if the store or business issued a credit for returned merchandise.

=over 4

=item Y = Yes

=item N = No

=back

Note: This field is applicable to the NAXMR case type only.

=head1 NAME

Finance::AMEX::Transaction::CBNOT::Detail - Object methods for AMEX chargeback notification file detail records.

=head1 AUTHOR

Tom Heady <theady@ziprecruiter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
