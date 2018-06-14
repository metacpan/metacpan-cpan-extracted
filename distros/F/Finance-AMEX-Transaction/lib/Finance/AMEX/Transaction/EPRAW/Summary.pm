package Finance::AMEX::Transaction::EPRAW::Summary;
$Finance::AMEX::Transaction::EPRAW::Summary::VERSION = '0.002';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Reconciliation Files (EPRAW) Summary Rows

use base 'Finance::AMEX::Transaction::EPRAW::Base';

sub field_map {
  return {
    AMEX_PAYEE_NUMBER     => [1, 10],
    AMEX_SORT_FIELD_1     => [11, 10],
    AMEX_SORT_FIELD_2     => [21, 10],
    PAYMENT_YEAR          => [31, 4],
    PAYMENT_NUMBER        => [35, 8],

    PAYMENT_NUMBER_DATE   => [35, 3],
    PAYMENT_NUMBER_TYPE   => [38, 1],
    PAYMENT_NUMBER_NUMBER => [39, 4],

    RECORD_TYPE           => [43, 1],
    DETAIL_RECORD_TYPE    => [44, 2],
    PAYMENT_DATE          => [46, 7],
    PAYMENT_AMOUNT        => [53, 11],
    DEBIT_BALANCE_AMOUNT  => [64, 9],
    ABA_BANK_NUMBER       => [73, 9],
    SE_DDA_NUMBER         => [82, 17],
  };
}

sub type {return 'SUMMARY'}

sub AMEX_PAYEE_NUMBER     {return $_[0]->_get_column('AMEX_PAYEE_NUMBER')}
sub AMEX_SORT_FIELD_1     {return $_[0]->_get_column('AMEX_SORT_FIELD_1')}
sub AMEX_SORT_FIELD_2     {return $_[0]->_get_column('AMEX_SORT_FIELD_2')}
sub PAYMENT_YEAR          {return $_[0]->_get_column('PAYMENT_YEAR')}
sub PAYMENT_NUMBER        {return $_[0]->_get_column('PAYMENT_NUMBER')}

sub PAYMENT_NUMBER_DATE   {return $_[0]->_get_column('PAYMENT_NUMBER_DATE')}
sub PAYMENT_NUMBER_TYPE   {return $_[0]->_get_column('PAYMENT_NUMBER_TYPE')}
sub PAYMENT_NUMBER_NUMBER {return $_[0]->_get_column('PAYMENT_NUMBER_NUMBER')}

sub RECORD_TYPE           {return $_[0]->_get_column('RECORD_TYPE')}
sub DETAIL_RECORD_TYPE    {return $_[0]->_get_column('DETAIL_RECORD_TYPE')}
sub PAYMENT_DATE          {return $_[0]->_get_column('PAYMENT_DATE')}
sub PAYMENT_AMOUNT        {return $_[0]->_get_column('PAYMENT_AMOUNT')}
sub DEBIT_BALANCE_AMOUNT  {return $_[0]->_get_column('DEBIT_BALANCE_AMOUNT')}
sub ABA_BANK_NUMBER       {return $_[0]->_get_column('ABA_BANK_NUMBER')}
sub SE_DDA_NUMBER         {return $_[0]->_get_column('SE_DDA_NUMBER')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::EPRAW::Summary - Parse AMEX Reconciliation Files (EPRAW) Summary Rows

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'EPRAW');
 open my $fh, '<', '/path to EPRAW file' or die "cannot open EPRAW file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'SUMMARY') {
    print $record->PAYMENT_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an EPRAW  file');
 if ($record->type eq 'SUMMARY') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new L<Finance::AMEX::Transaction::EPRAW::Summary> object.

 my $record = Finance::AMEX::Transaction::EPRAW::Summary->new(line => $line);

=head2 type

This will always return the string SUMMARY.

 print $record->type; # SUMMARY

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 AMEX_PAYEE_NUMBER

This field contains the Service Establishment (SE) Number of the merchant that received the payment from American Express.

Note: SE Numbers are assigned by American Express.

=head2 AMEX_SORT_FIELD_1

This field is always zero filled in the Summary Record.

=head2 AMEX_SORT_FIELD_2

This field is always zero filled in the Summary Record.

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

This field contains the constant literal “1”, a Record Type code that indicates that this is a Summary Record.

=head2 DETAIL_RECORD_TYPE

This field contains the Detail Record Type code that indicates the type of record used in this transaction.

For Summary Records, this entry is always “00” (zeros).

=head2 PAYMENT_DATE

This field contains the Payment Date, which is the date the funds are actually available to the payee’s depository institution.

The format is: YYYYDDD

=over 4

=item YYYY = Year

=item DDD = Julian Date

=back

=head2 PAYMENT_AMOUNT

This field contains the actual Payment Amount paid to the payee for the activities listed in the Detail Records.

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

 Amount    Debit          Credit
   $1.11   0000000011A    0000000227}
 $345.05   0000003450E    0000003450N
  $22.70   0000000227{    0000000011J

=head2 DEBIT_BALANCE_AMOUNT

This field contains the Debit Balance Amount, which is a negative value if the merchant has an opening debit balance
for the payment listed in PAYMENT_AMOUNT.

=head2 ABA_BANK_NUMBER

This field contains the ABA Bank Number to which the value in PAYMENT_AMOUNT, was transferred through the ACH banking system.

=head2 SE_DDA_NUMBER

This field contains the payee’s Direct Deposit Account Number to which the value in PAYMENT_AMOUNT, was transferred through the ACH banking system.

=head1 NAME

Finance::AMEX::Transaction::EPRAW::Summary - Object methods for AMEX Reconciliation file summary records.

=head1 AUTHOR

Tom Heady <theady@ziprecruiter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
