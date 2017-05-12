package Microsoft::AdCenter::V6::CustomerManagementService::AdCenterAddress;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V6::CustomerManagementService::AdCenterAddress - Represents "AdCenterAddress" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'AdCenterAddress';
}

sub _namespace_uri {
    return 'http://adcenter.microsoft.com/syncapis';
}

our @_attributes = (qw/
    AddressId
    AddressLine1
    AddressLine2
    AddressLine3
    AddressLine4
    City
    Country
    StateOrProvince
    ZipOrPostalCode
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AddressId => 'int',
    AddressLine1 => 'string',
    AddressLine2 => 'string',
    AddressLine3 => 'string',
    AddressLine4 => 'string',
    City => 'string',
    Country => 'CountryCode',
    StateOrProvince => 'string',
    ZipOrPostalCode => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AddressId => 1,
    AddressLine1 => 0,
    AddressLine2 => 0,
    AddressLine3 => 0,
    AddressLine4 => 0,
    City => 0,
    Country => 1,
    StateOrProvince => 0,
    ZipOrPostalCode => 0,
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

=head2 AddressId

Gets/sets AddressId (int)

=head2 AddressLine1

Gets/sets AddressLine1 (string)

=head2 AddressLine2

Gets/sets AddressLine2 (string)

=head2 AddressLine3

Gets/sets AddressLine3 (string)

=head2 AddressLine4

Gets/sets AddressLine4 (string)

=head2 City

Gets/sets City (string)

=head2 Country

Gets/sets Country (CountryCode)

=head2 StateOrProvince

Gets/sets StateOrProvince (string)

=head2 ZipOrPostalCode

Gets/sets ZipOrPostalCode (string)

=cut

