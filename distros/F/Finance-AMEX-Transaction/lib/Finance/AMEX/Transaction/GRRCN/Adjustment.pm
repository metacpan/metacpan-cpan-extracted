package Finance::AMEX::Transaction::GRRCN::Adjustment;
$Finance::AMEX::Transaction::GRRCN::Adjustment::VERSION = '0.002';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Global Reconciliation (GRRCN) Adjustment Rows

use base 'Finance::AMEX::Transaction::GRRCN::Base';

sub field_map {
  return {
    RECORD_TYPE                        => [1, 10],
    PAYEE_MERCHANT_ID                  => [11, 15],
    SETTLEMENT_ACCOUNT_TYPE_CODE       => [26, 3],
    AMERICAN_EXPRESS_PAYMENT_NUMBER    => [29, 10],
    PAYMENT_DATE                       => [39, 8],
    PAYMENT_CURRENCY                   => [47, 3],
    SUBMISSION_MERCHANT_ID             => [50, 15],

    BUSINESS_SUBMISSION_DATE           => [65, 8],
    MERCHANT_LOCATION_ID               => [73, 15],
    INVOICE_REFERENCE_NUMBER           => [88, 30],
    SELLER_ID                          => [118, 20],
    CARDMEMBER_ACCOUNT_NUMBER          => [138, 19],
    INDUSTRY_SPECIFIC_REFERENCE_NUMBER => [157, 30],
    AMEX_PROCESSING_DATE               => [187, 8],
    SUBMISSION_INVOICE_NUMBER          => [195, 15],
    SUBMISSION_CURRENCY                => [210, 3],
    ADJUSTMENT_NUMBER                  => [213, 30],
    ADJUSTMENT_REASON_CODE             => [243, 10],
    ADJUSTMENT_REASON_DESCRIPTION      => [253, 280],
    GROSS_AMOUNT                       => [533, 16],
    DISCOUNT_AMOUNT                    => [549, 16],
    SERVICE_FEE_AMOUNT                 => [565, 16],
    TAX_AMOUNT                         => [581, 16],
    NET_AMOUNT                         => [597, 16],
    DISCOUNT_RATE                      => [613, 7],
    SERVICE_FEE_RATE                   => [620, 7],
    BATCH_CODE                         => [627, 3],
    BILL_CODE                          => [630, 3],

  };
}

sub type {return 'ADJUSTMENT'}

sub RECORD_TYPE                        {return $_[0]->_get_column('RECORD_TYPE')}
sub PAYEE_MERCHANT_ID                  {return $_[0]->_get_column('PAYEE_MERCHANT_ID')}
sub SETTLEMENT_ACCOUNT_TYPE_CODE       {return $_[0]->_get_column('SETTLEMENT_ACCOUNT_TYPE_CODE')}
sub AMERICAN_EXPRESS_PAYMENT_NUMBER    {return $_[0]->_get_column('AMERICAN_EXPRESS_PAYMENT_NUMBER')}
sub PAYMENT_DATE                       {return $_[0]->_get_column('PAYMENT_DATE')}
sub PAYMENT_CURRENCY                   {return $_[0]->_get_column('PAYMENT_CURRENCY')}
sub SUBMISSION_MERCHANT_ID             {return $_[0]->_get_column('SUBMISSION_MERCHANT_ID')}

sub BUSINESS_SUBMISSION_DATE           {return $_[0]->_get_column('BUSINESS_SUBMISSION_DATE')}
sub MERCHANT_LOCATION_ID               {return $_[0]->_get_column('MERCHANT_LOCATION_ID')}
sub INVOICE_REFERENCE_NUMBER           {return $_[0]->_get_column('INVOICE_REFERENCE_NUMBER')}
sub SELLER_ID                          {return $_[0]->_get_column('SELLER_ID')}
sub CARDMEMBER_ACCOUNT_NUMBER          {return $_[0]->_get_column('CARDMEMBER_ACCOUNT_NUMBER')}
sub INDUSTRY_SPECIFIC_REFERENCE_NUMBER {return $_[0]->_get_column('INDUSTRY_SPECIFIC_REFERENCE_NUMBER')}
sub AMEX_PROCESSING_DATE               {return $_[0]->_get_column('AMEX_PROCESSING_DATE')}
sub SUBMISSION_INVOICE_NUMBER          {return $_[0]->_get_column('SUBMISSION_INVOICE_NUMBER')}
sub SUBMISSION_CURRENCY                {return $_[0]->_get_column('SUBMISSION_CURRENCY')}
sub ADJUSTMENT_NUMBER                  {return $_[0]->_get_column('ADJUSTMENT_NUMBER')}
sub ADJUSTMENT_REASON_CODE             {return $_[0]->_get_column('ADJUSTMENT_REASON_CODE')}
sub ADJUSTMENT_REASON_DESCRIPTION      {return $_[0]->_get_column('ADJUSTMENT_REASON_DESCRIPTION')}
sub GROSS_AMOUNT                       {return $_[0]->_get_column('GROSS_AMOUNT')}
sub DISCOUNT_AMOUNT                    {return $_[0]->_get_column('DISCOUNT_AMOUNT')}
sub SERVICE_FEE_AMOUNT                 {return $_[0]->_get_column('SERVICE_FEE_AMOUNT')}
sub TAX_AMOUNT                         {return $_[0]->_get_column('TAX_AMOUNT')}
sub NET_AMOUNT                         {return $_[0]->_get_column('NET_AMOUNT')}
sub DISCOUNT_RATE                      {return $_[0]->_get_column('DISCOUNT_RATE')}
sub SERVICE_FEE_RATE                   {return $_[0]->_get_column('SERVICE_FEE_RATE')}
sub BATCH_CODE                         {return $_[0]->_get_column('BATCH_CODE')}
sub BILL_CODE                          {return $_[0]->_get_column('BILL_CODE')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::GRRCN::Adjustment - Parse AMEX Global Reconciliation (GRRCN) Adjustment Rows

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'GRRCN');
 open my $fh, '<', '/path to GRRCN file' or die "cannot open GRRCN file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'ADJUSTMENT') {
    print $record->PAYMENT_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an GRRCN file');
 if ($record->type eq 'ADJUSTMENT') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new L<Finance::AMEX::Transaction::GRRCN::Adjustment> object.

 my $record = Finance::AMEX::Transaction::GRRCN::Adjustment->new(line => $line);

