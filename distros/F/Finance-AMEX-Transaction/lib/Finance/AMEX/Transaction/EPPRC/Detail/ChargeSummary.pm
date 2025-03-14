package Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummary 0.005;

use strict;
use warnings;

# ABSTRACT: Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC) Summary of Charge (SOC) Detail Rows

use base 'Finance::AMEX::Transaction::EPPRC::Base';

sub field_map {
  return {
    AMEX_PAYEE_NUMBER           => [1,   10],
    AMEX_SE_NUMBER              => [11,  10],
    SE_UNIT_NUMBER              => [21,  10],
    PAYMENT_YEAR                => [31,  4],
    PAYMENT_NUMBER              => [35,  8],
    PAYMENT_NUMBER_DATE         => [35,  3],
    PAYMENT_NUMBER_TYPE         => [38,  1],
    PAYMENT_NUMBER_NUMBER       => [39,  4],
    RECORD_TYPE                 => [43,  1],
    DETAIL_RECORD_TYPE          => [44,  2],
    SE_BUSINESS_DATE            => [46,  7],
    AMEX_PROCESS_DATE           => [53,  7],
    SOC_INVOICE_NUMBER          => [60,  6],
    SOC_AMOUNT                  => [66,  11],
    DISCOUNT_AMOUNT             => [77,  9],
    SERVICE_FEE_AMOUNT          => [86,  7],
    NET_SOC_AMOUNT              => [100, 11],
    DISCOUNT_RATE               => [111, 5],
    SERVICE_FEE_RATE            => [116, 5],
    AMEX_GROSS_AMOUNT           => [142, 11],
    AMEX_ROC_COUNT              => [153, 5],
    TRACKING_ID                 => [158, 9],
    TRACKING_ID_DATE            => [158, 3],
    TRACKING_ID_PCID            => [161, 6],
    CPC_INDICATOR               => [167, 1],
    AMEX_ROC_COUNT_POA          => [183, 7],
    BASE_DISCOUNT_AMOUNT        => [190, 16],
    CARD_NOT_PRESENT_BPA_AMOUNT => [206, 16],
    CARD_NOT_PRESENT_PTA_AMOUNT => [222, 16],
    CARD_NOT_PRESENT_BPA_RATE   => [238, 9],
    CARD_NOT_PRESENT_PTA_RATE   => [247, 9],
    TRANSACTION_FEE_AMOUNT      => [256, 16],
    TRANSACTION_FEE_RATE        => [272, 9],
  };
}

sub type {return 'SOC_DETAIL'}

