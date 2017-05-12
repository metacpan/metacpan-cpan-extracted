package Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardInvoiceHandle;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardInvoiceHandle - Represents "AdCenterCardInvoiceHandle" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'AdCenterCardInvoiceHandle';
}

sub _namespace_uri {
    return 'http://adcenter.microsoft.com/syncapis';
}

our @_attributes = (qw/
    AccountId
    BillingDocumentId
    CustomerId
    EndDateTicks
    NoActivity
    StartDateTicks
    UserId
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AccountId => 'int',
    BillingDocumentId => 'int',
    CustomerId => 'int',
    EndDateTicks => 'long',
    NoActivity => 'short',
    StartDateTicks => 'long',
    UserId => 'int',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AccountId => 1,
    BillingDocumentId => 1,
    CustomerId => 1,
    EndDateTicks => 1,
    NoActivity => 1,
    StartDateTicks => 1,
    UserId => 1,
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

Gets/sets AccountId (int)

=head2 BillingDocumentId

Gets/sets BillingDocumentId (int)

=head2 CustomerId

Gets/sets CustomerId (int)

=head2 EndDateTicks

Gets/sets EndDateTicks (long)

=head2 NoActivity

Gets/sets NoActivity (short)

=head2 StartDateTicks

Gets/sets StartDateTicks (long)

=head2 UserId

Gets/sets UserId (int)

=cut

