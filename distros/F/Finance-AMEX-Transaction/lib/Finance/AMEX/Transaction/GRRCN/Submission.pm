package Finance::AMEX::Transaction::GRRCN::Submission;
$Finance::AMEX::Transaction::GRRCN::Submission::VERSION = '0.002';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Global Reconciliation (GRRCN) Submission or summary of charge (SOC) Rows

use base 'Finance::AMEX::Transaction::GRRCN::Base';

sub field_map {
  return {
    RECORD_TYPE                                    => [1, 10],
    PAYEE_MERCHANT_ID                              => [11, 15],
    SETTLEMENT_ACCOUNT_TYPE_CODE                   => [26, 3],
    AMERICAN_EXPRESS_PAYMENT_NUMBER                => [29, 10],
    PAYMENT_DATE                                   => [39, 8],
    PAYMENT_CURRENCY                               => [47, 3],

    SUBMISSION_MERCHANT_ID                         => [50, 15],
    BUSINESS_SUBMISSION_DATE                       => [65, 8],
    AMERICAN_EXPRESS_PROCESSING_DATE               => [73, 18],
    SUBMISSION_INVOICE_NUMBER                      => [81, 15],
    SUBMISSION_CURRENCY                            => [96, 3],
    SUBMISSION_EXCHANGE_RATE                       => [114, 15],
    SUBMISSION_GROSS_AMOUNT_IN_SUBMISSION_CURRENCY => [129, 15],
    SUBMISSION_GROSS_AMOUNT_IN_PAYMENT_CURRENCY    => [145, 16],
    SUBMISSION_DISCOUNT_AMOUNT                     => [161, 16],
    SUBMISSION_SERVICE_FEE_AMOUNT                  => [177, 16],
    SUBMISSION_TAX_AMOUNT                          => [193, 16],
    SUBMISSION_NET_AMOUNT                          => [209, 16],
    SUBMISSION_DISCOUNT_RATE                       => [225, 7],
    SUBMISSION_TAX_RATE                            => [232, 7],
    TRANSACTION_COUNT                              => [239, 7],
    TRACKING_ID                                    => [246, 11],
    INSTALLMENT_NUMBER                             => [257, 5],
    ACCELERATION_NUMBER                            => [262, 9],
    ORIGINAL_SETTLEMENT_DATE                       => [271, 8],
    ACCELERATION_DATE                              => [279, 8],
    NUMBER_OF_DAYS_IN_ADVANCE                      => [287, 5],
    SUBMISSION_ACCELERATION_FEE_AMOUNT             => [292, 16],
    SUBMISSION_ACCELERATION_FEE_NET_AMOUNT         => [308, 16],
    SUBMISSION_DEBIT_GROSS_AMOUNT                  => [324, 16],
    SUBMISSION_CREDIT_GROSS_AMOUNT                 => [340, 16],
  };
}

sub type {return 'SUBMISSION'}

sub RECORD_TYPE                                    {return $_[0]->_get_column('RECORD_TYPE')}
sub PAYEE_MERCHANT_ID                              {return $_[0]->_get_column('PAYEE_MERCHANT_ID')}
sub SETTLEMENT_ACCOUNT_TYPE_CODE                   {return $_[0]->_get_column('SETTLEMENT_ACCOUNT_TYPE_CODE')}
sub AMERICAN_EXPRESS_PAYMENT_NUMBER                {return $_[0]->_get_column('AMERICAN_EXPRESS_PAYMENT_NUMBER')}
sub PAYMENT_DATE                                   {return $_[0]->_get_column('PAYMENT_DATE')}

