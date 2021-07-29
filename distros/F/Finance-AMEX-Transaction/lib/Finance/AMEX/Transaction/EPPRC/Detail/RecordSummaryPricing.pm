package Finance::AMEX::Transaction::EPPRC::Detail::RecordSummaryPricing;
$Finance::AMEX::Transaction::EPPRC::Detail::RecordSummaryPricing::VERSION = '0.004';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC) Record of Charge (ROC) Level Pricing Record Rows

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
    FEE_DESCRIPTION       => [48, 25],
    DISCOUNT_RATE         => [73, 9],
    DISCOUNT_AMOUNT       => [82, 15],
    FEE_RATE              => [97, 9],
    FEE_AMOUNT            => [106, 15],
    MERCHANT_ID           => [121, 15],
  };
}

sub type {return 'ROC_PRICING'}

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

Finance::AMEX::Transaction::EPPRC::Detail::RecordSummaryPricing - Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC) Record of Charge (ROC) Level Pricing Record Rows

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'EPPRC');
 open my $fh, '<', '/path to EPPRC file' or die "cannot open EPPRC file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'ROC_PRICING') {
    print $record->FEE_CODE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an EPPRC  file');
 if ($record->type eq 'ROC_PRICING') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new Finance::AMEX::Transaction::EPPRC::Detail::RecordSummaryPricing object.

 my $record = Finance::AMEX::Transaction::EPPRC::Detail::RecordSummaryPricing->new(line => $line);

=head2 type

This will always return the string ROC_PRICING.

 print $record->type; # ROC_PRICING

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

This field contains the constant literal “3”, a Record Type code that indicates that this is a Record of Charge (ROC) Detail Record.

=head2 DETAIL_RECORD_TYPE

This field contains the Detail Record Type code that indicates the type of record used in this transaction. For Record of Charge (ROC) Level Pricing Records, this entry is always “13”.

=head2 FEE_CODE

