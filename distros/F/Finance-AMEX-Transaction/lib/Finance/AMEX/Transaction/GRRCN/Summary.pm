package Finance::AMEX::Transaction::GRRCN::Summary 0.005;

use strict;
use warnings;

# ABSTRACT: Parse AMEX Global Reconciliation (GRRCN) Summary Rows

use base 'Finance::AMEX::Transaction::GRRCN::Base';

sub field_map {
  return [
    {RECORD_TYPE                       => [1,   10]},
    {PAYEE_MERCHANT_ID                 => [11,  15]},
    {SETTLEMENT_ACCOUNT_TYPE_CODE      => [26,  3]},
    {AMERICAN_EXPRESS_PAYMENT_NUMBER   => [29,  10]},
    {PAYMENT_DATE                      => [39,  8]},
    {PAYMENT_CURRENCY                  => [47,  3]},
    {UNIQUE_PAYMENT_REFERENCE_NUMBER   => [50,  18]},
    {PAYMENT_NET_AMOUNT                => [68,  16]},
    {PAYMENT_GROSS_AMOUNT              => [84,  16]},
    {PAYMENT_DISCOUNT_AMOUNT           => [100, 16]},
    {PAYMENT_SERVICE_FEE_AMOUNT        => [116, 16]},
    {PAYMENT_ADJUSTMENT_AMOUNT         => [132, 16]},
    {PAYMENT_TAX_AMOUNT                => [148, 16]},
    {OPENING_DEBIT_BALANCE_AMOUNT      => [164, 16]},
    {PAYEE_DIRECT_DEPOSIT_NUMBER       => [180, 17]},
    {BANK_ACCOUNT_NUMBER               => [197, 34]},
    {INTERNATIONAL_BANK_ACCOUNT_NUMBER => [231, 34]},
    {BANK_IDENTIFIER_CODE              => [265, 15]},
    {FILLER1                           => [280, 521]},
  ];
}

sub type {return 'SUMMARY'}

sub RECORD_TYPE                       {return $_[0]->_get_column('RECORD_TYPE')}
sub PAYEE_MERCHANT_ID                 {return $_[0]->_get_column('PAYEE_MERCHANT_ID')}
sub SETTLEMENT_ACCOUNT_TYPE_CODE      {return $_[0]->_get_column('SETTLEMENT_ACCOUNT_TYPE_CODE')}
sub AMERICAN_EXPRESS_PAYMENT_NUMBER   {return $_[0]->_get_column('AMERICAN_EXPRESS_PAYMENT_NUMBER')}
sub PAYMENT_DATE                      {return $_[0]->_get_column('PAYMENT_DATE')}
sub PAYMENT_CURRENCY                  {return $_[0]->_get_column('PAYMENT_CURRENCY')}
sub UNIQUE_PAYMENT_REFERENCE_NUMBER   {return $_[0]->_get_column('UNIQUE_PAYMENT_REFERENCE_NUMBER')}
sub PAYMENT_NET_AMOUNT                {return $_[0]->_get_column('PAYMENT_NET_AMOUNT')}
sub PAYMENT_GROSS_AMOUNT              {return $_[0]->_get_column('PAYMENT_GROSS_AMOUNT')}
sub PAYMENT_DISCOUNT_AMOUNT           {return $_[0]->_get_column('PAYMENT_DISCOUNT_AMOUNT')}
sub PAYMENT_SERVICE_FEE_AMOUNT        {return $_[0]->_get_column('PAYMENT_SERVICE_FEE_AMOUNT')}
sub PAYMENT_ADJUSTMENT_AMOUNT         {return $_[0]->_get_column('PAYMENT_ADJUSTMENT_AMOUNT')}
sub PAYMENT_TAX_AMOUNT                {return $_[0]->_get_column('PAYMENT_TAX_AMOUNT')}
sub OPENING_DEBIT_BALANCE_AMOUNT      {return $_[0]->_get_column('OPENING_DEBIT_BALANCE_AMOUNT')}
sub PAYEE_DIRECT_DEPOSIT_NUMBER       {return $_[0]->_get_column('PAYEE_DIRECT_DEPOSIT_NUMBER')}
sub BANK_ACCOUNT_NUMBER               {return $_[0]->_get_column('BANK_ACCOUNT_NUMBER')}
sub INTERNATIONAL_BANK_ACCOUNT_NUMBER {return $_[0]->_get_column('INTERNATIONAL_BANK_ACCOUNT_NUMBER')}
sub BANK_IDENTIFIER_CODE              {return $_[0]->_get_column('BANK_IDENTIFIER_CODE')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::GRRCN::Summary - Parse AMEX Global Reconciliation (GRRCN) Summary Rows

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'GRRCN');
 open my $fh, '<', '/path to GRRCN file' or die "cannot open GRRCN file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'SUMMARY') {
    print $record->PAYMENT_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an GRRCN  file');
 if ($record->type eq 'SUMMARY') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new L<Finance::AMEX::Transaction::GRRCN::Summary> object.

 my $record = Finance::AMEX::Transaction::GRRCN::Summary->new(line => $line);

=head2 type

This will always return the string SUMMARY.

 print $record->type; # SUMMARY

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 field_map

Returns an arrayref of hashrefs where the name is the record name and 
the value is an arrayref of the start position and length of that field.

 # print the start position of the PAYMENT_DATE field
 print $record->field_map->[4]->{PAYMENT_DATE}->[0]; # 39

