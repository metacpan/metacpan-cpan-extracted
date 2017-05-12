package Microsoft::AdCenter::V8::CustomerManagementService::AccountInfoWithCustomerData;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CustomerManagementService::AccountInfoWithCustomerData - Represents "AccountInfoWithCustomerData" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'AccountInfoWithCustomerData';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement/Entities';
}

our @_attributes = (qw/
    AccountId
    AccountLifeCycleStatus
    AccountName
    AccountNumber
    CustomerId
    CustomerName
    PauseReason
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AccountId => 'long',
    AccountLifeCycleStatus => 'AccountLifeCycleStatus',
    AccountName => 'string',
    AccountNumber => 'string',
    CustomerId => 'long',
    CustomerName => 'string',
    PauseReason => 'unsignedByte',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AccountId => 0,
    AccountLifeCycleStatus => 0,
    AccountName => 0,
    AccountNumber => 0,
    CustomerId => 0,
    CustomerName => 0,
    PauseReason => 0,
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

=head2 AccountId

Gets/sets AccountId (long)

=head2 AccountLifeCycleStatus

Gets/sets AccountLifeCycleStatus (AccountLifeCycleStatus)

=head2 AccountName

Gets/sets AccountName (string)

=head2 AccountNumber

Gets/sets AccountNumber (string)

=head2 CustomerId

Gets/sets CustomerId (long)

=head2 CustomerName

Gets/sets CustomerName (string)

=head2 PauseReason

Gets/sets PauseReason (unsignedByte)

=cut

