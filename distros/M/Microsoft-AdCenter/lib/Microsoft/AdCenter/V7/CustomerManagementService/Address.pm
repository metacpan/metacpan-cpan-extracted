package Microsoft::AdCenter::V7::CustomerManagementService::Address;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V7::CustomerManagementService::Address - Represents "Address" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'Address';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement/Entities';
}

our @_attributes = (qw/
    City
    CountryCode
    Id
    Line1
    Line2
    Line3
    Line4
    PostalCode
    StateOrProvince
    TimeStamp
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    City => 'string',
    CountryCode => 'string',
    Id => 'long',
    Line1 => 'string',
    Line2 => 'string',
    Line3 => 'string',
    Line4 => 'string',
    PostalCode => 'string',
    StateOrProvince => 'string',
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
    City => 0,
    CountryCode => 0,
    Id => 0,
    Line1 => 0,
    Line2 => 0,
    Line3 => 0,
    Line4 => 0,
    PostalCode => 0,
    StateOrProvince => 0,
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

=head2 City

Gets/sets City (string)

=head2 CountryCode

Gets/sets CountryCode (string)

=head2 Id

Gets/sets Id (long)

=head2 Line1

Gets/sets Line1 (string)

=head2 Line2

Gets/sets Line2 (string)

=head2 Line3

Gets/sets Line3 (string)

=head2 Line4

Gets/sets Line4 (string)

=head2 PostalCode

Gets/sets PostalCode (string)

=head2 StateOrProvince

Gets/sets StateOrProvince (string)

=head2 TimeStamp

Gets/sets TimeStamp (base64Binary)

=cut