=head2 RECORD_TYPE

This field contains the Record identifier, which will always be “SUMMARY” for the Summary Record.

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

=head2 UNIQUE_PAYMENT_REFERENCE_NUMBER

This field contains a Unique Payment Reference (UPR) reserved for use by specific Merchants. If unused, this field will be character space filled (fixed format) or blank (delimited formats).

=head2 PAYMENT_NET_AMOUNT

This field contains the actual Payment or Net Amount, expressed in the Payment (Settlement) currency. This is an amount credited to the payee's account for the activities listed in the detail submission records. Will be signed negative to represent a debit amount.

Calculation for Payment Net Amount = Payment Gross Amount - Payment Discount Amount - Payment Service Fee Amount - Payment Tax Amount + Payment Adjustment Amount + Opening Debit Balance Amount.

The format for all amount fields is that they are 16 bytes in length in CNNNNNNNNNNNNNNN format.

=over 4

=item C = an alphanumeric value which indicates whether the amount is a credit or debit value. In the case of a credit amount a character space will appear in this position. In the case of a debit amount a minus (‘-’) will be in this position.

=item N = Numeric value right aligned with leading zeros. Assumed two decimal places but will vary according to currency.

=back

=head2 PAYMENT_GROSS_AMOUNT

This field contains the Payment Gross Amount which is the sum of all the submission gross amounts in this payment/settlement, expressed in the Payment (Settlement) currency.

For formats of amount values, see description in PAYMENT_NET_AMOUNT.

=head2 PAYMENT_DISCOUNT_AMOUNT

This field contains the total Discount Amount for the payment/settlement, expressed in the Payment (Settlement) currency. For a normal settlement where American Express makes a credit payment to the Merchant's account, the payment discount amount will be signed positive. If the
settlement results in a debit to the Merchant's account (i.e., no payment is made) then the payment discount amount will be negative.

For formats of amount values, see description in PAYMENT_NET_AMOUNT.

For U.S. and Canada Merchants using Gross Pay, this field is for information purposes only. Aggregated Discount and Service Fees to be debited will be recorded in the Fees &Revenues Record on the date of debit from the Merchant's account.

=head2 PAYMENT_SERVICE_FEE_AMOUNT

This field contains the Service Fee Amount, expressed in the Payment (Settlement) currency.

For a normal settlement where American Express makes a credit payment to the Merchant's account, any service fee amount will be signed positive. If the settlement results in a debit from the Merchant's account (i.e., no payment is made) then the payment service fee amount will be negative.

For formats of amount values, see description in PAYMENT_NET_AMOUNT.

For U.S. and Canada Merchants using Gross Pay, this field is for information purposes only. Aggregated Discount and Service Fees to be debited will be recorded in the Fees & Revenues Record on the date of debit from the Merchant's account.

=head2 PAYMENT_ADJUSTMENT_AMOUNT

This field contains the Payment Adjustment Amount, expressed in the Payment (Settlement) currency. This reflects the net amount of all adjustment and chargeback records included in this summary. This field will be signed negative to represent a debit amount.

For formats of amount values, see description in PAYMENT_NET_AMOUNT.

=head2 PAYMENT_TAX_AMOUNT

This field contains the Payment Tax Amount, expressed in the Payment (Settlement) currency, which is only applicable to the following specific markets:

 LAC            Mexico / Bahamas / Panama / Argentina
 JAPA           Australia / India / Japan
 EMEA           Germany / Austria
 Multi-Currency Mexico / Australia

If unused, this field will be space filled (fixed format) or blank (delimited formats). For a normal settlement where American Express makes a credit payment to the Merchant's account, any tax amount will be signed positive. If the settlement results in a debit from the Merchant's account (i.e., no payment is made) then the payment tax amount will be negative.

For formats of amount values, see description in PAYMENT_NET_AMOUNT.

=head2 OPENING_DEBIT_BALANCE_AMOUNT

This field contains any current Debit Balance on the SE account for information, expressed in the Payment (Settlement) currency. If present this will always be signed as a negative amount.

For formats of amount values, see description in PAYMENT_NET_AMOUNT.

This field will be space filled (fixed format) or blank (delimited) if there is no debit balance.

=head2 PAYEE_DIRECT_DEPOSIT_NUMBER

This field contains the Payee's Direct Deposit Account Number to which the payment was transferred.

This field is only used in the U.S. and Canada and will be space filled (fixed format) or blank (delimited) if not in this market or not available.

=head2 BANK_ACCOUNT_NUMBER

This field contains the ABA Bank Number to which the payment was transferred.

This field is only used in the U.S. and Canada and will be character space filled (fixed format) or blank (delimited) if not in this market or not available.

=head2 INTERNATIONAL_BANK_ACCOUNT_NUMBER

This field is only used for markets where an International Bank Account Number (IBAN) is available. Otherwise it will be character space filled (fixed format) or blank (delimited) if not in this market or not available.

=head2 BANK_IDENTIFIER_CODE

This field contains the Bank Identifier Code (BIC) of the bank/branch, also known as a “Swift Code”.

This field is only used for markets where a BIC is available. Otherwise it will be character space filled (fixed format) or blank (delimited) if not in this market or not available.

=head1 NAME

Finance::AMEX::Transaction::GRRCN::Summary - Object methods for AMEX Reconciliation file summary records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by ZipRecruiter/Tom Heady.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
