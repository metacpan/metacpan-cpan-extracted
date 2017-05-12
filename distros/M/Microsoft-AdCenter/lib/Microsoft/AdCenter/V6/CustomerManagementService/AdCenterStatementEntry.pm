package Microsoft::AdCenter::V6::CustomerManagementService::AdCenterStatementEntry;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V6::CustomerManagementService::AdCenterStatementEntry - Represents "AdCenterStatementEntry" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'AdCenterStatementEntry';
}

sub _namespace_uri {
    return 'http://adcenter.microsoft.com/syncapis';
}

our @_attributes = (qw/
    Detail
    DetailCode
    InvoiceEndDate
    InvoiceNumber
    InvoiceStartDate
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Detail => 'string',
    DetailCode => 'string',
    InvoiceEndDate => 'dateTime',
    InvoiceNumber => 'string',
    InvoiceStartDate => 'dateTime',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    Detail => 0,
    DetailCode => 0,
    InvoiceEndDate => 1,
    InvoiceNumber => 0,
    InvoiceStartDate => 1,
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

=head2 Detail

Gets/sets Detail (string)

=head2 DetailCode

Gets/sets DetailCode (string)

=head2 InvoiceEndDate

Gets/sets InvoiceEndDate (dateTime)

=head2 InvoiceNumber

Gets/sets InvoiceNumber (string)

=head2 InvoiceStartDate

Gets/sets InvoiceStartDate (dateTime)

=cut

