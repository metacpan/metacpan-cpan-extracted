package Finance::AMEX::Transaction::EPPRC::Detail::Other 0.005;

use strict;
use warnings;

# ABSTRACT: Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC) Other Fees and Revenues Detail Rows

use base 'Finance::AMEX::Transaction::EPPRC::Base';

sub field_map {
  return {
    AMEX_PAYEE_NUMBER          => [1,   10],
    AMEX_SE_NUMBER             => [11,  10],
    SE_UNIT_NUMBER             => [21,  10],
    PAYMENT_YEAR               => [31,  4],
    PAYMENT_NUMBER             => [35,  8],
    PAYMENT_NUMBER_DATE        => [35,  3],
    PAYMENT_NUMBER_TYPE        => [38,  1],
    PAYMENT_NUMBER_NUMBER      => [39,  4],
    RECORD_TYPE                => [43,  1],
    DETAIL_RECORD_TYPE         => [44,  2],
    AMEX_PROCESS_DATE          => [46,  7],
    ASSET_BILLING_AMOUNT       => [53,  9],
    ASSET_BILLING_DESCRIPTION  => [62,  65],
    TAKE_ONE_COMMISSION_AMOUNT => [127, 9],
    TAKE_ONE_DESCRIPTION       => [136, 80],
    OTHER_FEE_AMOUNT           => [216, 9],
    OTHER_FEE_DESCRIPTION      => [225, 80],
    ASSET_BILLING_TAX          => [305, 9],
    PAY_IN_GROSS_INDICATOR     => [314, 1],
    BATCH_CODE                 => [315, 3],
    BILL_CODE                  => [318, 3],
    SERVICE_AGENT_MERCHANT_ID  => [321, 15],
  };
}

sub type {return 'OTHER_DETAIL'}

sub AMEX_PAYEE_NUMBER          {return $_[0]->_get_column('AMEX_PAYEE_NUMBER')}
sub AMEX_SE_NUMBER             {return $_[0]->_get_column('AMEX_SE_NUMBER')}
sub SE_UNIT_NUMBER             {return $_[0]->_get_column('SE_UNIT_NUMBER')}
sub PAYMENT_YEAR               {return $_[0]->_get_column('PAYMENT_YEAR')}
sub PAYMENT_NUMBER             {return $_[0]->_get_column('PAYMENT_NUMBER')}
sub PAYMENT_NUMBER_DATE        {return $_[0]->_get_column('PAYMENT_NUMBER_DATE')}
sub PAYMENT_NUMBER_TYPE        {return $_[0]->_get_column('PAYMENT_NUMBER_TYPE')}
sub PAYMENT_NUMBER_NUMBER      {return $_[0]->_get_column('PAYMENT_NUMBER_NUMBER')}
sub RECORD_TYPE                {return $_[0]->_get_column('RECORD_TYPE')}
sub DETAIL_RECORD_TYPE         {return $_[0]->_get_column('DETAIL_RECORD_TYPE')}
sub AMEX_PROCESS_DATE          {return $_[0]->_get_column('AMEX_PROCESS_DATE')}
sub ASSET_BILLING_AMOUNT       {return $_[0]->_get_column('ASSET_BILLING_AMOUNT')}
sub ASSET_BILLING_DESCRIPTION  {return $_[0]->_get_column('ASSET_BILLING_DESCRIPTION')}
sub TAKE_ONE_COMMISSION_AMOUNT {return $_[0]->_get_column('TAKE_ONE_COMMISSION_AMOUNT')}
sub TAKE_ONE_DESCRIPTION       {return $_[0]->_get_column('TAKE_ONE_DESCRIPTION')}
sub OTHER_FEE_AMOUNT           {return $_[0]->_get_column('OTHER_FEE_AMOUNT')}
sub OTHER_FEE_DESCRIPTION      {return $_[0]->_get_column('OTHER_FEE_DESCRIPTION')}
sub ASSET_BILLING_TAX          {return $_[0]->_get_column('ASSET_BILLING_TAX')}
sub PAY_IN_GROSS_INDICATOR     {return $_[0]->_get_column('PAY_IN_GROSS_INDICATOR')}
sub BATCH_CODE                 {return $_[0]->_get_column('BATCH_CODE')}
sub BILL_CODE                  {return $_[0]->_get_column('BILL_CODE')}
sub SERVICE_AGENT_MERCHANT_ID  {return $_[0]->_get_column('SERVICE_AGENT_MERCHANT_ID')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::EPPRC::Detail::Other - Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC) Other Fees and Revenues Detail Rows

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'EPPRC');
 open my $fh, '<', '/path to EPPRC file' or die "cannot open EPPRC file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'OTHER_DETAIL') {
    print $record->AMEX_PROCESS_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an EPPRC  file');
 if ($record->type eq 'OTHER_DETAIL') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new Finance::AMEX::Transaction::EPPRC::Detail::Other object.

 my $record = Finance::AMEX::Transaction::EPPRC::Detail::Other->new(line => $line);