sub PAYMENT_CURRENCY                               {return $_[0]->_get_column('PAYMENT_CURRENCY')}
sub SUBMISSION_MERCHANT_ID                         {return $_[0]->_get_column('SUBMISSION_MERCHANT_ID')}
sub BUSINESS_SUBMISSION_DATE                       {return $_[0]->_get_column('BUSINESS_SUBMISSION_DATE')}
sub AMERICAN_EXPRESS_PROCESSING_DATE               {return $_[0]->_get_column('AMERICAN_EXPRESS_PROCESSING_DATE')}
sub SUBMISSION_INVOICE_NUMBER                      {return $_[0]->_get_column('SUBMISSION_INVOICE_NUMBER')}
sub SUBMISSION_CURRENCY                            {return $_[0]->_get_column('SUBMISSION_CURRENCY')}
sub SUBMISSION_EXCHANGE_RATE                       {return $_[0]->_get_column('SUBMISSION_EXCHANGE_RATE')}
sub SUBMISSION_GROSS_AMOUNT_IN_SUBMISSION_CURRENCY {return $_[0]->_get_column('SUBMISSION_GROSS_AMOUNT_IN_SUBMISSION_CURRENCY')}
sub SUBMISSION_GROSS_AMOUNT_IN_PAYMENT_CURRENCY    {return $_[0]->_get_column('SUBMISSION_GROSS_AMOUNT_IN_PAYMENT_CURRENCY')}
sub SUBMISSION_DISCOUNT_AMOUNT                     {return $_[0]->_get_column('SUBMISSION_DISCOUNT_AMOUNT')}
sub SUBMISSION_SERVICE_FEE_AMOUNT                  {return $_[0]->_get_column('SUBMISSION_SERVICE_FEE_AMOUNT')}
sub SUBMISSION_TAX_AMOUNT                          {return $_[0]->_get_column('SUBMISSION_TAX_AMOUNT')}
sub SUBMISSION_NET_AMOUNT                          {return $_[0]->_get_column('SUBMISSION_NET_AMOUNT')}
sub SUBMISSION_DISCOUNT_RATE                       {return $_[0]->_get_column('SUBMISSION_DISCOUNT_RATE')}
sub SUBMISSION_TAX_RATE                            {return $_[0]->_get_column('SUBMISSION_TAX_RATE')}
sub TRANSACTION_COUNT                              {return $_[0]->_get_column('TRANSACTION_COUNT')}
sub TRACKING_ID                                    {return $_[0]->_get_column('TRACKING_ID')}
sub INSTALLMENT_NUMBER                             {return $_[0]->_get_column('INSTALLMENT_NUMBER')}
sub ACCELERATION_NUMBER                            {return $_[0]->_get_column('ACCELERATION_NUMBER')}
sub ORIGINAL_SETTLEMENT_DATE                       {return $_[0]->_get_column('ORIGINAL_SETTLEMENT_DATE')}
sub ACCELERATION_DATE                              {return $_[0]->_get_column('ACCELERATION_DATE')}
sub NUMBER_OF_DAYS_IN_ADVANCE                      {return $_[0]->_get_column('NUMBER_OF_DAYS_IN_ADVANCE')}
sub SUBMISSION_ACCELERATION_FEE_AMOUNT             {return $_[0]->_get_column('SUBMISSION_ACCELERATION_FEE_AMOUNT')}
sub SUBMISSION_ACCELERATION_FEE_NET_AMOUNT         {return $_[0]->_get_column('SUBMISSION_ACCELERATION_FEE_NET_AMOUNT')}
sub SUBMISSION_DEBIT_GROSS_AMOUNT                  {return $_[0]->_get_column('SUBMISSION_DEBIT_GROSS_AMOUNT')}
sub SUBMISSION_CREDIT_GROSS_AMOUNT                 {return $_[0]->_get_column('SUBMISSION_CREDIT_GROSS_AMOUNT')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::GRRCN::Submission - Parse AMEX Global Reconciliation (GRRCN) Submission or summary of charge (SOC) Rows

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'GRRCN');
 open my $fh, '<', '/path to GRRCN file' or die "cannot open GRRCN file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'SUBMISSION') {
    print $record->PAYMENT_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an GRRCN  file');
 if ($record->type eq 'SUBMISSION') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new L<Finance::AMEX::Transaction::GRRCN::Submission> object.

 my $record = Finance::AMEX::Transaction::GRRCN::Submission->new(line => $line);

=head2 type