This field contains a Fee Code that corresponds to preceding ROC Detail Record. For valid ROC Level Pricing Record Fee
Codes, see below.

 Fee Code   Fee Description
 AI         NS AUTHFEE (May 2018)
 AP         CNP APP-IN (May 2018)
 AS         ACCESS FEE (May 2018)
 BC         RETURN FEE (May 2018)
 B1         HVP PC CR1 (May 2018)
 B2         HVP PC CR2 (May 2018)
 B3         HVP PC CR3 (May 2018)
 CB         CHGBCK FEE
 CC         CHARGE
 CF         CREDIT FEE
 CK         CHECK FEE
 CN         NONSWIPED
 CO         CORPORATE
 CP         RATE CAP (May 2018)
 CR         RET DSC CR
 CS         CROC SBI
 CT         CREDIT FEE (May 2018)
 C1         RDR CAP
 DB         DEBIT CARD
 DC         D/C TERMNL
 DD         DIRECT DEP
 DF         DSPUTE FEE
 DP         DYNAMIC PRICING (May 2018)
 DQ         DATA QUAL (May 2018)
 E1         CPC EIPP
 E2         CPC EIPP2
 E3         CPC EIPP3
 FF         FLAT FEE
 F1         HVP RP CR1 (May 2018)
 F2         HVP RP CR2 (May 2018)
 F3         HVP RP CR3 (May 2018)
 GA         CONSUMER 1 (May 2018)
 GB         CORPORATE1 (May 2018)
 GC         SMBUSINES1 (May 2018)
 GD         CONSUMER 2 (May 2018)
 GE         CORPORATE2 (May 2018)
 GF         SMBUSINES2 (May 2018)
 GG         RET DSC GG
 GH         CONSUMER 3 (May 2018)
 GI         CORPORATE3 (May 2018)
 GJ         SMBUSINES3 (May 2018)
 GK         CONSUMER 4 (May 2018)
 GL         CORPORATE4 (May 2018)
 GM         SMBUSINES4 (May 2018)
 GN         CONSUMER 5 (May 2018)
 GO         CORPORATE5 (May 2018)
 GP         GROSS PAY (May 2018)
 GQ         SMBUSINES5 (May 2018)
 GS         CONSUMER 6 (May 2018)
 GT         CORPORATE6 (May 2018)
 GU         SMBUSINES6 (May 2018)
 GV         CONSUMER 7 (May 2018)
 GW         CORPORATE7 (May 2018)
 GX         SMBUSINES7 (May 2018)
 GZ         PREPAID (May 2018)
 G1         HIROC CHG
 G2         HIROC CHG2
 G3         HIROC CHG3
 HC         H-NONSWIPE
 HI         HIGH ROC
 IB         INBOUND (May 2018)
 IP         PURCH IB (May 2018)
 IR         RELOAD IB (May 2018)
 IS         PREPAID IB (May 2018)
 JC         JCB CARD
 K1         HVP SV CR1 (May 2018)
 K2         HVP SV CR2 (May 2018)
 K3         HVP SV CR3 (May 2018)
 MI         MICRO MRCH
 MM         MONMIN FEE
 MN         MNTHLY FEE
 MR         MEMBERSHIP
 NA         DISC COP (May 2018, previously REGULAR SUBMISSION)
 NC         NONCOMPLIA
 NF         NETWORK
 NK         NON-COMPLIANCE (May 2018, effective October 2018)
 OP         REVOLVING
 O1         HIROC COR
 O2         HIROC COR2
 O3         HIROC COR3
 PA         PAPER(SOC)
 PC         PURCH CARD
 PI         APCD PRC
 PL         PAYFLW LNK
 PP         PAYFLW PRO
 P1         HIROC PUR
 P2         HIROC PUR2
 P3         HIROC PUR3
 QU         QUTRLY FEE
 RD         RETAIN DSC
 RO         RDR OPTOUT
 RP         RELOADABLE (May 2018)
 R1         HIROC REG
 R2         HIROC REG2
 R3         HIROC REG3
 SB         SBI
 SE         SETUP FEE
 SM         SM MERCHNT
 ST         STATEMENT
 SV         STORED VAL
 TR         TRANS CNT
 VA         VOICE AUTH
 VG         GATEWAY
 VP         VPAYMENT (May 2018)
 V1         HVP REG C1 (May 2018)
 V2         HVP REG C2 (May 2018)
 V3         HVP REG C3 (May 2018)
 WA         TBP PC AD1 (May 2018)
 WB         TBP PC AD2 (May 2018)
 WC         TBP PC AD3 (May 2018)
 WD         TBP PC AD4 (May 2018)
 WE         TBP PC AD5 (May 2018)
 WI         TBP REGAD1 (May 2018)
 WJ         TBP REGAD2 (May 2018)
 WK         TBP REGAD3 (May 2018)
 WL         TBP REGAD4 (May 2018)
 WM         TBP REGAD5 (May 2018)
 WO         TBP REGCD5 (May 2018)
 W1         TBP PC CD1 (May 2018)
 W2         TBP PC CD2 (May 2018)
 W3         TBP PC CD3 (May 2018)
 W4         TBP PC CD4 (May 2018)
 W5         TBP PC CD5 (May 2018)
 W6         TBP REGCD1 (May 2018)
 W7         TBP REGCD2 (May 2018)
 W8         TBP REGCD3 (May 2018)
 W9         TBP REGCD4 (May 2018)
 X1         CORP EIPP
 X2         CORP EIPP2
 X3         CORP EIPP3
 YA         TBP SV AD1 (May 2018)
 YB         TBP SV AD2 (May 2018)
 YC         TBP SV AD3 (May 2018)
 YD         TBP SV AD4 (May 2018)
 YE         TBP SV AD5 (May 2018)
 YF         TBP RP AD1 (May 2018)
 YG         TBP RP AD2 (May 2018)
 YH         TBP RP AD3 (May 2018)
 YI         TBP RP AD4 (May 2018)
 YJ         TBP RP AD5 (May 2018)
 YR         YEARLY FEE
 Y0         TBP RP CD5 (May 2018)
 Y1         TBP SV CD1 (May 2018)
 Y2         TBP SV CD2 (May 2018)
 Y3         TBP SV CD3 (May 2018)
 Y4         TBP SV CD4 (May 2018)
 Y5         TBP SV CD5 (May 2018)
 Y6         TBP RP CD1 (May 2018)
 Y7         TBP RP CD2 (May 2018)
 Y8         TBP RP CD3 (May 2018)
 Y9         TBP RP CD4 (May 2018)

=head2 FEE_DESCRIPTION

This field contains the Fee Description that corresponds to the amount in FEE_CODE.

=head2 DISCOUNT_RATE

This field contains the Discount Rate (decimal place value) used to calculate the amount American Express charged a merchant for the services that correspond to the preceding ROC Detail Record.

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

This field contains the Discount Amount that American Express charged a merchant for the services that correspond to the preceding ROC Detail Record.

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

This field contains the Fee Rate (decimal place value) used to calculate the amount American Express charged a merchant for a fee (described in the FEE_CODE and FEE_DESCRIPTION fields in this record) that corresponds to the preceding ROC Detail Record. For more information, see pages FEE_CODE and FEE_DESCRIPTION.

This value may be a debit or credit rate. The format is a 1-digit “sign”, followed by an 8-digit “rate”.

See examples of negative and positive entries in DISCOUNT_RATE.

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 FEE_AMOUNT

This field contains the Fee Amount American Express charged a merchant for a fee (described in the FEE_CODE and FEE_DESCRIPTION fields in this record) that corresponds to the preceding ROC Detail Record. For more information, see FEE_CODE and FEE_DESCRIPTION.

This value may be a debit or credit amount. The format is a 1-digit “sign”, followed by a 14-digit “amount”.

See examples of negative and positive entries in DISCOUNT_AMOUNT.

If unused, position 1 in this field contains a character space; and the remaining positions are zero filled.

=head2 MERCHANT_ID

This field contains the external, third party Service Agent Merchant ID number when applicable.

=head1 NAME

Finance::AMEX::Transaction::EPPRC::Detail::RecordSummaryPricing - Object methods for AMEX Transaction/Invoice (ROC) level pricing records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
