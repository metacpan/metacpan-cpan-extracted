package Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardInvoiceHeader;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardInvoiceHeader - Represents "AdCenterCardInvoiceHeader" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'AdCenterCardInvoiceHeader';
}

sub _namespace_uri {
    return 'http://adcenter.microsoft.com/syncapis';
}

our @_attributes = (qw/
    AccountName
    AccountNumber
    ActivityEndDate
    ActivityStartDate
    AttnAddress1
    AttnAddress2
    AttnAddress3
    AttnCity
    AttnName
    AttnPostalCode
    AttnStateOrProvince
    BillingInquiriesURL
    CountryCode
    CurrencyCode
    CustomerName
    DocumentType
    InvoiceNumber
    PreferredLanguageId
    TaxId
    UserLCID
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AccountName => 'string',
    AccountNumber => 'string',
    ActivityEndDate => 'dateTime',
    ActivityStartDate => 'dateTime',
    AttnAddress1 => 'string',
    AttnAddress2 => 'string',
    AttnAddress3 => 'string',
    AttnCity => 'string',
    AttnName => 'string',
    AttnPostalCode => 'string',
    AttnStateOrProvince => 'string',
    BillingInquiriesURL => 'string',
    CountryCode => 'CountryCode',
    CurrencyCode => 'Currency',
    CustomerName => 'string',
    DocumentType => 'string',
    InvoiceNumber => 'string',
    PreferredLanguageId => 'LanguageType',
    TaxId => 'string',
    UserLCID => 'LCID',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AccountName => 0,
    AccountNumber => 0,
    ActivityEndDate => 1,
    ActivityStartDate => 1,
    AttnAddress1 => 0,
    AttnAddress2 => 0,
    AttnAddress3 => 0,
    AttnCity => 0,
    AttnName => 0,
    AttnPostalCode => 0,
    AttnStateOrProvince => 0,
    BillingInquiriesURL => 0,
    CountryCode => 1,
    CurrencyCode => 1,
    CustomerName => 0,
    DocumentType => 0,
    InvoiceNumber => 0,
    PreferredLanguageId => 1,
    TaxId => 0,
    UserLCID => 1,
);

sub _attribute_min_occurs {
    my ($self, $attribute) = @_;
    if (exists $_attribute_min_occurs{$attribute}) {
        return $_attribute_min_occurs{$attribute};
    }
    return $self->SUPER::_attribute_min_occurs($attribute);
}

__PACKAGE__->mk_accessors(@_attributes);

1;

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=cut

=head1 METHODS

=head2 new

Creates a new instance

=head2 AccountName

Gets/sets AccountName (string)

=head2 AccountNumber

Gets/sets AccountNumber (string)

=head2 ActivityEndDate

Gets/sets ActivityEndDate (dateTime)

=head2 ActivityStartDate

Gets/sets ActivityStartDate (dateTime)

=head2 AttnAddress1

Gets/sets AttnAddress1 (string)

=head2 AttnAddress2

Gets/sets AttnAddress2 (string)

=head2 AttnAddress3

Gets/sets AttnAddress3 (string)

=head2 AttnCity

Gets/sets AttnCity (string)

=head2 AttnName

Gets/sets AttnName (string)

=head2 AttnPostalCode

Gets/sets AttnPostalCode (string)

=head2 AttnStateOrProvince

Gets/sets AttnStateOrProvince (string)

=head2 BillingInquiriesURL

Gets/sets BillingInquiriesURL (string)

=head2 CountryCode

Gets/sets CountryCode (CountryCode)

=head2 CurrencyCode

Gets/sets CurrencyCode (Currency)

=head2 CustomerName

Gets/sets CustomerName (string)

=head2 DocumentType

Gets/sets DocumentType (string)

=head2 InvoiceNumber

Gets/sets InvoiceNumber (string)

=head2 PreferredLanguageId

Gets/sets PreferredLanguageId (LanguageType)

=head2 TaxId

Gets/sets TaxId (string)

=head2 UserLCID

Gets/sets UserLCID (LCID)

=cut

