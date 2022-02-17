package Finance::AMEX::Transaction::GRRCN::TaxRecord 0.005;

use strict;
use warnings;

# ABSTRACT: Parse AMEX Global Reconciliation (GRRCN) TaxRecord Rows

use base 'Finance::AMEX::Transaction::GRRCN::Base';

sub field_map {
  return [
    {RECORD_TYPE                     => [1,   10]},
    {PAYEE_MERCHANT_ID               => [11,  15]},
    {SETTLEMENT_ACCOUNT_TYPE_CODE    => [26,  3]},
    {AMERICAN_EXPRESS_PAYMENT_NUMBER => [29,  10]},
    {PAYMENT_DATE                    => [39,  8]},
    {PAYMENT_CURRENCY                => [47,  3]},
    {TAX_TYPE_CODE                   => [50,  2]},
    {TAX_DESCRIPTION                 => [52,  64]},
    {TAX_BASE_AMOUNT                 => [116, 24]},
    {TAX_PRESENT_DATE                => [140, 8]},
    {TAX_RATE                        => [148, 20]},
    {TAX_AMOUNT                      => [168, 24]},
    {FILLER1                         => [192, 609]},
  ];
}

sub type {return 'TAXRECORD'}

sub RECORD_TYPE                     {return $_[0]->_get_column('RECORD_TYPE')}
sub PAYEE_MERCHANT_ID               {return $_[0]->_get_column('PAYEE_MERCHANT_ID')}
sub SETTLEMENT_ACCOUNT_TYPE_CODE    {return $_[0]->_get_column('SETTLEMENT_ACCOUNT_TYPE_CODE')}
sub AMERICAN_EXPRESS_PAYMENT_NUMBER {return $_[0]->_get_column('AMERICAN_EXPRESS_PAYMENT_NUMBER')}
sub PAYMENT_DATE                    {return $_[0]->_get_column('PAYMENT_DATE')}
sub PAYMENT_CURRENCY                {return $_[0]->_get_column('PAYMENT_CURRENCY')}
sub TAX_TYPE_CODE                   {return $_[0]->_get_column('TAX_TYPE_CODE')}
sub TAX_DESCRIPTION                 {return $_[0]->_get_column('TAX_DESCRIPTION')}
sub TAX_BASE_AMOUNT                 {return $_[0]->_get_column('TAX_BASE_AMOUNT')}
sub TAX_PRESENT_DATE                {return $_[0]->_get_column('TAX_PRESENT_DATE')}
sub TAX_RATE                        {return $_[0]->_get_column('TAX_RATE')}
sub TAX_AMOUNT                      {return $_[0]->_get_column('TAX_AMOUNT')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::GRRCN::TaxRecord - Parse AMEX Global Reconciliation (GRRCN) TaxRecord Rows

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

Returns a new L<Finance::AMEX::Transaction::GRRCN::TaxRecord> object.

 my $record = Finance::AMEX::Transaction::GRRCN::TaxRecord->new(line => $line);

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

This field contains the Record identifier, which will always be “TAXRECORD” for the Tax Record(s).

Note: This record is only applicable to the Argentina market.

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

=head2 TAX_TYPE_CODE

This field contains a numerical value between 01 and 99 according to the description of tax.

=head2 TAX_DESCRIPTION

This field contains a description of the tax applied, which corresponds to the Tax Type Code field.

Note: there may be multiple descriptions for a single tax code.

=head2 TAX_BASE_AMOUNT

This field contains the amount on which tax is applied.

The format of the Tax Base Amount field value is: leading sign (1), whole numbers (13) and decimal places (10).

=head2 TAX_PRESENT_DATE

This field contains the date when American Express pays the tax to the tax collector.

The format is: YYYYMMDD

=head2 TAX_RATE

This field contains the Tax Rate Percentage, which corresponds to the calculation of the tax Amount.

This field is expressed as an actual percentage. The format of the Tax Rate field value is: leading sign (1), whole numbers (13)
and decimal places (6). Right aligned with leading zeros.

For example:
 Rate            Displayed in File
 +21%            ~0000000000021000000
 +21.123446%     ~0000000000021123446
  -5.05%         -0000000000005050000

=head2 TAX_AMOUNT

This field contains the amount of the tax.

The Tax Amount is calculated as follows;

Tax Base Amount * Tax Rate = Tax Amount.

“Tax Rate” used in above calculation is a decimal value (i.e., Tax Base Amount = 1000, Tax Rate = 20%, Tax Amount = 200; 1000 * 0.2 = 200).

The format of the Tax Amount field value is: leading sign (1), whole numbers (13) and decimal places (10).

=head1 NAME

Finance::AMEX::Transaction::GRRCN::TaxRecord - Object methods for AMEX Global Reconciliation (GRRCN) Tax records.

Note: This record is only applicable for Argentina.

=for: list
= YYYY = Year
=   MM = Month
=   DD = Day

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by ZipRecruiter/Tom Heady.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
