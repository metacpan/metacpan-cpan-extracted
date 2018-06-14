package Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummaryPricing;
$Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummaryPricing::VERSION = '0.002';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC) Summary of Charge (SOC) Level Pricing Rows

use base 'Finance::AMEX::Transaction::EPPRC::Base';

sub field_map {
  return {

    AMEX_PAYEE_NUMBER     => [1, 10],
    AMEX_SE_NUMBER        => [11, 10],
    SE_UNIT_NUMBER        => [21, 10],
    PAYMENT_YEAR          => [31, 4],
    PAYMENT_NUMBER        => [35, 8],
    PAYMENT_NUMBER_DATE   => [35, 3],
    PAYMENT_NUMBER_TYPE   => [38, 1],
    PAYMENT_NUMBER_NUMBER => [39, 4],
    RECORD_TYPE           => [43, 1],
    DETAIL_RECORD_TYPE    => [44, 2],

    FEE_CODE              => [46, 2],
    FEE_DESCRIPTION       => [45, 25],
    DISCOUNT_RATE         => [73, 9],
    DISCOUNT_AMOUNT       => [82, 15],
    FEE_RATE              => [97, 9],
    FEE_AMOUNT            => [106, 15],
    MERCHANT_ID           => [121, 15],
  };
}

sub type {return 'SOC_PRICING'}

sub AMEX_PAYEE_NUMBER     {return $_[0]->_get_column('AMEX_PAYEE_NUMBER')}
sub AMEX_SE_NUMBER        {return $_[0]->_get_column('AMEX_SE_NUMBER')}
sub SE_UNIT_NUMBER        {return $_[0]->_get_column('SE_UNIT_NUMBER')}
sub PAYMENT_YEAR          {return $_[0]->_get_column('PAYMENT_YEAR')}
sub PAYMENT_NUMBER        {return $_[0]->_get_column('PAYMENT_NUMBER')}
sub PAYMENT_NUMBER_DATE   {return $_[0]->_get_column('PAYMENT_NUMBER_DATE')}
sub PAYMENT_NUMBER_TYPE   {return $_[0]->_get_column('PAYMENT_NUMBER_TYPE')}
sub PAYMENT_NUMBER_NUMBER {return $_[0]->_get_column('PAYMENT_NUMBER_NUMBER')}
sub RECORD_TYPE           {return $_[0]->_get_column('RECORD_TYPE')}
sub DETAIL_RECORD_TYPE    {return $_[0]->_get_column('DETAIL_RECORD_TYPE')}
sub FEE_CODE              {return $_[0]->_get_column('FEE_CODE')}
sub FEE_DESCRIPTION       {return $_[0]->_get_column('FEE_DESCRIPTION')}
sub DISCOUNT_RATE         {return $_[0]->_get_column('DISCOUNT_RATE')}
sub DISCOUNT_AMOUNT       {return $_[0]->_get_column('DISCOUNT_AMOUNT')}
sub FEE_RATE              {return $_[0]->_get_column('FEE_RATE')}
sub FEE_AMOUNT            {return $_[0]->_get_column('FEE_AMOUNT')}
sub MERCHANT_ID           {return $_[0]->_get_column('MERCHANT_ID')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummaryPricing - Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC) Summary of Charge (SOC) Level Pricing Rows

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'EPPRC');
 open my $fh, '<', '/path to EPPRC file' or die "cannot open EPPRC file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'SOC_PRICING') {
    print $record->AMEX_PROCESS_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an EPPRC  file');
 if ($record->type eq 'SOC_PRICING') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummaryPricing object.

 my $record = Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummaryPricing->new(line => $line);

=head2 type

This will always return the string SOC_PRICING.

 print $record->type; # SOC_PRICING

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

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

This field contains the constant literal “2”, a Record Type code that indicates that this is a Summary of Charge (SOC) Detail Record.

=head2 DETAIL_RECORD_TYPE

This field contains the Detail Record Type code that indicates the type of record used in this transaction. For Summary of Charge (SOC) Level Pricing Records, this entry is always “12”

=head2 FEE_CODE

This field contains a Fee Code that corresponds to preceding SOC Detail Record. For valid SOC Level Pricing Record Fee
Codes, see below:

 Sr. No.   Fee Code    Fee Description
 61        EP          Expresspay Service Fee
 62        EF          ACH Service Fee
 63        PG          PIG Service Fee

=head2 FEE_DESCRIPTION

This field contains the Fee Description that corresponds to the amount in FEE_CODE.

=head2 DISCOUNT_RATE

This field contains the Discount Rate (decimal place value) used to calculate the amount American Express charged a merchant for the services that correspond to the preceding SOC Detail Record.

Note: This field is not used when this record transports data for Automated Clearing House (ACH), Expresspay or Pay in Gross (PIG) fees.

This value may be a debit or credit rate. The format is a 1-digit “sign”, followed by an 8-digit “rate”.

For a debit (a negative rate), the first position is a minus sign; and a “negative .003 (.3%)” would appear as:

 0
 123456789
 -00000300

For a credit (a positive rate), the first position is a plus sign; and a “positive .003 (.3%)” would appear as:

 0
 123456789
 +00000300

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 DISCOUNT_AMOUNT

This field contains the Discount Amount that American Express charged a merchant for the services that correspond to the preceding SOC Detail Record.

Note: This field is not used when this record transports data for Automated Clearing House (ACH), Expresspay or Pay in Gross (PIG) fees.

This value may be a debit or credit amount; and the format is a 1-digit “sign”, followed by a 14-digit “dollar amount”.

For a debit (a negative amount), the first position is a minus sign; and a “negative $1005.05” would appear as:

 0        1
 123456789012345
 -00000000100505

For a credit (a positive amount), the first position is a plus sign; and a “positive $1005.05” would appear as:

 0        1
 123456789012345
 +00000000100505

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 FEE_RATE

This field contains the Fee Rate (decimal place value) used to calculate the amount American Express charged a merchant for a fee (described in the FEE_CODE and FEE_ DESCRIPTION fields in this record) that corresponds to the preceding SOC Detail Record. For more information, see FEE_CODE and FEE_ DESCRIPTION.

This value may be a debit or credit rate. The format is a 1-digit “sign”, followed by an 8-digit “rate”.

See examples of negative and positive entries under DISCOUNT_RATE.

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 FEE_AMOUNT

This field contains the Fee Amount American Express charged a merchant for a fee (described in the FEE_CODE and FEE_DESCRIPTION fields in this record) that corresponds to the preceding SOC Detail Record. For more information, see FEE_CODE and FEE_DESCRIPTION.

This value may be a debit or credit amount. The format is a 1-digit “sign”, followed by a 14-digit “amount”.

See examples of negative and positive entries under DISCOUNT_AMOUNT.

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 MERCHANT_ID

This field contains the external, third party Service Agent Merchant ID number when applicable. Otherwise this field will be space filled.

=head1 NAME

Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummaryPricing - Object methods for AMEX Reconciliation file summary of charge level pricing records.

=head1 AUTHOR

Tom Heady <theady@ziprecruiter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