This will always return the string SUBMISSION.

 print $record->type; # SUBMISSION

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 RECORD_TYPE

This field contains the Record identifier, which will always be “SUBMISSION” for the Submission Record.

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

=head2 BUSINESS_SUBMISSION_DATE

The field contains the date assigned by the Merchant or Partner to this submission.

The format is: YYYYMMDD

=over 4

=item YYYY = Year

=item MM = Month

=item DD = Day

=back

=head2 AMERICAN_EXPRESS_PROCESSING_DATE

This field contains the American Express Transaction Processing Date, which is used to determine the payment date scheduled in the American Express Systems.

The format is: YYYYMMDD

=over 4

=item YYYY = Year

=item MM = Month

=item DD = Day

=back

=head2 SUBMISSION_INVOICE_NUMBER

This field contains the Submission Invoice number.

This field may not always be populated if no Submission Invoice Number is assigned.

=head2 SUBMISSION_CURRENCY

This field contains the Submission Currency Code in Alpha ISO format. Refer to the Global Codes & Information Guide.

=head2 SUBMISSION_EXCHANGE_RATE

This field is reserved for future use and will be set to spaces (fixed format) or blank (delimited formats).

In the future this field will include the exchange rate used to convert the submission currency into the settlement currency for payment.

Where the payment currency and submission currency are the same, this field will be space filled (fixed format) or blank (delimited formats). Right justified, leading zeros.

=head2 SUBMISSION_GROSS_AMOUNT_IN_SUBMISSION_CURRENCY

This field contains the Gross Amount of American Express charges submitted in the original submission, expressed in the submission currency.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 SUBMISSION_GROSS_AMOUNT_IN_PAYMENT_CURRENCY

This field contains the Gross Amount of American Express charges submitted in the original submission, expressed in the Payment (Settlement) currency.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 SUBMISSION_DISCOUNT_AMOUNT

This field contains the total Discount Amount, expressed in the Payment (Settlement) currency.

This field will contain the positive for a typical debit submission which results in American Express making a credit to the Merchant's account, negative if a credit submission.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

For U.S. and Canada Merchants using Gross Pay, this field is for information purposes only. Aggregated Discount and Service Fees to be debited will be recorded in the Fees & Revenues Record on the date of debit from the Merchant's account.

=head2 SUBMISSION_SERVICE_FEE_AMOUNT

This field contains the total Service Fee Amount for the whole Submission, expressed in the Payment (Settlement) currency.

This field is signed positive for a typical debit submission which results in American Express making a credit to the Merchant's account, negative if a credit submission.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

For U.S. and Canada Merchants using Gross Pay, this field is for information purposes only. Aggregated Discount and Service Fees to be debited will be recorded in the Fees & Revenues Record on the date of debit from the Merchant's account.

=head2 SUBMISSION_TAX_AMOUNT

This field contains the total Tax Amount for the submission, expressed in the Payment (Settlement) currency, which is only applicable to the following specific markets

 LAC            Mexico / Bahamas / Panama / Argentina
 JAPA           Australia / India / Japan
 EMEA           Germany / Austria
 Multi-Currency Mexico / Australia

This field is signed positive for a typical debit submission which results in American Express making a credit to the Merchant's account, negative if a credit submission.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 SUBMISSION_NET_AMOUNT

This field contains the Net SOC (Summary of Charge) amount for payment, expressed in the Payment (Settlement) currency, which is the sum total of Submission Gross Amount less Submission Discount Amount, Submission Service Fee and Submission Tax Amount.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 SUBMISSION_DISCOUNT_RATE

This field contains the following:

=over 4

=item U.S. and Canada — Contains the contract discount rate. Detailed fees and discount amounts can be found in transaction level pricing record records.

=item Other countries — This field will be blank (delimited format) or spaces (fixed format). Detailed fees and discount amounts can be found in transaction level pricing records.

=back

Note: where used, the submission discount rate is always signed positive.

Formatting of rate fields is as follows:

 A (1) N (6)

The format is a signed, numeric field with five decimal places implied. Detailed layout is below.