sub AMEX_PAYEE_NUMBER           {return $_[0]->_get_column('AMEX_PAYEE_NUMBER')}
sub AMEX_SE_NUMBER              {return $_[0]->_get_column('AMEX_SE_NUMBER')}
sub SE_UNIT_NUMBER              {return $_[0]->_get_column('SE_UNIT_NUMBER')}
sub PAYMENT_YEAR                {return $_[0]->_get_column('PAYMENT_YEAR')}
sub PAYMENT_NUMBER              {return $_[0]->_get_column('PAYMENT_NUMBER')}
sub PAYMENT_NUMBER_DATE         {return $_[0]->_get_column('PAYMENT_NUMBER_DATE')}
sub PAYMENT_NUMBER_TYPE         {return $_[0]->_get_column('PAYMENT_NUMBER_TYPE')}
sub PAYMENT_NUMBER_NUMBER       {return $_[0]->_get_column('PAYMENT_NUMBER_NUMBER')}
sub RECORD_TYPE                 {return $_[0]->_get_column('RECORD_TYPE')}
sub DETAIL_RECORD_TYPE          {return $_[0]->_get_column('DETAIL_RECORD_TYPE')}
sub SE_BUSINESS_DATE            {return $_[0]->_get_column('SE_BUSINESS_DATE')}
sub AMEX_PROCESS_DATE           {return $_[0]->_get_column('AMEX_PROCESS_DATE')}
sub SOC_INVOICE_NUMBER          {return $_[0]->_get_column('SOC_INVOICE_NUMBER')}
sub SOC_AMOUNT                  {return $_[0]->_get_column('SOC_AMOUNT')}
sub DISCOUNT_AMOUNT             {return $_[0]->_get_column('DISCOUNT_AMOUNT')}
sub SERVICE_FEE_AMOUNT          {return $_[0]->_get_column('SERVICE_FEE_AMOUNT')}
sub NET_SOC_AMOUNT              {return $_[0]->_get_column('NET_SOC_AMOUNT')}
sub DISCOUNT_RATE               {return $_[0]->_get_column('DISCOUNT_RATE')}
sub SERVICE_FEE_RATE            {return $_[0]->_get_column('SERVICE_FEE_RATE')}
sub AMEX_GROSS_AMOUNT           {return $_[0]->_get_column('AMEX_GROSS_AMOUNT')}
sub AMEX_ROC_COUNT              {return $_[0]->_get_column('AMEX_ROC_COUNT')}
sub TRACKING_ID                 {return $_[0]->_get_column('TRACKING_ID')}
sub TRACKING_ID_DATE            {return $_[0]->_get_column('TRACKING_ID_DATE')}
sub TRACKING_ID_PCID            {return $_[0]->_get_column('TRACKING_ID_PCID')}
sub CPC_INDICATOR               {return $_[0]->_get_column('CPC_INDICATOR')}
sub AMEX_ROC_COUNT_POA          {return $_[0]->_get_column('AMEX_ROC_COUNT_POA')}
sub BASE_DISCOUNT_AMOUNT        {return $_[0]->_get_column('BASE_DISCOUNT_AMOUNT')}
sub CARD_NOT_PRESENT_BPA_AMOUNT {return $_[0]->_get_column('CARD_NOT_PRESENT_BPA_AMOUNT')}
sub CARD_NOT_PRESENT_PTA_AMOUNT {return $_[0]->_get_column('CARD_NOT_PRESENT_PTA_AMOUNT')}
sub CARD_NOT_PRESENT_BPA_RATE   {return $_[0]->_get_column('CARD_NOT_PRESENT_BPA_RATE')}
sub CARD_NOT_PRESENT_PTA_RATE   {return $_[0]->_get_column('CARD_NOT_PRESENT_PTA_RATE')}
sub TRANSACTION_FEE_AMOUNT      {return $_[0]->_get_column('TRANSACTION_FEE_AMOUNT')}
sub TRANSACTION_FEE_RATE        {return $_[0]->_get_column('TRANSACTION_FEE_RATE')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummary - Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC) Summary of Charge (SOC) Detail Rows

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'EPPRC');
 open my $fh, '<', '/path to EPPRC file' or die "cannot open EPPRC file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'SOC_DETAIL') {
    print $record->AMEX_PROCESS_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an EPPRC  file');
 if ($record->type eq 'SOC_DETAIL') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummary object.

 my $record = Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummary->new(line => $line);

=head2 type

This will always return the string SOC_DETAIL.

 print $record->type; # SOC_DETAIL

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 field_map

Returns an arrayref of hashrefs where the name is the record name and 
the value is an arrayref of the start position and length of that field.

 # print the start position of the PAYMENT_YEAR field
 print $record->field_map->[3]->{PAYMENT_YEAR}->[0]; # 31

=head2 AMEX_PAYEE_NUMBER

This field contains the Service Establishment (SE) Number of the merchant that received the payment from American Express.

Note: SE Numbers are assigned by American Express.

=head2 AMEX_SE_NUMBER

This field contains the Service Establishment (SE) Number of the merchant being reconciled, which may not necessarily be the same SE receiving payment (see AMEX_PAYEE_NUMBER).

This is the SE Number under which the transactions were submitted, which usually corresponds to the physical location.

=head2 SE_UNIT_NUMBER

This field contains the merchant-assigned SE Unit Number (usually an internal, store identifier code) that corresponds to a specific store or location.

If no value is assigned, this field is character space filled.

=head2 PAYMENT_YEAR

This field contains the Payment Year that corresponds to the entry in the Julian Date subfield of PAYMENT_NUMBER.

=head2 PAYMENT_NUMBER

This field contains the Payment Number, a reference number used by the American Express Payee to reconcile the daily settlement to the daily payment.

=head2 PAYMENT_NUMBER_DATE

The Julian date of the payment.

=head2 PAYMENT_NUMBER_TYPE

An alpha character assigned by the American Express settlement system.

=head2 PAYMENT_NUMBER_NUMBER

The Number of the payment.

=head2 RECORD_TYPE

This field contains the constant literal “2”, a Record Type code that indicates that this is a Detail Record.

=head2 DETAIL_RECORD_TYPE

