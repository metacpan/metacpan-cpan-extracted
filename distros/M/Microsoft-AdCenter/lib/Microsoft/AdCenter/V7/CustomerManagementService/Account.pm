package Microsoft::AdCenter::V7::CustomerManagementService::Account;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V7::CustomerManagementService::Account - Represents "Account" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'Account';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement/Entities';
}

our @_attributes = (qw/
    AccountType
    BillToCustomerId
    CountryCode
    CurrencyType
    FinancialStatus
    Id
    Language
    LastModifiedByUserId
    LastModifiedTime
    Name
    Number
    ParentCustomerId
    PaymentMethodId
    PaymentMethodType
    PrimaryUserId
    Status
    TimeStamp
    TimeZone
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AccountType => 'AccountType',
    BillToCustomerId => 'long',
    CountryCode => 'string',
    CurrencyType => 'CurrencyType',
    FinancialStatus => 'AccountFinancialStatus',
    Id => 'long',
    Language => 'LanguageType',
    LastModifiedByUserId => 'long',
    LastModifiedTime => 'dateTime',
    Name => 'string',
    Number => 'string',
    ParentCustomerId => 'long',
    PaymentMethodId => 'long',
    PaymentMethodType => 'PaymentMethodType',
    PrimaryUserId => 'long',
    Status => 'AccountLifeCycleStatus',
    TimeStamp => 'base64Binary',
    TimeZone => 'TimeZoneType',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AccountType => 0,
    BillToCustomerId => 0,
    CountryCode => 0,
    CurrencyType => 0,
    FinancialStatus => 0,
    Id => 0,
    Language => 0,
    LastModifiedByUserId => 0,
    LastModifiedTime => 0,
    Name => 0,
    Number => 0,
    ParentCustomerId => 0,
    PaymentMethodId => 0,
    PaymentMethodType => 0,
    PrimaryUserId => 0,
    Status => 0,
    TimeStamp => 0,
    TimeZone => 0,
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

=head2 AccountType

Gets/sets AccountType (AccountType)

=head2 BillToCustomerId

Gets/sets BillToCustomerId (long)

=head2 CountryCode

Gets/sets CountryCode (string)

=head2 CurrencyType

Gets/sets CurrencyType (CurrencyType)

=head2 FinancialStatus

Gets/sets FinancialStatus (AccountFinancialStatus)

=head2 Id

Gets/sets Id (long)

=head2 Language

Gets/sets Language (LanguageType)

=head2 LastModifiedByUserId

Gets/sets LastModifiedByUserId (long)

=head2 LastModifiedTime

Gets/sets LastModifiedTime (dateTime)

=head2 Name

Gets/sets Name (string)

=head2 Number

Gets/sets Number (string)

=head2 ParentCustomerId

Gets/sets ParentCustomerId (long)

=head2 PaymentMethodId

Gets/sets PaymentMethodId (long)

=head2 PaymentMethodType

Gets/sets PaymentMethodType (PaymentMethodType)

=head2 PrimaryUserId

Gets/sets PrimaryUserId (long)

=head2 Status

Gets/sets Status (AccountLifeCycleStatus)

=head2 TimeStamp

Gets/sets TimeStamp (base64Binary)

=head2 TimeZone

Gets/sets TimeZone (TimeZoneType)

=cut