=head2 type

This will always return the string OTHER_DETAIL.

 print $record->type; # OTHER_DETAIL

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

This field contains the Detail Record Type Code that indicates the type of record used in this transaction. For Other Fees and Revenues Detail Records, valid entries include the following:

=over 4

=item 40 = Assets Billing

=item 41 = Take-One Comissions

=item 50 = Other Fees

=back

=head2 AMEX_PROCESS_DATE

This field contains the American Express Transaction Processing Date, which is used to determine the payment date.

The format is: YYYYDDD

=over 4

=item YYYY = Year

=item DDD = Julian Date

=back

=head2 ASSET_BILLING_AMOUNT

This field contains the total Asset Billing Amount charged to the merchant for physical assets provided by American Express.

Note: For US Dollar (USD) and Canadian Dollar (CAD) transactions, two decimal places are implied.

A debit amount (positive) is indicated by an upper-case alpha code used in place of the last digit in the amount. The debit codes and their numeric equivalents are listed below:

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

  Amount    Debit         Credit
   $1.11    0000000011A   0000000011J
 $345.05    0000003450E   0000003450N
  $22.70    0000000227{   0000000227}

=head2 ASSET_BILLING_DESCRIPTION

This field contains a brief description of the physical assets provided by American Express that correspond to the amount in ASSET_BILLING_AMOUNT.

=head2 TAKE_ONE_COMMISSION_AMOUNT

This field contains the Commission Amount paid to the merchant for processing Take-One applications.

=head2 TAKE_ONE_DESCRIPTION

This field contains the Take-One Description, a brief explanation that corresponds to the payment in TAKE_ONE_COMMISSION_AMOUNT.

=head2 OTHER_FEE_AMOUNT

This field contains the Amount of Other Fees charged to the merchant.

=head2 OTHER_FEE_DESCRIPTION

This field contains the Other Fee description, a brief description that corresponds to the amount in OTHER_FEE_AMOUNT.

=head2 ASSET_BILLING_TAX

This field contains the tax assessed on the assets that correspond to ASSET_BILLING_AMOUNT.

=head2 PAY_IN_GROSS_INDICATOR

This field contains a code that indicates whether this Other Fees and Revenues Detail Record transports data associated with the recovery of a Pay-in-Gross (PIG) discount amount.

Valid entries include the following:

=over 4

=item Y = Yes; this record contains a PIG recovery fee.

=item ~ = All other occurrences.

=back

Note: Tilde (~) represents a character space. If unused, this field is character space filled.

=head2 BATCH_CODE

This field contains the three-digit, numeric Batch Code that corresponds to the ASSET_BILLING_DESCRIPTION, TAKE_ONE_DESCRIPTION and/or OTHER_FEE_DESCRIPTION, when used in conjunction with BILL_CODE.

If unused, this field is character space filled.

=head2 BILL_CODE

This field contains the three-digit, numeric Bill Code that corresponds to the ASSET_BILLING_DESCRIPTION, TAKE_ONE_DESCRIPTION and/or OTHER_FEE_DESCRIPTION, when used in conjunction with BATCH_CODE.

If unused, this field is character space filled.

=head2 SERVICE_AGENT_MERCHANT_ID

This field contains the external, third party Service Agent Merchant ID number when applicable. Otherwise this field will be space filled.

=head1 NAME

Finance::AMEX::Transaction::EPPRC::Detail::Other - Object methods for AMEX Reconciliation file chargeback detail records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by ZipRecruiter/Tom Heady.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
