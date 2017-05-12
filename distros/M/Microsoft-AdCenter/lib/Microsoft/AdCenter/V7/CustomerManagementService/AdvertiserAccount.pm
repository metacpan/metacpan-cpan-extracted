package Microsoft::AdCenter::V7::CustomerManagementService::AdvertiserAccount;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::V7::CustomerManagementService::Account/;

=head1 NAME

Microsoft::AdCenter::V7::CustomerManagementService::AdvertiserAccount - Represents "AdvertiserAccount" in Microsoft AdCenter Customer Management Service.

=head1 INHERITANCE

Microsoft::AdCenter::V7::CustomerManagementService::Account

=cut

sub _type_name {
    return 'AdvertiserAccount';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement/Entities';
}

our @_attributes = (qw/
    AgencyContactName
    AgencyCustomerId
    SalesHouseCustomerId
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    AgencyContactName => 'string',
    AgencyCustomerId => 'long',
    SalesHouseCustomerId => 'long',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    AgencyContactName => 0,
    AgencyCustomerId => 0,
    SalesHouseCustomerId => 0,
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

=head2 AgencyContactName

Gets/sets AgencyContactName (string)

=head2 AgencyCustomerId

Gets/sets AgencyCustomerId (long)

=head2 SalesHouseCustomerId

Gets/sets SalesHouseCustomerId (long)

=cut

