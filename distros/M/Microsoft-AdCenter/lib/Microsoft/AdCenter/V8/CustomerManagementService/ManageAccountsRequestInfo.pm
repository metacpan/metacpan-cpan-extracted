package Microsoft::AdCenter::V8::CustomerManagementService::ManageAccountsRequestInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CustomerManagementService::ManageAccountsRequestInfo - Represents "ManageAccountsRequestInfo" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'ManageAccountsRequestInfo';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement/Entities';
}

our @_attributes = (qw/
    AdvertiserAccountNumbers
    AgencyCustomerNumber
    EffectiveDate
    Id
    RequestDate
    Status
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
    RequestDate => 'dateTime',
    Status => 'ManageAccountsRequestStatus',
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
    RequestDate => 0,
    Status => 0,
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

=head2 RequestDate

Gets/sets RequestDate (dateTime)

=head2 Status

Gets/sets Status (ManageAccountsRequestStatus)

=cut

