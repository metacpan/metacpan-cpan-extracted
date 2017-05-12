package Microsoft::AdCenter::V8::CampaignManagementService::Business;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::Business - Represents "Business" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'Business';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

our @_attributes = (qw/
    AddressLine1
    AddressLine2
    BusinessImageIcon
    City
    CountryOrRegion
    Description
    Email
    GeoCodeStatus
    HrsOfOperation
    Id
    IsOpen24Hours
    LatitudeDegrees
    LongitudeDegrees
    Name
    OtherPaymentTypeDesc
    Payment
    Phone
    StateOrProvince
    Status
    URL
    ZipOrPostalCode
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AddressLine1 => 'string',
    AddressLine2 => 'string',
    BusinessImageIcon => 'BusinessImageIcon',
    City => 'string',
    CountryOrRegion => 'string',
    Description => 'string',
    Email => 'string',
    GeoCodeStatus => 'BusinessGeoCodeStatus',
    HrsOfOperation => 'ArrayOfHoursOfOperation',
    Id => 'long',
    IsOpen24Hours => 'boolean',
    LatitudeDegrees => 'double',
    LongitudeDegrees => 'double',
    Name => 'string',
    OtherPaymentTypeDesc => 'string',
    Payment => 'ArrayOfPaymentType',
    Phone => 'string',
    StateOrProvince => 'string',
    Status => 'BusinessStatus',
    URL => 'string',
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
    AddressLine1 => 0,
    AddressLine2 => 0,
    BusinessImageIcon => 0,
    City => 0,
    CountryOrRegion => 0,
    Description => 1,
    Email => 0,
    GeoCodeStatus => 0,
    HrsOfOperation => 0,
    Id => 0,
    IsOpen24Hours => 0,
    LatitudeDegrees => 0,
    LongitudeDegrees => 0,
    Name => 1,
    OtherPaymentTypeDesc => 0,
    Payment => 0,
    Phone => 0,
    StateOrProvince => 0,
    Status => 0,
    URL => 0,
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

=head2 AddressLine1

Gets/sets AddressLine1 (string)

=head2 AddressLine2

Gets/sets AddressLine2 (string)

=head2 BusinessImageIcon

Gets/sets BusinessImageIcon (BusinessImageIcon)

=head2 City

Gets/sets City (string)

=head2 CountryOrRegion

Gets/sets CountryOrRegion (string)

=head2 Description

Gets/sets Description (string)

=head2 Email

Gets/sets Email (string)

=head2 GeoCodeStatus

Gets/sets GeoCodeStatus (BusinessGeoCodeStatus)

=head2 HrsOfOperation

Gets/sets HrsOfOperation (ArrayOfHoursOfOperation)

=head2 Id

Gets/sets Id (long)

=head2 IsOpen24Hours

Gets/sets IsOpen24Hours (boolean)

=head2 LatitudeDegrees

Gets/sets LatitudeDegrees (double)

=head2 LongitudeDegrees

Gets/sets LongitudeDegrees (double)

=head2 Name

Gets/sets Name (string)

=head2 OtherPaymentTypeDesc

Gets/sets OtherPaymentTypeDesc (string)

=head2 Payment

Gets/sets Payment (ArrayOfPaymentType)

=head2 Phone

Gets/sets Phone (string)

=head2 StateOrProvince

Gets/sets StateOrProvince (string)

=head2 Status

Gets/sets Status (BusinessStatus)

=head2 URL

Gets/sets URL (string)

=head2 ZipOrPostalCode

Gets/sets ZipOrPostalCode (string)

=cut

