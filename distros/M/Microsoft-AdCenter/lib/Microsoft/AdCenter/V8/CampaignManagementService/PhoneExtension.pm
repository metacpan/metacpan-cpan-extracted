package Microsoft::AdCenter::V8::CampaignManagementService::PhoneExtension;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::PhoneExtension - Represents "PhoneExtension" in Microsoft AdCenter Campaign Management Service.

=cut

sub _type_name {
    return 'PhoneExtension';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

our @_attributes = (qw/
    Country
    EnableClickToCallOnly
    EnablePhoneExtension
    Phone
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Country => 'string',
    EnableClickToCallOnly => 'boolean',
    EnablePhoneExtension => 'boolean',
    Phone => 'string',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    Country => 0,
    EnableClickToCallOnly => 0,
    EnablePhoneExtension => 1,
    Phone => 0,
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

=head2 Country

Gets/sets Country (string)

=head2 EnableClickToCallOnly

Gets/sets EnableClickToCallOnly (boolean)

=head2 EnablePhoneExtension

Gets/sets EnablePhoneExtension (boolean)

=head2 Phone

Gets/sets Phone (string)

=cut