=head2 type

This will always return the string ADJUSTMENT.

 print $record->type; # ADJUSTMENT

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 RECORD_TYPE

This field contains the record identifier, which will always be “ADJUSTMENT” for the Adjustment Record.

=head2 PAYEE_MERCHANT_ID

This field contains the American Express-assigned Service Establishment (SE) Number of the Merchant receiving the payment/settlement.

=head2 SETTLEMENT_ACCOUNT_TYPE_CODE

This field contains the Settlement Account Type.

Valid values include the following:

=over 4

=item 002 = Primary

=item 001 = Discount

=item 004 = All Chargebacks

=back

If unused, this field will be space filled (fixed format) or blank (delimited formats).

=head2 AMERICAN_EXPRESS_PAYMENT_NUMBER

This field contains the American Express-assigned Payment/Settlement Number. This reference number may be used by the American Express Payee for reconciliation purposes.

=head2 PAYMENT_DATE

This field contains the Payment Date scheduled in American Express systems. The date that funds are actually available to the payee's depository institution may differ from the date reported in this field.

The format is: YYYYMMDD

=over 4

=item YYYY = Year

=item MM   = Month

=item DD   = Day

=back

=head2 PAYMENT_CURRENCY

This field contains the Alphanumeric ISO Code for the Payment (Settlement) currency.

=head2 SUBMISSION_MERCHANT_ID

This field contains the Service Establishment (SE) Number of the Merchant being reconciled, which may not necessarily be the same SE receiving payment.

=head2 BUSINESS_SUBMISSION_DATE

This field contains the date assigned by the Merchant or Partner to this submission.

The format is: YYYYMMDD

=over 4

=item YYYY = Year

=item MM   = Month

=item DD   = Day

=back

=head2 MERCHANT_LOCATION_ID

This field contains the Merchant-assigned SE Unit Number (such as an internal, store identifier code) that corresponds to a specific store or location.

If unused, this field is character space filled (fixed format) or blank (delimited formats).

=head2 INVOICE_REFERENCE_NUMBER

This field contains the Invoice/Reference Number assigned by the Merchant or Partner to this transaction at the time the sale was executed.

This is a transaction level identifier used by the Merchant for identification and reconciliation purposes.

If unused, this field is character space filled (fixed format) or blank (delimited).

=head2 SELLER_ID

This field contains the Seller ID, 20-byte code that uniquely identifies a Payment Aggregator or OptBlue Participant's specific seller or vendor.

When no value is assigned this field will be character space filled (fixed format) or blank (delimited formats).

=head2 CARDMEMBER_ACCOUNT_NUMBER

This field contains the Cardmember Account Number that corresponds to this transaction.

Note: if Card number masking is enabled this field is required to accept alphanumeric characters.

JCB card transactions may appear in the reconciliation file. JCB transactions can be distinguished using the Issuer Identification Number (IIN), previously known as bank identification number (BIN), as represented by the first six digits of the credit card number. JCB card numbers begin with ‘35’ and will be 16 digits in length, whereas American Express card numbers begin with ‘37’ and will be 15 digits in length.

If unused, this field is character space filled (fixed format) or blank (delimited).

=head2 INDUSTRY_SPECIFIC_REFERENCE_NUMBER

This field contains an industry-specific identifier, which corresponds to the relevant identifier submitted originally by the Merchant, Payment Service Provider or Partner. It will be one of the following IDs, depending on the industry-specific addenda records used when submitting the invoice to American Express:

=over 4

=item Airline ticket number

=item Rental agreement number

