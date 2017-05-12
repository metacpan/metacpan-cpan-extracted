package Microsoft::AdCenter::V8::CustomerBillingService::InvoiceInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CustomerBillingService::InvoiceInfo - Represents "InvoiceInfo" in Microsoft AdCenter Customer Billing Service.

=cut

sub _type_name {
    return 'InvoiceInfo';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement/Entities';
}

our @_attributes = (qw/
    AccountId
    AccountName
    AccountNumber
    Amount
    CurrencyCode
    InvoiceDate
    InvoiceId
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AccountId => 'long',
    AccountName => 'string',
    AccountNumber => 'string',
    Amount => 'double',
    CurrencyCode => 'string',
    InvoiceDate => 'dateTime',
    InvoiceId => 'long',
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
    AccountName => 0,
    AccountNumber => 0,
    Amount => 0,
    CurrencyCode => 0,
    InvoiceDate => 0,
    InvoiceId => 0,
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

=head2 AccountName

Gets/sets AccountName (string)

=head2 AccountNumber

Gets/sets AccountNumber (string)

=head2 Amount

Gets/sets Amount (double)

=head2 CurrencyCode

Gets/sets CurrencyCode (string)

=head2 InvoiceDate

Gets/sets InvoiceDate (dateTime)

=head2 InvoiceId

Gets/sets InvoiceId (long)

=cut

