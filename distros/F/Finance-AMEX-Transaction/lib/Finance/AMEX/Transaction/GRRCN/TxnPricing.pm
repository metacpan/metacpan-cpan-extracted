package Finance::AMEX::Transaction::GRRCN::TxnPricing;
$Finance::AMEX::Transaction::GRRCN::TxnPricing::VERSION = '0.002';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Global Reconciliation (GRRCN) Transaction or ROC pricing Rows

use base 'Finance::AMEX::Transaction::GRRCN::Base';

sub field_map {
  return {
    RECORD_TYPE                     => [1, 10],
    PAYEE_MERCHANT_ID               => [11, 15],
    SETTLEMENT_ACCOUNT_TYPE_CODE    => [26, 3],
    AMERICAN_EXPRESS_PAYMENT_NUMBER => [29, 10],
    PAYMENT_DATE                    => [39, 8],
    PAYMENT_CURRENCY                => [47, 3],
    SUBMISSION_MERCHANT_ID          => [50, 15],

    MERCHANT_LOCATION_ID            => [65, 15],
    INVOICE_REFERENCE_NUMBER        => [95, 30],
    SELLER_ID                       => [125, 20],
    CARDMEMBER_ACCOUNT_NUMBER       => [145, 19],
    TRANSACTION_AMOUNT              => [164, 16],
    TRANSACTION_DATE                => [180, 8],
    FEE_CODE                        => [188, 2],
    FEE_AMOUNT                      => [197, 22],
    DISCOUNT_RATE                   => [216, 7],
    DISCOUNT_AMOUNT                 => [226, 22],
  };
}

sub type {return 'TXNPRICING'}

sub RECORD_TYPE                     {return $_[0]->_get_column('RECORD_TYPE')}
sub PAYEE_MERCHANT_ID               {return $_[0]->_get_column('PAYEE_MERCHANT_ID')}
sub SETTLEMENT_ACCOUNT_TYPE_CODE    {return $_[0]->_get_column('SETTLEMENT_ACCOUNT_TYPE_CODE')}
sub AMERICAN_EXPRESS_PAYMENT_NUMBER {return $_[0]->_get_column('AMERICAN_EXPRESS_PAYMENT_NUMBER')}
sub PAYMENT_DATE                    {return $_[0]->_get_column('PAYMENT_DATE')}
sub PAYMENT_CURRENCY                {return $_[0]->_get_column('PAYMENT_CURRENCY')}
sub SUBMISSION_MERCHANT_ID          {return $_[0]->_get_column('SUBMISSION_MERCHANT_ID')}

sub MERCHANT_LOCATION_ID            {return $_[0]->_get_column('MERCHANT_LOCATION_ID')}
sub INVOICE_REFERENCE_NUMBER        {return $_[0]->_get_column('INVOICE_REFERENCE_NUMBER')}
sub SELLER_ID                       {return $_[0]->_get_column('SELLER_ID')}
sub CARDMEMBER_ACCOUNT_NUMBER       {return $_[0]->_get_column('CARDMEMBER_ACCOUNT_NUMBER')}
sub TRANSACTION_AMOUNT              {return $_[0]->_get_column('TRANSACTION_AMOUNT')}
sub TRANSACTION_DATE                {return $_[0]->_get_column('TRANSACTION_DATE')}
sub FEE_CODE                        {return $_[0]->_get_column('FEE_CODE')}
sub FEE_AMOUNT                      {return $_[0]->_get_column('FEE_AMOUNT')}
sub DISCOUNT_RATE                   {return $_[0]->_get_column('DISCOUNT_RATE')}
sub DISCOUNT_AMOUNT                 {return $_[0]->_get_column('DISCOUNT_AMOUNT')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::GRRCN::TxnPricing - Parse AMEX Global Reconciliation (GRRCN) Transaction or ROC pricing Rows

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'GRRCN');
 open my $fh, '<', '/path to GRRCN file' or die "cannot open GRRCN file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'TXNPRICING') {
    print $record->PAYMENT_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an GRRCN file');
 if ($record->type eq 'TXNPRICING') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new L<Finance::AMEX::Transaction::GRRCN::TxnPricing> object.

 my $record = Finance::AMEX::Transaction::GRRCN::TxnPricing->new(line => $line);

=head2 type

This will always return the string TXNPRICING.

 print $record->type; # TXNPRICING

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 RECORD_TYPE

