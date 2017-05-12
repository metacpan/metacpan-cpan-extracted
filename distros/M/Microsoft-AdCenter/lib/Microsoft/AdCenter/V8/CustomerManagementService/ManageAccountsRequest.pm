package Microsoft::AdCenter::V8::CustomerManagementService::ManageAccountsRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CustomerManagementService::ManageAccountsRequest - Represents "ManageAccountsRequest" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'ManageAccountsRequest';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement/Entities';
}

our @_attributes = (qw/
    AdvertiserAccountNumbers
    AgencyCustomerNumber
    EffectiveDate
    Id
    LastModifiedByUserId
    LastModifiedDateTime
    Notes
    PaymentMethodId
    RequestDate
    RequestStatus
    RequestStatusDetails
    RequestType
    RequesterContactEmail
    RequesterContactName
    RequesterContactPhoneNumber
    RequesterCustomerNumber
    TimeStamp
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AdvertiserAccountNumbers => 'ArrayOfstring',
    AgencyCustomerNumber => 'string',
    EffectiveDate => 'Date',
    Id => 'long',
    LastModifiedByUserId => 'long',
    LastModifiedDateTime => 'dateTime',
    Notes => 'string',
    PaymentMethodId => 'long',
    RequestDate => 'dateTime',
    RequestStatus => 'ManageAccountsRequestStatus',
    RequestStatusDetails => 'ArrayOfstring',
    RequestType => 'ManageAccountsRequestType',
    RequesterContactEmail => 'string',
    RequesterContactName => 'string',
    RequesterContactPhoneNumber => 'string',
    RequesterCustomerNumber => 'string',
    TimeStamp => 'base64Binary',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AdvertiserAccountNumbers => 0,
    AgencyCustomerNumber => 0,
    EffectiveDate => 0,
    Id => 0,
    LastModifiedByUserId => 0,
    LastModifiedDateTime => 0,
    Notes => 0,
    PaymentMethodId => 0,
    RequestDate => 0,
    RequestStatus => 0,
    RequestStatusDetails => 0,
    RequestType => 0,
    RequesterContactEmail => 0,
    RequesterContactName => 0,
    RequesterContactPhoneNumber => 0,
    RequesterCustomerNumber => 0,
    TimeStamp => 0,
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

=head2 AdvertiserAccountNumbers

Gets/sets AdvertiserAccountNumbers (ArrayOfstring)

=head2 AgencyCustomerNumber

Gets/sets AgencyCustomerNumber (string)

=head2 EffectiveDate

Gets/sets EffectiveDate (Date)

=head2 Id

Gets/sets Id (long)

=head2 LastModifiedByUserId

Gets/sets LastModifiedByUserId (long)

=head2 LastModifiedDateTime

Gets/sets LastModifiedDateTime (dateTime)

=head2 Notes

Gets/sets Notes (string)

=head2 PaymentMethodId

Gets/sets PaymentMethodId (long)

=head2 RequestDate

Gets/sets RequestDate (dateTime)

=head2 RequestStatus

Gets/sets RequestStatus (ManageAccountsRequestStatus)

=head2 RequestStatusDetails

Gets/sets RequestStatusDetails (ArrayOfstring)

=head2 RequestType

Gets/sets RequestType (ManageAccountsRequestType)

=head2 RequesterContactEmail

Gets/sets RequesterContactEmail (string)

=head2 RequesterContactName

Gets/sets RequesterContactName (string)

=head2 RequesterContactPhoneNumber

Gets/sets RequesterContactPhoneNumber (string)

=head2 RequesterCustomerNumber

Gets/sets RequesterCustomerNumber (string)

=head2 TimeStamp

Gets/sets TimeStamp (base64Binary)

=cut

