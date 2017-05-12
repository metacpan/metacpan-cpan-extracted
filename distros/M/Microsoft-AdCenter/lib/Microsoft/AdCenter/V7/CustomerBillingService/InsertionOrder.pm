package Microsoft::AdCenter::V7::CustomerBillingService::InsertionOrder;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V7::CustomerBillingService::InsertionOrder - Represents "InsertionOrder" in Microsoft AdCenter Customer Billing Service.

=cut

sub _type_name {
    return 'InsertionOrder';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement/Entities';
}

our @_attributes = (qw/
    AccountId
    BalanceAmount
    BookingCountryCode
    Comment
    EndDate
    InsertionOrderId
    LastModifiedByUserId
    LastModifiedTime
    NotificationThreshold
    ReferenceId
    SpendCapAmount
    StartDate
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AccountId => 'long',
    BalanceAmount => 'double',
    BookingCountryCode => 'string',
    Comment => 'string',
    EndDate => 'dateTime',
    InsertionOrderId => 'long',
    LastModifiedByUserId => 'long',
    LastModifiedTime => 'dateTime',
    NotificationThreshold => 'double',
    ReferenceId => 'long',
    SpendCapAmount => 'double',
    StartDate => 'dateTime',
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
    BalanceAmount => 0,
    BookingCountryCode => 0,
    Comment => 0,
    EndDate => 0,
    InsertionOrderId => 0,
    LastModifiedByUserId => 0,
    LastModifiedTime => 0,
    NotificationThreshold => 0,
    ReferenceId => 0,
    SpendCapAmount => 0,
    StartDate => 0,
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

=head2 BalanceAmount

Gets/sets BalanceAmount (double)

=head2 BookingCountryCode

Gets/sets BookingCountryCode (string)

=head2 Comment

Gets/sets Comment (string)

=head2 EndDate

Gets/sets EndDate (dateTime)

=head2 InsertionOrderId

Gets/sets InsertionOrderId (long)

=head2 LastModifiedByUserId

Gets/sets LastModifiedByUserId (long)

=head2 LastModifiedTime

Gets/sets LastModifiedTime (dateTime)

=head2 NotificationThreshold

Gets/sets NotificationThreshold (double)

=head2 ReferenceId

Gets/sets ReferenceId (long)

=head2 SpendCapAmount

Gets/sets SpendCapAmount (double)

=head2 StartDate

Gets/sets StartDate (dateTime)

=cut