This field contains the Detail Record Type code that indicates the type of record used in this transaction. For Summary of Charge (SOC) Detail Records, this entry is always “10”.

=head2 SE_BUSINESS_DATE

This field contains the SE Business Date assigned to this submission by the submitting merchant location.

The format is: YYYYDDD

=over 4

=item YYYY = Year

=item DDD = Julian Date

=back

=head2 AMEX_PROCESS_DATE

This field contains the American Express Transaction Processing Date, which is used to determine the payment date.

The format is: YYYYDDD

=over 4

=item YYYY = Year

=item DDD = Julian Date

=back

=head2 SOC_INVOICE_NUMBER

This field contains the Summary of Charge (SOC) Invoice Number.

=head2 SOC_AMOUNT

This field contains the Summary of Charge (SOC) Amount originally submitted for payment.

Note: For US Dollar (USD) and Canadian Dollar (CAD) transactions, two decimal places are implied.

A debit amount (positive) is indicated by an upper-case alpha code used in place of the last digit in the amount.

The debit codes and their numeric equivalents are listed below:

=over 4

=item 1=A

=item 2=B

=item 3=C

=item 4=D

=item 5=E

=item 6=F

=item 7=G

=item 8=H

=item 9=I

=item 0={

=back

A credit amount (negative) is also indicated by an upper-case alpha code used in place of the last digit in the amount.

The credit codes and their numeric equivalents are listed below:

=over 4

=item 1=J

=item 2=K

=item 3=L

=item 4=M

=item 5=N

=item 6=O

=item 7=P

=item 8=Q

=item 9=R

=item 0=}

=back

The following are examples of how amounts would appear:

 Amount     Debit         Credit
   $1.11    0000000011A   0000000011J
 $345.05    0000003450E   0000003450N
  $22.70    0000000227{   0000000227}

=head2 DISCOUNT_AMOUNT

This field contains the total Discount Amount, based on SOC_AMOUNT and DISCOUNT_RATE.

=head2 SERVICE_FEE_AMOUNT

This field contains the total Service Fee Amount, based on SOC_AMOUNT, and SERVICE_FEE_RATE.

=head2 NET_SOC_AMOUNT

This field contains the Net SOC (Summary of Charge) Amount submitted to American Express for payment, which is the sum total of SOC_AMOUNT, less DISCOUNT_AMOUNT and SERVICE_FEE_AMOUNT.

=head2 DISCOUNT_RATE

This field contains the Discount Rate (decimal place value) used to calculate the amount American Express charges a merchant for services provided per the American Express Card Acceptance Agreement.

=head2 SERVICE_FEE_RATE

This field contains the Service Fee Rate (decimal place value) used to calculate the amount American Express charges a merchant as service fees.

Service fees are assessed only in certain situations and may not apply to all SEs.

=head2 AMEX_GROSS_AMOUNT

This field contains the gross amount of American Express charges submitted in the original SOC amount.

=head2 AMEX_ROC_COUNT

This field contains the quantity of American Express charges submitted in this Summary of Charge (SOC). This entry is always
positive, which is indicated by an upper-case alpha code used in place of the last (least significant) digit.

The alpha codes and their numeric equivalents are listed below:

=over 4

=item 1=A

=item 2=B

=item 3=C

=item 4=D

=item 5=E

=item 6=F

=item 7=G

=item 8=H

=item 9=I

