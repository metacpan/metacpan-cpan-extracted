package Finance::AMEX::Transaction::EPTRN::Detail::Chargeback 0.005;

use strict;
use warnings;

# ABSTRACT: Parse AMEX Reconciliation Files (EPTRN) Chargeback Detail Rows

use base 'Finance::AMEX::Transaction::EPTRN::Base';

sub field_map {
  return {

    AMEX_PAYEE_NUMBER     => [1,   10],
    AMEX_SE_NUMBER        => [11,  10],
    SE_UNIT_NUMBER        => [21,  10],
    PAYMENT_YEAR          => [31,  4],
    PAYMENT_NUMBER        => [35,  8],
    PAYMENT_NUMBER_DATE   => [35,  3],
    PAYMENT_NUMBER_TYPE   => [38,  1],
    PAYMENT_NUMBER_NUMBER => [39,  4],
    RECORD_TYPE           => [43,  1],
    DETAIL_RECORD_TYPE    => [44,  2],
    SE_BUSINESS_DATE      => [46,  7],
    AMEX_PROCESS_DATE     => [53,  7],
    SOC_INVOICE_NUMBER    => [60,  6],
    SOC_AMOUNT            => [66,  11],
    CHARGEBACK_AMOUNT     => [77,  9],
    DISCOUNT_AMOUNT       => [86,  9],
    SERVICE_FEE_AMOUNT    => [95,  7],
    NET_CHARGEBACK_AMOUNT => [109, 9],
    DISCOUNT_RATE         => [118, 5],
    SERVICE_FEE_RATE      => [123, 5],
    CHARGEBACK_REASON     => [144, 280],
  };
}

sub type {return 'CHARGEBACK_DETAIL'}

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
sub SE_BUSINESS_DATE      {return $_[0]->_get_column('SE_BUSINESS_DATE')}
sub AMEX_PROCESS_DATE     {return $_[0]->_get_column('AMEX_PROCESS_DATE')}
sub SOC_INVOICE_NUMBER    {return $_[0]->_get_column('SOC_INVOICE_NUMBER')}
sub SOC_AMOUNT            {return $_[0]->_get_column('SOC_AMOUNT')}
sub CHARGEBACK_AMOUNT     {return $_[0]->_get_column('CHARGEBACK_AMOUNT')}
sub DISCOUNT_AMOUNT       {return $_[0]->_get_column('DISCOUNT_AMOUNT')}
sub SERVICE_FEE_AMOUNT    {return $_[0]->_get_column('SERVICE_FEE_AMOUNT')}
sub NET_CHARGEBACK_AMOUNT {return $_[0]->_get_column('NET_CHARGEBACK_AMOUNT')}
sub DISCOUNT_RATE         {return $_[0]->_get_column('DISCOUNT_RATE')}
sub SERVICE_FEE_RATE      {return $_[0]->_get_column('SERVICE_FEE_RATE')}
sub CHARGEBACK_REASON     {return $_[0]->_get_column('CHARGEBACK_REASON')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::EPTRN::Detail::Chargeback - Parse AMEX Reconciliation Files (EPTRN) Chargeback Detail Rows

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'EPTRN');
 open my $fh, '<', '/path to EPTRN file' or die "cannot open EPTRN file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'CHARGEBACK_DETAIL') {
    print $record->AMEX_PROCESS_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an EPTRN  file');
 if ($record->type eq 'CHARGEBACK_DETAIL') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new F<Finance::AMEX::Transaction::EPTRN::Detail::Chargeback> object.

 my $record = Finance::AMEX::Transaction::EPTRN::Detail::Chargeback->new(line => $line);

=head2 type

This will always return the string CHARGEBACK_DETAIL.

 print $record->type; # CHARGEBACK_DETAIL

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

This field contains the Detail Record Type code that indicates the type of record used in this transaction. For Chargeback Detail Records, this entry is always “20”.

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

=head2 CHARGEBACK_AMOUNT

This field contains the Chargeback Amount, which is the gross amount charged back to the merchant against the original SOC_INVOICE_NUMBER and SOC_AMOUNT.

=head2 DISCOUNT_AMOUNT

This field contains the total Discount Amount, based on CHARGEBACK_AMOUNT, and DISCOUNT_RATE.

=head2 SERVICE_FEE_AMOUNT

This field contains the total Service Fee Amount, based on CHARGEBACK_AMOUNT, and SERVICE_FEE_RATE.

=head2 NET_CHARGEBACK_AMOUNT

This field contains the Net Amount of the Chargeback, which is the sum total of CHARGEBACK_AMOUNT, less DISCOUNT_AMOUNT and SERVICE_FEE_AMOUNT.

=head2 DISCOUNT_RATE

This field contains the Discount Rate (decimal place value) used to calculate the amount American Express charges a merchant for services provided per the American Express Card Acceptance Agreement.

=head2 SERVICE_FEE_RATE

This field contains the Service Fee Rate (decimal place value) used to calculate the amount American Express charges a merchant as service fees.

Service fees are assessed only in certain situations and may not apply to all SEs.

=head2 CHARGEBACK_REASON

This field contains the Chargeback Reason, which is the reason the Merchant is assessed the amount that appears in CHARGEBACK_AMOUNT.

A list of reason descriptions can be found below.

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

If unused, this field is character space filled.

=head1 NAME

Finance::AMEX::Transaction::EPTRN::Detail::Chargeback - Object methods for AMEX Reconciliation file chargeback detail records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by ZipRecruiter/Tom Heady.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