SWDDDDD

=over 4

=item S = the sign indicating whether the rate is positive or negative. A minus ('-) means a negative value and a space (indicated using '~' below)

=item W = whole number position

=item DDDDD = decimal percentages

=back

For example:

 Rate         Decimal Value     Displayed in File
 +99.999%     +0.99999          ~099999
 +03.300%     +0.03300          ~003300
 +00.001%     +0.00001          ~000001
 -00.001%     -0.00001          -000001
 -03.300%     -0.03300          -003300
 -99.999%     -0.99999          -099999

~ = space

=head2 SUBMISSION_TAX_RATE

This field is reserved for future use and will be set to spaces (fixed format) or blank (delimited formats).

For amount of any tax applied, SUBMISSION_TAX_AMOUNT.

=head2 TRANSACTION_COUNT

This field contains a count of the number of accepted transactions / ROCS (Record of Charge) in the submission / SOC (Summary of Charge).

=head2 TRACKING_ID

This field contains a Tracking ID, which holds an American Express-generated SOC processing ID.

This field is only applicable to U.S. and Canada. For other markets this will be set to spaces (fixed format) or blank (delimited formats).

=head2 INSTALLMENT_NUMBER

This field contains the number of monthly payments.

This field is only relevant for deposits made under the Monthly Installments Plan without interest.

This field is only applicable to certain local market Merchants from Mexico / Argentina.

=head2 ACCELERATION_NUMBER

This field contains the Acceleration Number for this SOC Deposit.

This field may be zero (0) if acceleration is consolidated at transaction level.

This field is only applicable to certain local market Merchants from Mexico / Argentina.

=head2 ORIGINAL_SETTLEMENT_DATE

This field contains the Original Settlement Date.

This field is only applicable to certain local market Merchants from Mexico / Argentina.

=head2 ACCELERATION_DATE

This field contains the Deposit Acceleration Date.

This field may be zero (0) if there is no acceleration date / acceleration is consolidated at transaction level.

This field is only applicable to certain local market Merchants from Mexico / Argentina.

=head2 NUMBER_OF_DAYS_IN_ADVANCE

This field contains the Number of Days the payment is accelerated.

This field may be zero (0) if acceleration is consolidated at transaction level.

This field is only applicable to certain local market Merchants from Mexico / Argentina.

=head2 SUBMISSION_ACCELERATION_FEE_AMOUNT

This field contains the Acceleration Amount.

This field may be zero (0) if acceleration is consolidated at transaction level.

This field can be calculated using, ACCELERATION_AMOUNT in the Transaction Record (i.e., If you sum up Transaction Record Field #ACCELERATION_AMOUNT for all ROC's within a SOC, you will have the Submission Acceleration Fee Amount).

This field is only applicable to certain local market Merchants from Mexico / Argentina.

=head2 SUBMISSION_ACCELERATION_FEE_NET_AMOUNT

This field contains the Acceleration Net Amount. This field may be zero (0) if acceleration is consolidated at transaction level.

This field can be calculated by; SUBMISSION_NET_AMOUNT (Submission Record) + SUBMISSION_ACCELERATION_FEE_AMOUNT (Submission Record).

This field is only applicable to certain local market Merchants from Mexico / Argentina.

The last two digits are decimals. For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 SUBMISSION_DEBIT_GROSS_AMOUNT

This field contains the proportion of the Submission Gross Amount which is a debit amount, expressed in the Payment (Settlement) currency.

This field is always signed positive.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head2 SUBMISSION_CREDIT_GROSS_AMOUNT

This field contains the proportion of the Submission Gross Amount which is a credit amount, expressed in the Payment (Settlement) currency.

This field is always signed positive.

For formats of amount values, see description in Summary Record, PAYMENT_NET_AMOUNT.

=head1 NAME

Finance::AMEX::Transaction::GRRCN::Submission - Object methods for AMEX Global Reconciliation (GRRCN) Submission or summary of charge records.

=head1 AUTHOR

Tom Heady <theady@ziprecruiter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
