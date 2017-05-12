package Microsoft::AdCenter::V8::CustomerManagementService::ContactInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CustomerManagementService::ContactInfo - Represents "ContactInfo" in Microsoft AdCenter Customer Management Service.

=cut

sub _type_name {
    return 'ContactInfo';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement/Entities';
}

our @_attributes = (qw/
    Address
    ContactByPhone
    ContactByPostalMail
    Email
    EmailFormat
    Fax
    HomePhone
    Id
    Mobile
    Phone1
    Phone2
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Address => 'Address',
    ContactByPhone => 'boolean',
    ContactByPostalMail => 'boolean',
    Email => 'string',
    EmailFormat => 'EmailFormat',
    Fax => 'string',
    HomePhone => 'string',
    Id => 'long',
    Mobile => 'string',
    Phone1 => 'string',
    Phone2 => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    Address => 0,
    ContactByPhone => 0,
    ContactByPostalMail => 0,
    Email => 0,
    EmailFormat => 0,
    Fax => 0,
    HomePhone => 0,
    Id => 0,
    Mobile => 0,
    Phone1 => 0,
    Phone2 => 0,
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

=head2 Address

Gets/sets Address (Address)

=head2 ContactByPhone

Gets/sets ContactByPhone (boolean)

=head2 ContactByPostalMail

Gets/sets ContactByPostalMail (boolean)

=head2 Email

Gets/sets Email (string)

=head2 EmailFormat

Gets/sets EmailFormat (EmailFormat)

=head2 Fax

Gets/sets Fax (string)

=head2 HomePhone

Gets/sets HomePhone (string)

=head2 Id

Gets/sets Id (long)

=head2 Mobile

Gets/sets Mobile (string)

=head2 Phone1

Gets/sets Phone1 (string)

=head2 Phone2

Gets/sets Phone2 (string)

=cut