This field contains the Record identifier, which will always be “TXNPRICING” for the Transaction Pricing Record.

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

This field contains the Service Establishment (SE) Number of the Merchant being reconciled.

=head2 MERCHANT_LOCATION_ID

This field contains the Merchant-assigned SE Unit Number (usually an internal, store identifier code) that corresponds to a specific store or location.

If unused, this field is character space filled (fixed format) or blank (delimited formats).

=head2 INVOICE_REFERENCE_NUMBER

This field contains the Invoice/Reference Number assigned by the Merchant or Partner to this transaction at the time the sale was executed.

This is a transaction-level identifier used by the Merchant for identification and reconciliation purposes.

=head2 SELLER_ID

This field contains the Seller ID, 20-byte code that uniquely identifies a Payment Aggregator or OptBlue Participant's specific seller or vendor.

When no value is assigned this field will be character space filled (fixed format) or blank (delimited formats).

=head2 CARDMEMBER_ACCOUNT_NUMBER

This field contains the Cardmember Account Number that corresponds to this transaction.

Note: if Card number masking is enabled this field is required to accept alphanumeric characters).

JCB card transactions may appear in the reconciliation file. JCB transactions can be distinguished using the Issuer Identification Number (IIN), previously known as bank identification number (BIN), as represented by the first six digits of the credit card number. JCB card numbers begin with ‘35’ and will be 16 digits in length, whereas American Express card numbers begin with ‘37’ and will be 15 digits in length.

=head2 TRANSACTION_AMOUNT

This field contains the Transaction or Record of Charge (ROC) Amount for a single transaction.

This value is expressed in the Submission currency.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 TRANSACTION_DATE

This field contains the Transaction Date, which is the date the transaction took place as specified by Merchant in the submission file.

The format is: YYYYMMDD

=over 4

=item YYYY = Year

=item MM   = Month

=item DD   = Day

=back

=head2 FEE_CODE

This field contains a Fee Code that corresponds to the preceding ROC Detail Record. Refer to the Appendix for a list of Fee Codes and their associated descriptions.

Please refrain from hard coding the Fee Codes into your application as American Express reserves the right to make changes. Hard-Coding to this field may result in file failures.

This field is applicable to the U.S. and Canada only.

=head2 FEE_AMOUNT

This field contains the Fee Amount charged by American Express for this transaction to six decimal places.

This value is expressed in the Submission currency.

For a typical debit ROC/transaction, the fee amount is signed positive.

The format of this field is:

Position 1 (1) is a signed field and will be either a space for a credit amount or a '-' sign for a debit amount.

Positions 2-16 (15) are whole numbers.

Positions 17-22 (6) are decimal places.

For example: ‘000000000000056789000’ represents a positive amount of 56.789. ‘-000000000000056789000’ represents a negative amount of 56.789.

=head2 DISCOUNT_RATE

This field contains the Discount Rate (decimal place value) used to calculate the amount American Express charges for services and corresponds to the preceding Transaction or ROC Detail Record. It acts as a proportion of the transaction amount.

Though a signed field, discount rate is always expressed as a positive value.

It is also possible in certain countries which have local goods and services tax, such as Australia and Mexico, that this field will contain the tax rate as a proportion of the discount amount.

For an explanation of rate syntax, see Submission Record, SUBMISSION_DISCOUNT_RATE.

=head2 DISCOUNT_AMOUNT

This field contains the Discount Amount charged by American Express for this transaction to six decimal places.

It is also possible that in some markets with local goods and services taxes, such as Australia and Mexico, that this field will contain a tax amount applicable to the transaction.

This value is expressed in the Submission currency.

For a typical debit transaction/ROC, the discount amount is signed positive.

The format of this field is:

Position 1 (1) is a signed field and will be either a space for a credit amount or a '-' sign for a debit amount.

Positions 2-16 (15) are whole numbers.

Positions 17-22 (6) are decimal places.

For example: ‘000000000000056789000’ represents a positive amount of 56.789, while ‘-000000000000056789000’ represents a negative amount of 56.789.

=head1 NAME

Finance::AMEX::Transaction::GRRCN::TxnPricing - Object methods for AMEX Global Reconciliation (GRRCN) transaction or ROC pricing records.

=head1 AUTHOR

Tom Heady <theady@ziprecruiter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