=item Insurance policy number

=item Rail ticket number

=item Travel ticket number

=back

If unused, this position will be space filled (fixed format) or blank (delimited formats).

=head2 AMEX_PROCESSING_DATE

This field contains the American Express Transaction Processing Date, which is used to determine the payment date scheduled in the American Express Systems.

The format is: YYYYMMDD

=over 4

=item YYYY = Year

=item MM   = Month

=item DD   = Day

=back

=head2 SUBMISSION_INVOICE_NUMBER

This field contains the Summary of Charge (SOC) Invoice number.

This field may not always be populated if no Summary of Charge or Submission Invoice Number is assigned.

=head2 SUBMISSION_CURRENCY

This field contains the Submission Currency Code in ISO format. Refer to the Global Codes & Information Guide.

=head2 ADJUSTMENT_NUMBER

This field contains the American Express-assigned reference number which relates to this adjustment.

=head2 ADJUSTMENT_REASON_CODE

This field contains the Adjustment Reason Code used by American Express systems according to the region of the adjustment.

This field is not available in the U.S.and Canada. This field is international only.

If unused, this field is character space filled (fixed format) or blank (delimited).

=head2 ADJUSTMENT_REASON_DESCRIPTION

This field contains the Adjustment Reason Description, which is the reason the Merchant is assigned the amount that appears in NET_AMOUNT.

If unused, this field is character space filled (fixed format) or blank (delimited).

=head2 GROSS_AMOUNT

This field contains the Gross Amount relating to this Adjustment Record.

This value is expressed in the Payment (Settlement) currency.

Typically signed negative to indicate a debit to the Merchant's account, though may also be signed positive to indicate a credit.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 DISCOUNT_AMOUNT

This field contains the total Discount Amount relating to this Adjustment Record.

This value is expressed in the Payment (Settlement) currency.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 SERVICE_FEE_AMOUNT

This field contains the total Service Fee Amount relating to this Adjustment.

This value is expressed in the Payment (Settlement) currency.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 TAX_AMOUNT

This field contains the Tax Amount relating to this Adjustment, which is only applicable to the following specific markets:

 LAC              Mexico / Bahamas / Panama / Argentina
 JAPA             Australia / India / Japan
 EMEA             Germany / Austria
 Multi-Currency   Mexico / Australia

This value is expressed in the Payment (Settlement) currency.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 NET_AMOUNT

This field contains the Net Amount of the adjustment, which is the gross amount less deductions.

This value is expressed in the Payment (Settlement) currency.

Typically signed negative to indicate a debit to the Merchant's account, though may also be signed positive for a credit to the Merchant.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 DISCOUNT_RATE

This field contains the Discount Rate, which is a percentage used to calculate the American Express charge as its discount amount.

This field is always signed positive.

For an explanation of rate syntax, see Submission Record, SUBMISSION_DISCOUNT_RATE.

=head2 SERVICE_FEE_RATE

This field contains the Service Fee Rate used to calculate the amount American Express charges a Merchant as service fees.

This field is always signed positive.

For an explanation of rate syntax, see Submission Record, SUBMISSION_DISCOUNT_RATE.

=head2 BATCH_CODE

This field contains the three-digit, numeric Batch Code that corresponds to the Adjustment Reason, when used in conjunction with Bill Code.

If unused, this field is character space filled (fixed format) or blank (delimited).

This field applies to the U.S. and Canada only.

=head2 BILL_CODE

This field contains the three-digit, numeric Bill Code that corresponds to the Chargeback Reason, when used in conjunction with Batch Code.

Refer to the Appendix for a list of Bill Codes and their associated descriptions.

This field applies to the U.S. and Canada only.

Please refrain from hard coding the Bill Codes into your application as American Express reserves the right to make changes. Hard-Coding to this field may result in file failures.

If unused, this field is character space filled (fixed format) or blank (delimited).

=over 4

=item 603 Debit for processing error Chargeback

=item 604 Debit for multiple charge

=item 605 Credit processed as Charge

=item 610 Debit as no approval gained

=item 613 Debit as Charge on expired/invalid card

=item 631 Miscellaneous

=item 641 Debit authorized by the merchant

=item 642 Debit for insufficient reply

=item 643 Debit for no reply to inquiry

=item 644 Debit for Fraud Full Recourse

=item 645 Incorrect account number

=item 646 Debit as credit not received by Cardmember

=item 651 Debit as Cardmember paid direct

=item 652 Debit for fraudulent transaction

=item 653 Debit as Cardmember cancelled goods/services

=item 661 Reversal of previous debit

=item 689 Not as described or defective merchandise

=item 690 Not as described or defective merchandise

=item 691 Goods not received

=item 692 Debit for unproven rental charge

=back

=head1 NAME

Finance::AMEX::Transaction::GRRCN::Adjustment - Object methods for AMEX Global Reconciliation (GRRCN) adjustment records.

=head1 AUTHOR

Tom Heady <theady@ziprecruiter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
