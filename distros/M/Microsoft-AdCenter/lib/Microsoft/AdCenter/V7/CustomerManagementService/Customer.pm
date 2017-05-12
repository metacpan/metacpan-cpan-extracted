package Microsoft::AdCenter::V7::CustomerManagementService::Customer;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V7::CustomerManagementService::Customer - Represents "Customer" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'Customer';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement/Entities';
}

our @_attributes = (qw/
    CustomerAddress
    FinancialStatus
    Id
    Industry
    LastModifiedByUserId
    LastModifiedTime
    Market
    Name
    ServiceLevel
    Status
    TimeStamp
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    CustomerAddress => 'Address',
    FinancialStatus => 'CustomerFinancialStatus',
    Id => 'long',
    Industry => 'Industry',
    LastModifiedByUserId => 'long',
    LastModifiedTime => 'dateTime',
    Market => 'Market',
    Name => 'string',
    ServiceLevel => 'ServiceLevel',
    Status => 'CustomerLifeCycleStatus',
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
    CustomerAddress => 0,
    FinancialStatus => 0,
    Id => 0,
    Industry => 0,
    LastModifiedByUserId => 0,
    LastModifiedTime => 0,
    Market => 0,
    Name => 0,
    ServiceLevel => 0,
    Status => 0,
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

=head2 CustomerAddress

Gets/sets CustomerAddress (Address)

=head2 FinancialStatus

Gets/sets FinancialStatus (CustomerFinancialStatus)

=head2 Id

Gets/sets Id (long)

=head2 Industry

Gets/sets Industry (Industry)

=head2 LastModifiedByUserId

Gets/sets LastModifiedByUserId (long)

=head2 LastModifiedTime

Gets/sets LastModifiedTime (dateTime)

=head2 Market

Gets/sets Market (Market)

=head2 Name

Gets/sets Name (string)

=head2 ServiceLevel

Gets/sets ServiceLevel (ServiceLevel)

=head2 Status

Gets/sets Status (CustomerLifeCycleStatus)

=head2 TimeStamp

Gets/sets TimeStamp (base64Binary)

=cut

