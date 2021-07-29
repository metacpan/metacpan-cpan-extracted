package Finance::AMEX::Transaction::GRRCN::FeeRevenue;
$Finance::AMEX::Transaction::GRRCN::FeeRevenue::VERSION = '0.004';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Global Reconciliation (GRRCN) Fees and Revenues Record Rows

use base 'Finance::AMEX::Transaction::GRRCN::Base';

sub field_map {
  return {
    RECORD_TYPE                     => [1, 10],
    PAYEE_MERCHANT_ID               => [11, 15],
    AMERICAN_EXPRESS_PAYMENT_NUMBER => [26, 10],
    PAYMENT_DATE                    => [36, 8],
    PAYMENT_CURRENCY                => [44, 3],

    SUBMISSION_MERCHANT_ID          => [47, 15],
    MERCHANT_LOCATION_ID            => [62, 15],

    FEE_OR_REVENUE_AMOUNT           => [77, 16],
    FEE_OR_REVENUE_DESCRIPTION      => [93, 80],
    ASSET_BILLING_AMOUNT            => [173, 16],
    ASSET_BILLING_DESCRIPTION       => [189, 65],
    ASSET_BILLING_TAX               => [254, 16],
    PAY_IN_GROSS_INDICATOR          => [270, 1],
    BATCH_CODE                      => [271, 3],
    BILL_CODE                       => [274, 3],
  };
}

sub type {return 'FEEREVENUE'}

sub RECORD_TYPE                     {return $_[0]->_get_column('RECORD_TYPE')}
sub PAYEE_MERCHANT_ID               {return $_[0]->_get_column('PAYEE_MERCHANT_ID')}
sub AMERICAN_EXPRESS_PAYMENT_NUMBER {return $_[0]->_get_column('AMERICAN_EXPRESS_PAYMENT_NUMBER')}
sub PAYMENT_DATE                    {return $_[0]->_get_column('PAYMENT_DATE')}
sub PAYMENT_CURRENCY                {return $_[0]->_get_column('PAYMENT_CURRENCY')}

sub SUBMISSION_MERCHANT_ID          {return $_[0]->_get_column('SUBMISSION_MERCHANT_ID')}
sub MERCHANT_LOCATION_ID            {return $_[0]->_get_column('MERCHANT_LOCATION_ID')}

sub FEE_OR_REVENUE_AMOUNT           {return $_[0]->_get_column('FEE_OR_REVENUE_AMOUNT')}
sub FEE_OR_REVENUE_DESCRIPTION      {return $_[0]->_get_column('FEE_OR_REVENUE_DESCRIPTION')}
sub ASSET_BILLING_AMOUNT            {return $_[0]->_get_column('ASSET_BILLING_AMOUNT')}
sub ASSET_BILLING_DESCRIPTION       {return $_[0]->_get_column('ASSET_BILLING_DESCRIPTION')}
sub ASSET_BILLING_TAX               {return $_[0]->_get_column('ASSET_BILLING_TAX')}
sub PAY_IN_GROSS_INDICATOR          {return $_[0]->_get_column('PAY_IN_GROSS_INDICATOR')}
sub BATCH_CODE                      {return $_[0]->_get_column('BATCH_CODE')}
sub BILL_CODE                       {return $_[0]->_get_column('BILL_CODE')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::GRRCN::FeeRevenue - Parse AMEX Global Reconciliation (GRRCN) Fees and Revenues Record Rows

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'GRRCN');
 open my $fh, '<', '/path to GRRCN file' or die "cannot open GRRCN file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'FEEREVENUE') {
    print $record->PAYMENT_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an GRRCN file');
 if ($record->type eq 'FEEREVENUE') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new L<Finance::AMEX::Transaction::GRRCN::FeeRevenue> object.

 my $record = Finance::AMEX::Transaction::GRRCN::FeeRevenue->new(line => $line);

=head2 type

This will always return the string FEEREVENUE.

 print $record->type; # FEEREVENUE

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 RECORD_TYPE

This field contains the Record identifier, which will always be “FEEREVENUE” for the Fees and Revenues Record.

Note: This record is only applicable to the U.S. and Canada markets.

=head2 PAYEE_MERCHANT_ID

This field contains the American Express-assigned Service Establishment (SE) Number of the Merchant receiving the payment/settlement.

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

=head2 MERCHANT_LOCATION_ID

This field contains the Merchant-assigned SE Unit Number (such as an internal, store identifier code) that corresponds to a specific store or location.

If unused, this field is character space filled (fixed format) or blank (delimited formats).

=head2 FEE_OR_REVENUE_AMOUNT

This field contains the amount of the Fee or Revenue to the payee account.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 FEE_OR_REVENUE_DESCRIPTION

This field contains an explanation of the given fee or revenue amount.

=head2 ASSET_BILLING_AMOUNT

This field contains the total Asset Billing Amount charged to the Merchant for physical assets provided by American Express.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 ASSET_BILLING_DESCRIPTION

This field contains a brief description of the physical assets provided by American Express that correspond to the Asset Billing Amount.

=head2 ASSET_BILLING_TAX

This field contains the tax assessed on the assets that correspond to the Asset Billing Amount.

=head2 PAY_IN_GROSS_INDICATOR

This field contains a code that indicates whether this Fees and Revenues Record contains data associated with the recovery of a Pay In Gross (PIG) discount amount.

Valid values include the following:

=over 4

=item 1 = Yes; this record contains a PIG recovery fee

=item 0 = All other occurrences

=back

=head2 BATCH_CODE

This field contains the three-digit, numeric Batch Code that corresponds to the Fee or Revenue Description, when used in conjunction with Bill Code.

If unused, this field is character space filled (fixed format) or blank (delimited).

=head2 BILL_CODE

This field contains the three-digit, numeric Bill Code that corresponds to the Fee or Revenue Description, when used in conjunction with Batch Code.

If unused, this field is character space filled (fixed format) or blank (delimited).

=head1 NAME

Finance::AMEX::Transaction::GRRCN::FeeRevenue - Object methods for AMEX Global Reconciliation (GRRCN) adjustment records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
