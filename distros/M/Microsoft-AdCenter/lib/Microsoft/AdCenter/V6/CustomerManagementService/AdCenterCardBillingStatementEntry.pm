package Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardBillingStatementEntry;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::V6::CustomerManagementService::AdCenterStatementEntry/;

=head1 NAME

Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardBillingStatementEntry - Represents "AdCenterCardBillingStatementEntry" in Microsoft AdCenter Customer Management Service.

=head1 INHERITANCE

Microsoft::AdCenter::V6::CustomerManagementService::AdCenterStatementEntry

=cut

sub _type_name {
    return 'AdCenterCardBillingStatementEntry';
}

sub _namespace_uri {
    return 'http://adcenter.microsoft.com/syncapis';
}

our @_attributes = (qw/
    Amount
    Balance
    BillingInvoiceHandle
    Charge
    Credit
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Amount => 'double',
    Balance => 'double',
    BillingInvoiceHandle => 'AdCenterCardInvoiceHandle',
    Charge => 'double',
    Credit => 'double',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    Amount => 1,
    Balance => 1,
    BillingInvoiceHandle => 1,
    Charge => 1,
    Credit => 1,
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

Remark: Inherited methods are not listed.

=head2 new

Creates a new instance

=head2 Amount

Gets/sets Amount (double)

=head2 Balance

Gets/sets Balance (double)

=head2 BillingInvoiceHandle

Gets/sets BillingInvoiceHandle (AdCenterCardInvoiceHandle)

=head2 Charge

Gets/sets Charge (double)

=head2 Credit

Gets/sets Credit (double)

=cut