=item 0={

=back

Note: In rare instances, the quantity of American Express charges may exceed the five-byte length of this field; and the actual value may be truncated. In this case, this entry should be ignored, and the actual quantity of American Express charges should be obtained from the seven-byte, AMEX_ROC_COUNT_POA field.

For this reason, American Express strongly recommends that Merchant and Authorized Third Party Processor systems use
AMEX_ROC_COUNT_POA, in lieu of this field.

=head2 TRACKING_ID

This field contains the Tracking ID, which holds SOC processing information.

=head2 TRACKING_ID_DATE

The Julian date for the tracking id.

=head2 TRACKING_ID_PCID

Tracking ID PCID

=head2 CPC_INDICATOR

This field contains the CPC Indicator, which indicates whether the batch that corresponds to this SOC detail record contains CPC/Corporate Purchasing Card (a.k.a., CPS/Corporate Purchasing Solutions Card) transactions.

Valid entries include:

=over 4

=item P = CPC/CPS Card transactions (special pricing applied)

=item ~ = Non-CPC/CPS Card transactions

=back

Note: Tilde (~) represents a character space.

=head2 AMEX_ROC_COUNT_POA

This field contains the quantity of American Express charges submitted in this Summary of Charge (SOC). This entry is always positive, which is indicated by an upper-case alpha code used in place of the last (least significant) digit.

The alpha codes and their numeric equivalents are listed below:

=over 4

=item 1=A

=item 2=B

=item 3=C

=item 4=D

=item 5=E

=item 6=F

=item 7=G

=item 8=H

=item 9=I

=item 0={

=back

Important Note for Merchants Using AMEX_ROC_COUNT_POA:

AMEX_ROC_COUNT and AMEX_ROC_COUNT_POA contain the same basic value, up five significant digits. However, for values greater than “9999I” (99,999), AMEX_ROC_COUNT_POA should be used; because the value in AMEX_ROC_COUNT is truncated at five bytes.

=head2 BASE_DISCOUNT_AMOUNT

This field contains the total Base Discount Amount applied. A negative amount represents a debit or a deduction, and a positive amount indicates a payment or credit.

This value may be a debit or credit; and the format is a 1-digit “sign”, followed by a 15-digit “dollar amount”.

For a debit (a negative amount), the first position is a minus sign; and a “negative $100.00” would appear as:

 0        1
 1234567890123456
 -000000000010000

For a credit (a positive amount), the first position is a character space; and a “positive $100.00” would appear as:

 0        1
 1234567890123456
 _000000000010000

Note: The underline character ( _ ) represents a character space.

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 CARD_NOT_PRESENT_BPA_AMOUNT

This field contains the Card Not Present, Basis Point Adjustment Amount. A negative amount represents a debit or a deduction, and a positive amount indicates a payment or credit.

This value may be a debit or credit; and the format is a 1-digit “sign”, followed by a 15-digit “dollar amount”.

See examples of negative and positive entries under BASE_DISCOUNT_AMOUNT.

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 CARD_NOT_PRESENT_PTA_AMOUNT

This field contains the Card Not Present, Per Transaction Adjustment Amount. A negative amount represents a debit or a deduction, and a positive amount indicates a payment or credit.

This value may be a debit or credit; and the format is a 1-digit “sign”, followed by a 15-digit “dollar amount”.

See examples of negative and positive entries under BASE_DISCOUNT_AMOUNT.

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 CARD_NOT_PRESENT_BPA_RATE

This field contains the Card Not Present, Basis Point Adjustment Rate applied to Card Not Present transactions.

This value may be a debit or credit rate. The format is a 1-digit “sign”, followed by an 8-digit “rate”.

For a debit (a negative rate), the first position is a minus sign; and a “negative .003 (.30%)” would appear as:

 0
 123456789
 -00000300

For a credit (a positive rate), the first position is a character space; and a “positive .003 (.30%)” would appear as:

 0
 123456789
 _00000300

Note: The underline character ( _ ) represents a character space.

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 CARD_NOT_PRESENT_PTA_RATE

This field contains the Card Not Present, Per Transaction Adjustment Rate applied to Card Not Present transactions.

This value may be a debit or credit rate. The format is a 1-digit “sign”, followed by an 8-digit “rate”.

For a debit (a negative rate), the first position is a minus sign; and a “negative .10” would appear as:

 0
 123456789
 -00010000

For a credit (a positive rate), the first position is a character space; and a “positive .10” would appear as:

 0
 123456789
 _00010000

Note: The underline character ( _ ) represents a character space.

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 TRANSACTION_FEE_AMOUNT

This field contains the total Transaction Fee Amount applied to the Merchant’s settlement file. A negative amount represents a debit or a deduction, and a positive amount indicates a payment or credit.

This value may be a debit or credit; and the format is a 1-digit “sign”, followed by a 15-digit “dollar amount”.

See examples of negative and positive entries under CARD_NOT_PRESENT_PTA_RATE.

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 TRANSACTION_FEE_RATE

This field contains the Transaction Fee Rate applied to transactions in the Merchant’s settlement file, in accordance with the Merchant Pricing Plan.

This value may be a debit or credit rate. The format is a 1-digit “sign”, followed by an 8-digit “rate”.

See examples of rate entries under CARD_NOT_PRESENT_BPA_RATE.

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head1 NAME

Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummary - Object methods for AMEX Reconciliation file summary of charge detail records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by ZipRecruiter/Tom Heady.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
